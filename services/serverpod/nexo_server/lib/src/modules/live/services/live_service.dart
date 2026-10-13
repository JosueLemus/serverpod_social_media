import 'package:serverpod/serverpod.dart';

import '../../../generated/protocol.dart';
import '../../../shared/audit/audit_service.dart';
import '../../../shared/auth/auth_context.dart';
import '../../../shared/gateways/agora/agora_live_media_gateway.dart';
import '../../../shared/gateways/live_media_gateway.dart';
import '../../../shared/profiles/avatar_lookup.dart';
import '../../../shared/profiles/profile_lookup.dart';
import '../../identity/services/identity_service.dart';
import '../../notifications/services/notification_service.dart';
import '../../social/services/follow_service.dart';
import 'live_presence.dart';
import 'live_moderation_service.dart';
import 'live_rules.dart';
import 'live_sanctions.dart';
import 'live_stage_service.dart';
import 'show_scheduler.dart';

/// Reglas de negocio de los vivos: programar, iniciar, terminar, mirar y
/// chatear.
///
/// Toda escritura corre en una transacción con su auditoría, y lo que cambia
/// se publica **después** del commit: si la transacción se revierte, ningún
/// dispositivo tiene que haber visto el cambio.
class LiveService {
  LiveService({
    this._identity = const IdentityService(),
    this._audit = const AuditService(),
    this._notifications = const NotificationService(),
    this._follows = const FollowService(),
    this._scheduler = const FutureCallShowScheduler(),
    LivePresence? presence,
    LiveChatThrottle? throttle,
    LiveStageService? stage,
    LiveMediaGateway Function(Session session)? mediaGateway,
    DateTime Function()? now,
  }) : _presence = presence ?? LivePresence.instance,
       _throttle = throttle ?? LiveChatThrottle.instance,
       _stage = stage ?? LiveStageService(now: now),
       _mediaGateway =
           mediaGateway ??
           ((session) => liveMediaGatewayFrom(session.passwords)),
       _now = now ?? (() => DateTime.now().toUtc());

  final IdentityService _identity;
  final AuditService _audit;
  final NotificationService _notifications;
  final FollowService _follows;

  /// Recordatorio, expiración y replay automático (S15 del SDD 0008).
  final ShowScheduler _scheduler;
  final LivePresence _presence;
  final LiveChatThrottle _throttle;

  /// El escenario: roles en la sala, quién habla y quién pidió la palabra.
  final LiveStageService _stage;

  /// Silenciar, expulsar, banear, ocultar, borrar, fijar y destacar.
  late final LiveModerationService _moderation = LiveModerationService(
    stage: _stage,
    messageViews: _messageViews,
    now: _now,
  );

  /// Se resuelve por sesión porque los secretos se leen de ahí: con App
  /// Certificate, tokens firmados; sin él, el modo de prueba de Agora.
  final LiveMediaGateway Function(Session session) _mediaGateway;
  final DateTime Function() _now;

  // --- Lectura -------------------------------------------------------------

  Future<LiveShowView> get(Session session, int showId) async =>
      _toView(session, await requireVisible(session, showId));

  /// Lo que se muestra en Explorar y en el feed: al aire, programados y
  /// replays, en ese orden.
  Future<List<LiveShowView>> list(Session session) async {
    final shows = await LiveShow.db.find(
      session,
      where: (t) => t.status.inSet(_listed),
      orderByList: (t) => [t.startsAt.desc()],
      limit: LiveRules.listLimit,
    );
    return _toViews(session, shows..sort(_listOrder));
  }

  /// Los shows cuyo título coincide con [pattern], un patrón de `ILIKE` ya
  /// escapado, con los mismos estados y el mismo orden que [list].
  Future<List<LiveShowView>> search(
    Session session,
    String pattern, {
    required int limit,
  }) async {
    final shows = await LiveShow.db.find(
      session,
      where: (t) => t.status.inSet(_listed) & t.title.ilike(pattern),
      orderByList: (t) => [t.startsAt.desc()],
      limit: LiveRules.listLimit,
    );
    shows.sort(_listOrder);
    return _toViews(session, shows.take(limit).toList());
  }

  /// Lo que se lista: nada cancelado, fallido ni retirado.
  static const _listed = {
    LiveShowStatus.live,
    LiveShowStatus.ending,
    LiveShowStatus.scheduled,
    LiveShowStatus.recorded,
    LiveShowStatus.published,
  };

  /// Al aire, programados y replays. Programados: el más próximo primero. El
  /// resto: el más reciente.
  static int _listOrder(LiveShow a, LiveShow b) {
    int rank(LiveShow s) => LiveRules.isOnAir(s.status)
        ? 0
        : s.status == LiveShowStatus.scheduled
        ? 1
        : 2;
    final byRank = rank(a).compareTo(rank(b));
    if (byRank != 0) return byRank;
    return rank(a) == 1
        ? a.startsAt.compareTo(b.startsAt)
        : (b.startedAt ?? b.startsAt).compareTo(a.startedAt ?? a.startsAt);
  }

  /// Los shows al aire, con los de [prioritize] (las cuentas que sigue quien
  /// pide) primero y después los de más espectadores. La sección `liveNow`
  /// del feed de inicio.
  Future<List<LiveShowView>> onAir(
    Session session, {
    Set<UuidValue> prioritize = const {},
    int limit = 10,
  }) async {
    final shows = await LiveShow.db.find(
      session,
      where: (t) =>
          t.status.inSet({LiveShowStatus.live, LiveShowStatus.ending}),
      orderByList: (t) => [t.startedAt.desc()],
      limit: LiveRules.listLimit,
    );
    shows.sort((a, b) {
      final followed = (prioritize.contains(a.hostId) ? 0 : 1).compareTo(
        prioritize.contains(b.hostId) ? 0 : 1,
      );
      if (followed != 0) return followed;
      return _viewerCount(b).compareTo(_viewerCount(a));
    });
    return _toViews(session, shows.take(limit).toList());
  }

  /// Los shows de la cuenta de la sesión, en cualquier estado.
  Future<List<LiveShowView>> mine(Session session) async {
    final hostId = session.requireUserId;
    final shows = await LiveShow.db.find(
      session,
      where: (t) => t.hostId.equals(hostId),
      orderByList: (t) => [t.startsAt.desc()],
      limit: LiveRules.listLimit,
    );
    return _toViews(session, shows);
  }

  Future<LiveShowRole> roleIn(Session session, int showId) async =>
      _roleIn(session, await requireVisible(session, showId));

  /// Del más viejo al más nuevo. [beforeId] para pedir los anteriores.
  Future<List<LiveChatMessageView>> chatHistory(
    Session session,
    int showId, {
    int? beforeId,
  }) async {
    await requireVisible(session, showId);
    final rows = await LiveChatMessage.db.find(
      session,
      where: (t) {
        var where =
            t.showId.equals(showId) &
            t.hiddenAt.equals(null) &
            t.deletedAt.equals(null);
        if (beforeId != null) where = where & (t.id < beforeId);
        return where;
      },
      orderByList: (t) => [t.id.desc()],
      limit: LiveRules.chatPageSize,
    );
    return _messageViews(session, rows.reversed.toList());
  }

  // --- Escritura -----------------------------------------------------------

  Future<LiveShowView> schedule(Session session, LiveShowDraft draft) async {
    final hostId = session.requireUserId;
    final host = await _identity.requireActive(session, hostId);
    _requireVerifiedCreator(host);

    final title = LiveRules.normalizeTitle(draft.title);
    final description = LiveRules.normalizeDescription(draft.description);
    final duration = LiveRules.checkDuration(draft.durationMinutes);
    final startsAt = LiveRules.checkStartsAt(draft.startsAt, _now());
    final guests = await _guestIds(
      session,
      hostId,
      LiveRules.normalizeGuests(draft.guestUsernames),
    );

    final show = await session.db.transaction((tx) async {
      final show = await LiveShow.db.insertRow(
        session,
        LiveShow(
          hostId: hostId,
          title: title,
          description: description,
          startsAt: startsAt,
          durationMinutes: duration,
          access: draft.access,
          allowQuestions: draft.allowQuestions,
          recordReplay: draft.recordReplay,
          status: LiveShowStatus.scheduled,
        ),
        transaction: tx,
      );
      await LiveShowGuest.db.insert(session, [
        for (final id in guests)
          LiveShowGuest(
            showId: show.id!,
            userId: id,
            status: LiveShowGuestStatus.invited,
          ),
      ], transaction: tx);
      await _audit.record(
        session,
        actorId: hostId,
        action: 'live.schedule',
        entityType: 'liveShow',
        entityId: '${show.id}',
        transaction: tx,
      );
      return show;
    });

    final view = await _toView(session, show);
    await _publishStatus(session, view);
    await _scheduler.scheduled(session, show);
    return view;
  }

  /// D5 del SDD 0004: sólo el host, creador, verificado y con la cuenta
  /// activa. Un host tiene un solo vivo al aire a la vez.
  Future<LiveShowView> start(Session session, int showId) =>
      _transition(session, showId, LiveShowStatus.live);

  Future<LiveShowView> end(Session session, int showId) =>
      _transition(session, showId, LiveShowStatus.recorded);

  Future<LiveShowView> publish(Session session, int showId) =>
      _transition(session, showId, LiveShowStatus.published);

  Future<LiveShowView> cancel(Session session, int showId) =>
      _transition(session, showId, LiveShowStatus.cancelled);

  /// "Transmitir ahora": crea el show y lo pone al aire en un solo paso, como
  /// en cualquier red social. El mismo gate que [start] (D5) y el mismo lock
  /// por host: no se puede abrir un segundo vivo con este atajo.
  Future<LiveShowView> goLive(Session session, String title) async {
    final hostId = session.requireUserId;
    _requireVerifiedCreator(await _identity.requireActive(session, hostId));
    final normalized = LiveRules.normalizeTitle(title);

    late List<UserNotification> notices;
    final show = await session.db.transaction((tx) async {
      await _lockHost(session, hostId, tx);
      await _requireNoOtherLive(session, hostId, tx);
      final now = _now();
      final show = await LiveShow.db.insertRow(
        session,
        LiveShow(
          hostId: hostId,
          title: normalized,
          startsAt: now,
          durationMinutes: LiveRules.goLiveDurationMinutes,
          access: LiveShowAccess.public,
          status: LiveShowStatus.live,
          startedAt: now,
        ),
        transaction: tx,
      );
      await _audit.record(
        session,
        actorId: hostId,
        action: 'live.goLive',
        entityType: 'liveShow',
        entityId: '${show.id}',
        transaction: tx,
      );
      await _stage.seedOnAir(session, show, tx);
      notices = await _notifyLiveStarted(session, show, tx);
      return show;
    });

    final view = await _toView(session, show);
    await _publishStatus(session, view);
    await _notifications.publish(session, notices);
    return view;
  }

  /// La credencial de video para entrar al canal del show. El rol lo decide
  /// el servidor: con el show al aire publica el host **y quien esté en el
  /// escenario** (SDD 0011); el resto, incluso sin sesión, mira. El cliente
  /// nunca pide ser publicador (D9). Cuando alguien sube o baja, el evento
  /// `stage` le avisa que pida una credencial nueva.
  Future<LiveMediaGrant> mediaToken(Session session, int showId) async {
    final show = await requireVisible(session, showId);
    final onAir = LiveRules.isOnAir(show.status);
    // La audiencia entra también a un show programado: es la sala de
    // espera, y el video aparece cuando el host arranca.
    if (!onAir && show.status != LiveShowStatus.scheduled) {
      throw _error(NexoErrorCode.conflict, 'El show no está al aire.');
    }
    final viewer = session.userIdOrNull;
    await LiveSanctions.requireAdmitted(session, show, viewer);
    final isPublisher =
        onAir &&
        viewer != null &&
        (viewer == show.hostId ||
            await _stage.isOnStage(session, showId, viewer));
    final channel = LiveRules.mediaChannel(showId);
    final uid = LiveRules.mediaUid(viewer);
    final token = await _mediaGateway(session).issueToken(
      channel: channel,
      uid: uid,
      isPublisher: isPublisher,
      ttl: LiveRules.mediaTokenTtl,
    );
    return LiveMediaGrant(
      appId: token.appId,
      channel: channel,
      uid: uid,
      token: token.token,
      role: isPublisher
          ? LiveMediaGrantRole.publisher
          : LiveMediaGrantRole.subscriber,
      expiresAt: token.expiresAt,
    );
  }

  Future<LiveChatMessageView> sendChat(
    Session session,
    int showId,
    String body,
  ) async {
    final authorId = session.requireUserId;
    await _identity.requireActive(session, authorId);
    final show = await requireVisible(session, showId);
    if (show.status != LiveShowStatus.live) {
      throw _error(NexoErrorCode.conflict, 'El show no está al aire.');
    }
    await LiveSanctions.requireAdmitted(session, show, authorId);
    if (await LiveSanctions.activeMute(session, showId, authorId, _now()) !=
        null) {
      throw _error(NexoErrorCode.muted, 'Estás silenciado en este vivo.');
    }
    final text = LiveRules.normalizeChat(body);
    if (!_throttle.tryAcquire(authorId, _now(), LiveRules.chatCooldown)) {
      throw _error(
        NexoErrorCode.rateLimited,
        'Esperá un segundo antes del próximo mensaje.',
      );
    }

    final message = await LiveChatMessage.db.insertRow(
      session,
      LiveChatMessage(showId: showId, authorId: authorId, body: text),
    );
    final view = (await _messageViews(session, [message])).single;
    await session.messages.postMessage(
      LiveChannels.show(showId),
      LiveEvent(kind: LiveEventKind.chat, message: view),
    );
    return view;
  }

  /// Oculta un mensaje. Host o moderador, sobre alguien de rango menor
  /// (SDD 0011). No borra: queda en la auditoría.
  Future<void> hideChat(Session session, int messageId) =>
      _moderation.hideChat(session, messageId);

  // --- Tiempo real ---------------------------------------------------------

  /// El show si existe y se puede mirar. `removed` cuenta como inexistente.
  Future<LiveShow> requireVisible(Session session, int showId) async {
    final show = await LiveShow.db.findById(session, showId);
    if (show == null || show.status == LiveShowStatus.removed) {
      throw _error(NexoErrorCode.notFound, 'El show no existe.');
    }
    return show;
  }

  /// Lo primero que recibe quien se conecta. Se arma en SU sesión: es el
  /// único evento que puede llevar el rol.
  Future<LiveEvent> snapshot(Session session, LiveShow show) async {
    final (pinned, highlighted) = await _moderation.anchors(session, show);
    final viewer = session.userIdOrNull;
    final mute = viewer == null
        ? null
        : await LiveSanctions.activeMute(session, show.id!, viewer, _now());
    return LiveEvent(
      kind: LiveEventKind.snapshot,
      liveShow: await _toView(session, show),
      role: await _roleIn(session, show),
      viewerCount: _viewerCount(show),
      history: await chatHistory(session, show.id!),
      stage: await _stage.view(session, show.id!),
      pinned: pinned,
      highlighted: highlighted,
      sanctionKind: mute == null ? null : LiveSanctionKind.chatMute,
      until: mute?.until,
    );
  }

  /// `forbidden` si quien pide fue expulsado de este vivo o baneado por su
  /// host. Lo llama `watch` antes de sumarlo a la audiencia.
  Future<void> requireAdmitted(Session session, LiveShow show) =>
      LiveSanctions.requireAdmitted(session, show, session.userIdOrNull);

  /// Suma la sesión a los espectadores, salvo que sea el host.
  Future<void> joinAudience(Session session, LiveShow show) async {
    if (session.userIdOrNull == show.hostId) return;
    final count = _presence.join(show.id!, session);
    await _publishViewers(session, show.id!, count);
  }

  /// Idempotente: el `WillCloseListener` y el `finally` de `watch` la llaman
  /// los dos.
  Future<void> leaveAudience(Session session, int showId) async {
    final count = _presence.leave(showId, session);
    if (count != null) await _publishViewers(session, showId, count);
  }

  // --- Tareas diferidas (Future Calls) -------------------------------------
  //
  // Corren sin sesión de usuario: el actor es el sistema. Cada una vuelve a
  // mirar el estado del show y no hace nada si ya cambió, así que un
  // reintento o un reinicio no duplica efectos.

  /// `showStartingSoon` a los seguidores del host y a los invitados, si el
  /// show sigue programado.
  Future<void> remind(Session session, int showId) async {
    final notices = await session.db.transaction((tx) async {
      final show = await LiveShow.db.findById(
        session,
        showId,
        transaction: tx,
        lockMode: LockMode.forUpdate,
      );
      if (show == null || show.status != LiveShowStatus.scheduled) {
        return const <UserNotification>[];
      }
      final guests = await LiveShowGuest.db.find(
        session,
        where: (t) => t.showId.equals(showId),
        transaction: tx,
      );
      return _notifications.create(
        session,
        recipients: {
          ...await _follows.followerIdsOf(
            session,
            show.hostId,
            transaction: tx,
          ),
          for (final guest in guests) guest.userId,
        },
        kind: NotificationKind.showStartingSoon,
        actorId: show.hostId,
        showId: showId,
        transaction: tx,
      );
    });
    await _notifications.publish(session, notices);
  }

  /// Un show que a los 30 minutos de su inicio no arrancó se cancela (D11).
  Future<void> expire(Session session, int showId) => _systemTransition(
    session,
    showId,
    from: LiveShowStatus.scheduled,
    to: LiveShowStatus.cancelled,
    action: 'live.expire',
  );

  /// El replay se publica solo después de terminar, si el show lo guarda.
  Future<void> autoPublish(Session session, int showId) => _systemTransition(
    session,
    showId,
    from: LiveShowStatus.recorded,
    to: LiveShowStatus.published,
    action: 'live.autoPublish',
    when: (show) => show.recordReplay,
  );

  Future<void> _systemTransition(
    Session session,
    int showId, {
    required LiveShowStatus from,
    required LiveShowStatus to,
    required String action,
    bool Function(LiveShow show)? when,
  }) async {
    final updated = await session.db.transaction((tx) async {
      final show = await LiveShow.db.findById(
        session,
        showId,
        transaction: tx,
        lockMode: LockMode.forUpdate,
      );
      if (show == null || show.status != from) return null;
      if (when != null && !when(show)) return null;
      final saved = await LiveShow.db.updateRow(
        session,
        show.copyWith(status: to),
        transaction: tx,
      );
      await _audit.record(
        session,
        actorId: null,
        action: action,
        entityType: 'liveShow',
        entityId: '$showId',
        metadata: {'from': from.name, 'to': to.name},
        transaction: tx,
      );
      return saved;
    });
    if (updated == null) return;
    await _publishStatus(session, await _toView(session, updated));
  }

  // --- Escenario (SDD 0011) -------------------------------------------------

  Future<LiveStageView> stage(Session session, int showId) async =>
      _stage.view(session, (await requireVisible(session, showId)).id!);

  LiveStageService get stageService => _stage;

  LiveModerationService get moderation => _moderation;

  // --- Internos ------------------------------------------------------------

  Future<LiveShowView> _transition(
    Session session,
    int showId,
    LiveShowStatus to,
  ) async {
    final actorId = session.requireUserId;
    final current = await requireVisible(session, showId);

    // Quién puede, antes de bloquear nada. El host no cambia nunca, así que
    // leerlo fuera de la transacción es seguro.
    final isHost = current.hostId == actorId;
    if (to == LiveShowStatus.live) {
      if (!isHost) {
        throw _error(NexoErrorCode.forbidden, 'Sólo el host inicia su vivo.');
      }
      _requireVerifiedCreator(await _identity.requireActive(session, actorId));
    } else if (!isHost && !session.hasScope(NexoScopes.admin)) {
      throw _error(
        NexoErrorCode.forbidden,
        'Sólo el host o un operador cambian este show.',
      );
    }

    var notices = const <UserNotification>[];
    final updated = await session.db.transaction((tx) async {
      await _lockHost(session, current.hostId, tx);
      final show = (await LiveShow.db.findById(
        session,
        showId,
        transaction: tx,
        lockMode: LockMode.forUpdate,
      ))!;

      if (!LiveRules.canTransition(show.status, to)) {
        throw _error(
          NexoErrorCode.conflict,
          'El show no puede pasar de ${show.status.name} a ${to.name}.',
        );
      }
      if (to == LiveShowStatus.published && !show.recordReplay) {
        throw _error(NexoErrorCode.conflict, 'Este show no guarda replay.');
      }
      if (to == LiveShowStatus.live) {
        await _requireNoOtherLive(session, show.hostId, tx, except: show.id);
      }

      final now = _now();
      final next = switch (to) {
        LiveShowStatus.live => show.copyWith(status: to, startedAt: now),
        LiveShowStatus.recorded => show.copyWith(
          status: to,
          endedAt: now,
          endedBy: actorId,
          endedByModeration: !isHost,
          viewerPeak: [
            show.viewerPeak,
            _presence.peak(show.id!),
          ].reduce((a, b) => a > b ? a : b),
        ),
        _ => show.copyWith(status: to),
      };
      final saved = await LiveShow.db.updateRow(session, next, transaction: tx);
      await _audit.record(
        session,
        actorId: actorId,
        action: 'live.${_actionName(to)}',
        entityType: 'liveShow',
        entityId: '$showId',
        metadata: {'from': show.status.name, 'to': to.name},
        transaction: tx,
      );
      if (to == LiveShowStatus.live) {
        await _stage.seedOnAir(session, saved, tx);
        notices = await _notifyLiveStarted(session, saved, tx);
      }
      return saved;
    });

    final view = await _toView(session, updated);
    await _publishStatus(session, view);
    await _notifications.publish(session, notices);
    await _afterTransition(session, updated);
    return view;
  }

  /// Las tareas diferidas siguen al estado nuevo: un show que arrancó o se
  /// canceló ya no necesita recordatorio ni expiración; uno que terminó
  /// publica su replay solo.
  Future<void> _afterTransition(Session session, LiveShow show) =>
      switch (show.status) {
        LiveShowStatus.live => _scheduler.started(session, show.id!),
        LiveShowStatus.cancelled => _scheduler.cancelled(session, show.id!),
        LiveShowStatus.recorded => _scheduler.ended(session, show),
        LiveShowStatus.published => _scheduler.published(session, show.id!),
        _ => Future<void>.value(),
      };

  /// `liveStarted` para cada seguidor del host (S12), dentro de [tx].
  Future<List<UserNotification>> _notifyLiveStarted(
    Session session,
    LiveShow show,
    Transaction tx,
  ) async => _notifications.create(
    session,
    recipients: await _follows.followerIdsOf(
      session,
      show.hostId,
      transaction: tx,
    ),
    kind: NotificationKind.liveStarted,
    actorId: show.hostId,
    showId: show.id,
    transaction: tx,
  );

  /// Con el lock por host, dos toques seguidos de "Iniciar" (o de
  /// "Transmitir ahora") no abren dos vivos: el segundo espera y ve el
  /// primero al aire.
  Future<void> _lockHost(
    Session session,
    UuidValue hostId,
    Transaction tx,
  ) => session.db.unsafeExecute(
    'SELECT pg_advisory_xact_lock(hashtext(@key))',
    parameters: QueryParameters.named({'key': 'live:host:$hostId'}),
    transaction: tx,
  );

  /// Un host tiene un solo vivo al aire a la vez. Corre con [_lockHost]
  /// tomado.
  Future<void> _requireNoOtherLive(
    Session session,
    UuidValue hostId,
    Transaction tx, {
    int? except,
  }) async {
    final onAir = await LiveShow.db.count(
      session,
      where: (t) =>
          t.hostId.equals(hostId) &
          t.status.inSet({LiveShowStatus.live, LiveShowStatus.ending}) &
          // Con `except` nulo es `id IS NOT NULL`: todos.
          t.id.notEquals(except),
      transaction: tx,
    );
    if (onAir > 0) {
      throw _error(NexoErrorCode.conflict, 'Ya tenés un vivo al aire.');
    }
  }

  static String _actionName(LiveShowStatus to) => switch (to) {
    LiveShowStatus.live => 'start',
    LiveShowStatus.recorded => 'end',
    LiveShowStatus.published => 'publish',
    LiveShowStatus.cancelled => 'cancel',
    _ => to.name,
  };

  void _requireVerifiedCreator(AccountProfile account) {
    if (!account.isCreator ||
        account.verification != VerificationStatus.verified) {
      throw _error(
        NexoErrorCode.creatorNotVerified,
        'Necesitás ser creador verificado para transmitir.',
      );
    }
  }

  Future<List<UuidValue>> _guestIds(
    Session session,
    UuidValue hostId,
    List<String> usernames,
  ) async {
    if (usernames.isEmpty) return const [];
    final accounts = await AccountProfile.db.find(
      session,
      where: (t) => t.username.inSet(usernames.toSet()),
    );
    final byName = {for (final a in accounts) a.username: a};
    return [
      for (final username in usernames)
        switch (byName[username]) {
          null => throw _error(
            NexoErrorCode.notFound,
            'No existe la cuenta @$username.',
          ),
          final a when a.authUserId == hostId => throw _error(
            NexoErrorCode.invalidInput,
            'No podés invitarte a tu propio show.',
          ),
          final a when a.status != AccountStatus.active => throw _error(
            NexoErrorCode.invalidInput,
            '@$username no puede participar ahora.',
          ),
          final a => a.authUserId,
        },
    ];
  }

  Future<LiveShowRole> _roleIn(Session session, LiveShow show) => _stage.roleOf(
    session,
    show,
    session.userIdOrNull,
    isStaff: session.isStaff,
  );

  int _viewerCount(LiveShow show) {
    if (LiveRules.isOnAir(show.status)) return _presence.count(show.id!);
    if (LiveRules.isEnded(show.status)) return show.viewerPeak;
    return 0;
  }

  Future<LiveShowView> _toView(Session session, LiveShow show) async =>
      (await _toViews(session, [show])).single;

  Future<List<LiveShowView>> _toViews(
    Session session,
    List<LiveShow> shows,
  ) async {
    if (shows.isEmpty) return const [];
    final profiles = await profilesOf(session, shows.map((s) => s.hostId));
    final avatars = await avatarsOf(session, shows.map((s) => s.hostId));
    final guests = await LiveShowGuest.db.find(
      session,
      where: (t) => t.showId.inSet(shows.map((s) => s.id!).toSet()),
      orderBy: (t) => t.id,
    );
    return [
      for (final show in shows)
        LiveShowView(
          id: show.id!,
          hostId: show.hostId,
          hostUsername: profiles[show.hostId]?.userName,
          hostName: profiles[show.hostId]?.fullName,
          hostAvatarUrl: avatars[show.hostId],
          title: show.title,
          description: show.description,
          startsAt: show.startsAt,
          durationMinutes: show.durationMinutes,
          access: show.access,
          allowQuestions: show.allowQuestions,
          recordReplay: show.recordReplay,
          status: show.status,
          startedAt: show.startedAt,
          endedAt: show.endedAt,
          endedByModeration: show.endedByModeration,
          viewerCount: _viewerCount(show),
          guestIds: [
            for (final g in guests)
              if (g.showId == show.id) g.userId,
          ],
        ),
    ];
  }

  Future<List<LiveChatMessageView>> _messageViews(
    Session session,
    List<LiveChatMessage> messages,
  ) async {
    if (messages.isEmpty) return const [];
    final profiles = await profilesOf(session, messages.map((m) => m.authorId));
    final avatars = await avatarsOf(session, messages.map((m) => m.authorId));
    return [
      for (final m in messages)
        LiveChatMessageView(
          id: m.id!,
          showId: m.showId,
          authorId: m.authorId,
          authorUsername: profiles[m.authorId]?.userName,
          authorName: profiles[m.authorId]?.fullName,
          authorAvatarUrl: avatars[m.authorId],
          body: m.body,
          createdAt: m.createdAt,
        ),
    ];
  }

  Future<void> _publishStatus(Session session, LiveShowView view) async {
    await session.messages.postMessage(
      LiveChannels.show(view.id),
      LiveEvent(kind: LiveEventKind.status, liveShow: view),
    );
    await session.messages.postMessage(LiveChannels.index, view);
  }

  Future<void> _publishViewers(Session session, int showId, int count) =>
      session.messages.postMessage(
        LiveChannels.show(showId),
        LiveEvent(kind: LiveEventKind.viewers, viewerCount: count),
      );

  static NexoException _error(NexoErrorCode code, String message) =>
      NexoException(code: code, message: message);
}
