import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../features/admin/domain/entities/account_detail.dart';
import '../../features/admin/domain/entities/audit_entry.dart';
import '../../features/auth/domain/entities/app_user.dart';
import '../../features/live/domain/entities/live_comment.dart';
import '../../features/live/domain/entities/live_session.dart';
import '../../features/moderation/domain/entities/moderation_action.dart';
import '../errors/failures.dart';
import 'demo_accounts.dart';
import 'platform_sync.dart';

/// El servidor falso.
///
/// Hasta que exista Serverpod, esto es lo que decide. No es una UI que finge:
/// tiene las **mismas reglas** que va a tener el backend —quién puede qué, la
/// máquina de estados del vivo, el gate de verificación— y lanza los mismos
/// `Failure` que va a mapear el cliente desde `NexoErrorCode`. Los
/// repositorios mock son una capa fina encima; la View nunca decide un
/// permiso.
///
/// Una sola fuente de verdad, porque la consola tiene que **afectar** al resto
/// de la app: con un estado por repositorio, suspender a alguien en la
/// consola no llegaba nunca a su sesión, y ocultar un comentario no lo sacaba
/// de la sala.
///
/// Cada mutación pasa por [_commit]: valida, aplica y audita, o no deja
/// nada. Es lo que en el backend hace la `Transaction` de
/// `AuditService.record`.
class MockPlatform {
  MockPlatform(
    this._preferences, {
    PlatformSync? sync,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now {
    _load();
    _externalSubscription = (sync ?? PlatformSync(storageKey)).externalChanges
        .listen((_) => unawaited(_rehydrate()));
  }

  /// Versionada: si la forma del estado cambia, una clave vieja se ignora en
  /// vez de romper el parseo.
  static const storageKey = 'mock_platform_v1';

  static const _pageSize = 20;

  final SharedPreferences _preferences;
  final DateTime Function() _now;
  late final StreamSubscription<void> _externalSubscription;
  final _changes = StreamController<void>.broadcast();
  var _sequence = 0;

  late Map<String, _Account> _accounts;
  late Map<String, LiveSession> _lives;
  late List<_Comment> _comments;
  late List<_Report> _reports;
  late List<_SanctionRecord> _sanctions;
  late List<_AuditRecord> _audit;

  /// Quién está usando **esta** instancia. Es por pestaña y no se persiste:
  /// lo fija el repositorio de auth al restaurar o iniciar sesión.
  String? _actorId;

  /// Emite después de cada cambio, propio o de otra pestaña.
  Stream<void> get changes => _changes.stream;

  // ---------------------------------------------------------------------------
  // Sesión
  // ---------------------------------------------------------------------------

  void bindSession(String? accountId) => _actorId = accountId;

  String? get sessionAccountId => _actorId;

  AppUser? accountById(String id) => _accounts[id]?.user;

  AppUser? accountByEmail(String email) {
    final normalized = email.trim().toLowerCase();
    for (final account in _accounts.values) {
      if (account.user.email == normalized) return account.user;
    }
    return null;
  }

  /// Una cuenta sancionada no inicia sesión.
  AppUser signIn(String accountId) {
    final user = _accounts[accountId]?.user;
    if (user == null) throw const NotFoundFailure('account');
    if (!user.isActive) throw const AccountSuspendedFailure('signIn');
    _actorId = accountId;
    return user;
  }

  /// La razón de la sanción vigente, para la pantalla de cuenta suspendida.
  ModerationReason? statusReason(String accountId) {
    for (final sanction in _sanctions.reversed) {
      if (sanction.accountId == accountId &&
          sanction.sanction.kind != SanctionKind.mute &&
          sanction.sanction.liftedAt == null) {
        return sanction.sanction.reason;
      }
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Vivos
  // ---------------------------------------------------------------------------

  static const _transitions = <LiveStatus, Set<LiveStatus>>{
    LiveStatus.draft: {LiveStatus.scheduled, LiveStatus.cancelled},
    LiveStatus.scheduled: {LiveStatus.live, LiveStatus.cancelled},
    LiveStatus.live: {
      LiveStatus.ending,
      LiveStatus.recorded,
      LiveStatus.failed,
    },
    LiveStatus.ending: {LiveStatus.recorded},
    LiveStatus.recorded: {LiveStatus.published, LiveStatus.removed},
    LiveStatus.published: {LiveStatus.removed},
  };

  List<LiveSession> lives() => List.unmodifiable(_lives.values);

  LiveSession? live(String id) => _lives[id];

  LiveSession transitionLive(String id, LiveStatus to) {
    final actor = _requireActor();
    final session = _lives[id];
    if (session == null) throw const NotFoundFailure('live');

    final isHost = session.hostId == actor.id;
    if (!isHost && !actor.isOperator) {
      throw const ForbiddenFailure('live.transition: not host');
    }
    if (!(_transitions[session.status]?.contains(to) ?? false)) {
      throw ConflictFailure('live.transition: ${session.status.name}→$to');
    }
    // El gate. Lo que la demo tiene que probar: el botón de iniciar sigue en
    // pantalla para un creador desverificado, y es acá donde se rechaza.
    if (to == LiveStatus.live) {
      if (!isHost) throw const ForbiddenFailure('live.start: not host');
      if (!actor.isCreator || !actor.isVerified) {
        throw const CreatorNotVerifiedFailure('live.start');
      }
    }

    late LiveSession updated;
    _commit(() {
      updated = session.copyWith(status: to);
      _lives[id] = updated;
      if (to == LiveStatus.live || to == LiveStatus.recorded) {
        _record(
          to == LiveStatus.live
              ? AuditAction.liveStarted
              : AuditAction.liveEnded,
          entityId: id,
          target: session.title,
        );
      }
    });
    return updated;
  }

  // TODO: max set with dependency of backend when are available
  static const maxCohosts = 3;

  LiveSession scheduleShow({
    required String title,
    required String description,
    required DateTime startsAt,
    required int durationMinutes,
    required bool isPremium,
    required List<String> cohostIds,
    required bool allowQuestions,
    required bool recordReplay,
  }) {
    final actor = _requireActor();
    if (!actor.isCreator || !actor.isVerified) {
      throw const CreatorNotVerifiedFailure('live.schedule');
    }
    if (title.trim().isEmpty) {
      throw const ConflictFailure('live.schedule: empty title');
    }
    if (!startsAt.isAfter(_now())) {
      throw const ConflictFailure('live.schedule: starts in the past');
    }
    if (cohostIds.length > maxCohosts) {
      throw const ConflictFailure('live.schedule: too many cohosts');
    }
    for (final id in cohostIds) {
      if (id == actor.id) {
        throw const ConflictFailure('live.schedule: host as cohost');
      }
      if (!_accounts.containsKey(id)) throw const NotFoundFailure('cohost');
    }

    final session = LiveSession(
      id: _id('live'),
      title: title.trim(),
      hostId: actor.id,
      hostName: actor.name,
      status: LiveStatus.scheduled,
      isPremium: isPremium,
      description: description.trim(),
      scheduledAt: startsAt,
      durationMinutes: durationMinutes,
      cohostIds: List.unmodifiable(cohostIds),
      allowQuestions: allowQuestions,
      recordReplay: recordReplay,
    );
    _commit(() => _lives[session.id] = session);
    return session;
  }

  AppUser invitableAccount(String username) {
    final actor = _requireActor();
    final needle = _withoutHandlePrefix(username);
    for (final account in _accounts.values) {
      final user = account.user;
      if (user.username.toLowerCase() != needle) continue;
      if (user.id == actor.id) {
        throw const ConflictFailure('cohost: host as cohost');
      }
      if (!user.isActive) throw const ForbiddenFailure('cohost: inactive');
      return user;
    }
    throw const NotFoundFailure('account');
  }

  List<LiveComment> comments(String liveId) => [
    for (final record in _comments)
      if (record.liveId == liveId && record.hiddenAt == null)
        LiveComment(
          id: record.id,
          author: record.author,
          authorId: record.authorId,
          body: record.body,
          isMine: record.authorId == _actorId,
        ),
  ];

  LiveComment postComment(String liveId, String body) {
    final actor = _requireActor();
    if (!_lives.containsKey(liveId)) throw const NotFoundFailure('live');
    if (_activeMute(actor.id) != null) {
      throw const MutedFailure('comment.post');
    }
    if (_kicked(actor.id, liveId)) {
      throw const ForbiddenFailure('comment.post: kicked');
    }
    final record = _Comment(
      id: _id('comment'),
      liveId: liveId,
      authorId: actor.id,
      author: actor.name,
      body: body,
      createdAt: _now(),
    );
    _commit(() => _comments.add(record));
    return LiveComment(
      id: record.id,
      author: record.author,
      authorId: record.authorId,
      body: record.body,
      isMine: true,
    );
  }

  void hideComment(String liveId, String commentId) {
    final actor = _requireActor();
    if (!_canModerateLive(actor, liveId)) {
      throw const ForbiddenFailure('comment.hide');
    }
    _commit(() => _hideComment(commentId, ModerationReason.other));
  }

  LiveRole roleIn(String liveId) {
    final actor = _actorId == null ? null : _accounts[_actorId]?.user;
    if (actor == null) return LiveRole.audience;
    if (_lives[liveId]?.hostId == actor.id) return LiveRole.host;
    if (actor.canModerate) return LiveRole.moderator;
    return LiveRole.audience;
  }

  // ---------------------------------------------------------------------------
  // Moderación
  // ---------------------------------------------------------------------------

  List<ModerationReport> openReports() {
    _requireModerator();
    return [
      for (final report in _reports)
        if (report.status == _ReportStatus.open) report.report,
    ]..sort((a, b) {
      final bySeverity = b.severity.index.compareTo(a.severity.index);
      return bySeverity != 0 ? bySeverity : b.createdAt.compareTo(a.createdAt);
    });
  }

  List<ModerationAction> moderationActions() {
    _requireModerator();
    return [
      for (final record in _audit.reversed)
        if (_moderationType(record.action) case final type?)
          ModerationAction(
            id: record.id,
            type: type,
            target: record.target,
            reason: record.reason ?? ModerationReason.other,
            actor: _handle(record.actorId),
            createdAt: record.createdAt,
          ),
    ];
  }

  void reportComment({
    required String liveId,
    required String commentId,
    required ModerationReason reason,
  }) {
    final actor = _requireActor();
    final comment = _commentById(commentId);
    if (comment == null || comment.liveId != liveId) {
      throw const NotFoundFailure('comment');
    }
    final author = _accounts[comment.authorId]?.user;
    final report = ModerationReport(
      id: _id('report'),
      content: comment.body,
      author: '@${author?.username ?? comment.author}',
      authorId: comment.authorId,
      reason: reason,
      severity: reason.severity,
      createdAt: _now(),
      commentId: commentId,
      liveId: liveId,
    );
    _commit(() {
      _reports.add(_Report(report, reporterId: actor.id));
      _record(
        AuditAction.reportFiled,
        entityId: report.id,
        target: report.author,
        reason: reason,
      );
    });
  }

  ModerationAction resolveReport(String reportId, ModerationDecision decision) {
    _requireModerator();
    final record = _openReport(reportId);
    final report = record.report;
    late _AuditRecord audit;

    _commit(() {
      audit = switch (decision.type) {
        ModerationType.hideComment => () {
          final commentId = report.commentId;
          if (commentId == null) {
            throw const ConflictFailure('resolve: report has no comment');
          }
          return _hideComment(commentId, report.reason);
        }(),
        ModerationType.muteUser => _mute(
          report.authorId,
          decision.muteFor ?? MuteDuration.oneDay,
          report.reason,
        ),
        ModerationType.banUser => _record(
          AuditAction.userKicked,
          entityId: report.authorId,
          target: report.author,
          reason: report.reason,
          liveId: report.liveId,
        ),
        ModerationType.report || ModerationType.dismissReport =>
          throw const ConflictFailure('resolve: not an action'),
      };
      record
        ..status = _ReportStatus.resolved
        ..resolvedBy = _actorId;
    });

    return ModerationAction(
      id: audit.id,
      type: decision.type,
      target: audit.target,
      reason: report.reason,
      actor: _handle(audit.actorId),
      createdAt: audit.createdAt,
    );
  }

  void dismissReport(String reportId) {
    _requireModerator();
    final record = _openReport(reportId);
    _commit(() {
      record
        ..status = _ReportStatus.dismissed
        ..resolvedBy = _actorId;
      _record(
        AuditAction.reportDismissed,
        entityId: reportId,
        target: record.report.author,
        reason: record.report.reason,
      );
    });
  }

  // ---------------------------------------------------------------------------
  // Consola del operador
  // ---------------------------------------------------------------------------

  ResultPage<AppUser> searchAccounts(String query, {String? cursor}) {
    _requireOperator();
    final needle = _withoutHandlePrefix(query);
    final matches = [
      for (final account in _accounts.values)
        if (needle.isEmpty ||
            account.user.email.contains(needle) ||
            account.user.username.toLowerCase().contains(needle) ||
            account.user.name.toLowerCase().contains(needle) ||
            account.user.id == needle)
          account.user,
    ]..sort((a, b) => a.username.compareTo(b.username));
    return _page(matches, cursor);
  }

  AccountDetail accountDetail(String accountId) {
    _requireOperator();
    final account = _accounts[accountId];
    if (account == null) throw const NotFoundFailure('account');
    return AccountDetail(
      user: account.user,
      joinedAt: account.joinedAt,
      sanctions: [
        for (final record in _sanctions.reversed)
          if (record.accountId == accountId) record.sanction,
      ],
      openReports: _reports
          .where(
            (report) =>
                report.status == _ReportStatus.open &&
                report.report.authorId == accountId,
          )
          .length,
    );
  }

  void suspend(String accountId, ModerationReason reason) =>
      _sanctionAccount(accountId, reason, ban: false);

  void ban(String accountId, ModerationReason reason) =>
      _sanctionAccount(accountId, reason, ban: true);

  void restore(String accountId) {
    _requireOperator();
    final target = _sanctionable(accountId);
    if (target.user.status == AccountStatus.banned) {
      throw const ConflictFailure('restore: banned');
    }
    if (target.user.status == AccountStatus.active) return;
    _commit(() {
      target.user = _copyUser(target.user, status: AccountStatus.active);
      _liftSanctions(accountId, SanctionKind.suspension);
      _record(
        AuditAction.accountRestored,
        entityId: accountId,
        target: '@${target.user.username}',
      );
    });
  }

  void setVerification(
    String accountId, {
    required bool verified,
    ModerationReason? reason,
  }) {
    _requireOperator();
    final target = _accounts[accountId];
    if (target == null) throw const NotFoundFailure('account');
    if (!target.user.isCreator) {
      throw const ConflictFailure('verification: not a creator');
    }
    if (!verified && reason == null) {
      throw const ConflictFailure('verification: revoking needs a reason');
    }
    _commit(() {
      target.user = _copyUser(
        target.user,
        verification: verified
            ? VerificationStatus.verified
            : VerificationStatus.revoked,
      );
      _record(
        verified
            ? AuditAction.verificationGranted
            : AuditAction.verificationRevoked,
        entityId: accountId,
        target: '@${target.user.username}',
        reason: reason,
      );
    });
  }

  List<AppUser> creators() {
    _requireOperator();
    return [
      for (final account in _accounts.values)
        if (account.user.isCreator) account.user,
    ]..sort((a, b) {
      final byVerified = (a.isVerified ? 1 : 0).compareTo(b.isVerified ? 1 : 0);
      return byVerified != 0 ? byVerified : a.username.compareTo(b.username);
    });
  }

  List<LiveSession> activeLives() {
    _requireOperator();
    return [
      for (final session in _lives.values)
        if (session.status == LiveStatus.live ||
            session.status == LiveStatus.ending)
          session,
    ]..sort((a, b) => b.viewers.compareTo(a.viewers));
  }

  void forceEndLive(String liveId, ModerationReason reason) {
    _requireOperator();
    final session = _lives[liveId];
    if (session == null) throw const NotFoundFailure('live');
    if (session.status != LiveStatus.live &&
        session.status != LiveStatus.ending) {
      throw const ConflictFailure('forceEnd: not on air');
    }
    _commit(() {
      _lives[liveId] = session.copyWith(
        status: LiveStatus.recorded,
        endedByModeration: true,
      );
      _record(
        AuditAction.liveForceEnded,
        entityId: liveId,
        target: session.title,
        reason: reason,
      );
    });
  }

  ResultPage<AuditEntry> audit(AuditFilter filter, {String? cursor}) {
    _requireOperator();
    final actor = filter.actor == null
        ? null
        : _withoutHandlePrefix(filter.actor!);
    final entries = [
      for (final record in _audit.reversed)
        if ((actor == null ||
                actor.isEmpty ||
                _handle(record.actorId).substring(1).startsWith(actor)) &&
            (filter.action == null || record.action == filter.action) &&
            (filter.entity == null || record.action.entity == filter.entity) &&
            (filter.since == null || !record.createdAt.isBefore(filter.since!)))
          AuditEntry(
            id: record.id,
            actor: _handle(record.actorId),
            action: record.action,
            entityId: record.entityId,
            target: record.target,
            reason: record.reason,
            createdAt: record.createdAt,
          ),
    ];
    return _page(entries, cursor);
  }

  // ---------------------------------------------------------------------------
  // Perfil público
  // ---------------------------------------------------------------------------

  /// Público a propósito: una sanción que no se ve desde afuera no se puede
  /// demostrar. Una cuenta que no existe en el mock se trata como activa.
  AccountStatus statusOf(String username) {
    for (final account in _accounts.values) {
      if (account.user.username == username) return account.user.status;
    }
    return AccountStatus.active;
  }

  // ---------------------------------------------------------------------------
  // Demo
  // ---------------------------------------------------------------------------

  /// Vuelve a la semilla. La sesión de esta pestaña se conserva.
  Future<void> reset() async {
    _seed();
    await _save();
    _emit();
  }

  /// No espera a que los streams terminen de cerrar, a propósito. GetIt
  /// llama a esto al resetear el grafo, y en un test eso puede pasar dentro
  /// de la zona fake-async de `testWidgets` con un stream creado afuera: el
  /// `await` no completa nunca y el test se cuelga hasta el timeout de diez
  /// minutos del suite.
  Future<void> dispose() async {
    unawaited(_externalSubscription.cancel());
    unawaited(_changes.close());
  }

  // ---------------------------------------------------------------------------
  // Reglas internas
  // ---------------------------------------------------------------------------

  AppUser _requireActor() {
    final id = _actorId;
    final user = id == null ? null : _accounts[id]?.user;
    if (user == null) throw const ForbiddenFailure('unauthenticated');
    // La red de seguridad de la revocación: si el aviso a la sesión se
    // perdió, la próxima operación la rechaza igual.
    if (!user.isActive) throw const AccountSuspendedFailure('session');
    return user;
  }

  AppUser _requireModerator() {
    final actor = _requireActor();
    if (!actor.canModerate) throw const ForbiddenFailure('moderator');
    return actor;
  }

  AppUser _requireOperator() {
    final actor = _requireActor();
    if (!actor.isOperator) throw const ForbiddenFailure('operator');
    return actor;
  }

  bool _canModerateLive(AppUser actor, String liveId) =>
      actor.canModerate || _lives[liveId]?.hostId == actor.id;

  /// Un operador no se sanciona a sí mismo ni a otro operador: es la forma de
  /// dejar la plataforma sin nadie que pueda deshacerlo.
  _Account _sanctionable(String accountId) {
    final target = _accounts[accountId];
    if (target == null) throw const NotFoundFailure('account');
    if (target.user.id == _actorId || target.user.isOperator) {
      throw const ForbiddenFailure('sanction: operator');
    }
    return target;
  }

  void _sanctionAccount(
    String accountId,
    ModerationReason reason, {
    required bool ban,
  }) {
    _requireOperator();
    final target = _sanctionable(accountId);
    if (target.user.status == AccountStatus.banned) {
      throw const ConflictFailure('sanction: already banned');
    }
    if (!ban && target.user.status == AccountStatus.suspended) return;
    _commit(() {
      target.user = _copyUser(
        target.user,
        status: ban ? AccountStatus.banned : AccountStatus.suspended,
      );
      _sanctions.add(
        _SanctionRecord(
          accountId,
          Sanction(
            id: _id('sanction'),
            kind: ban ? SanctionKind.ban : SanctionKind.suspension,
            reason: reason,
            createdBy: _handle(_actorId),
            createdAt: _now(),
          ),
        ),
      );
      _record(
        ban ? AuditAction.accountBanned : AuditAction.accountSuspended,
        entityId: accountId,
        target: '@${target.user.username}',
        reason: reason,
      );
    });
  }

  void _liftSanctions(String accountId, SanctionKind kind) {
    for (var i = 0; i < _sanctions.length; i++) {
      final record = _sanctions[i];
      final sanction = record.sanction;
      if (record.accountId != accountId ||
          sanction.kind != kind ||
          sanction.liftedAt != null) {
        continue;
      }
      _sanctions[i] = _SanctionRecord(
        accountId,
        Sanction(
          id: sanction.id,
          kind: sanction.kind,
          reason: sanction.reason,
          createdBy: sanction.createdBy,
          createdAt: sanction.createdAt,
          expiresAt: sanction.expiresAt,
          liftedAt: _now(),
        ),
      );
    }
  }

  _AuditRecord _hideComment(String commentId, ModerationReason reason) {
    final comment = _commentById(commentId);
    if (comment == null) throw const NotFoundFailure('comment');
    // Ocultar no es borrar: el comentario queda, con quién y cuándo. Un
    // borrado duro deja la cola apuntando a algo inexistente.
    comment
      ..hiddenAt ??= _now()
      ..hiddenBy ??= _actorId;
    final author = _accounts[comment.authorId]?.user;
    return _record(
      AuditAction.commentHidden,
      entityId: commentId,
      target: '@${author?.username ?? comment.author}',
      reason: reason,
    );
  }

  _AuditRecord _mute(
    String accountId,
    MuteDuration duration,
    ModerationReason reason,
  ) {
    final target = _accounts[accountId];
    final now = _now();
    _sanctions.add(
      _SanctionRecord(
        accountId,
        Sanction(
          id: _id('sanction'),
          kind: SanctionKind.mute,
          reason: reason,
          createdBy: _handle(_actorId),
          createdAt: now,
          expiresAt: now.add(duration.duration),
        ),
      ),
    );
    return _record(
      AuditAction.userMuted,
      entityId: accountId,
      target: '@${target?.user.username ?? accountId}',
      reason: reason,
    );
  }

  Sanction? _activeMute(String accountId) {
    final now = _now();
    for (final record in _sanctions) {
      if (record.accountId == accountId &&
          record.sanction.kind == SanctionKind.mute &&
          record.sanction.isActiveAt(now)) {
        return record.sanction;
      }
    }
    return null;
  }

  bool _kicked(String accountId, String liveId) => _audit.any(
    (record) =>
        record.action == AuditAction.userKicked &&
        record.entityId == accountId &&
        record.liveId == liveId,
  );

  _Report _openReport(String reportId) {
    for (final report in _reports) {
      if (report.report.id == reportId) {
        if (report.status != _ReportStatus.open) {
          throw const ConflictFailure('report: already closed');
        }
        return report;
      }
    }
    throw const NotFoundFailure('report');
  }

  _Comment? _commentById(String id) {
    for (final comment in _comments) {
      if (comment.id == id) return comment;
    }
    return null;
  }

  static ModerationType? _moderationType(AuditAction action) =>
      switch (action) {
        AuditAction.commentHidden => ModerationType.hideComment,
        AuditAction.userMuted => ModerationType.muteUser,
        AuditAction.userKicked => ModerationType.banUser,
        AuditAction.reportFiled => ModerationType.report,
        AuditAction.reportDismissed => ModerationType.dismissReport,
        _ => null,
      };

  /// `@troll_99` y `troll_99` son la misma búsqueda. Sólo la `@` inicial:
  /// sacar la primera que aparezca rompía la búsqueda por correo.
  static String _withoutHandlePrefix(String query) {
    final value = query.trim().toLowerCase();
    return value.startsWith('@') ? value.substring(1) : value;
  }

  String _handle(String? accountId) {
    final user = accountId == null ? null : _accounts[accountId]?.user;
    return '@${user?.username ?? 'sistema'}';
  }

  _AuditRecord _record(
    AuditAction action, {
    required String entityId,
    required String target,
    ModerationReason? reason,
    String? liveId,
  }) {
    final record = _AuditRecord(
      id: _id('audit'),
      actorId: _actorId,
      action: action,
      entityId: entityId,
      target: target,
      reason: reason,
      liveId: liveId,
      createdAt: _now(),
    );
    _audit.add(record);
    return record;
  }

  ResultPage<T> _page<T>(List<T> items, String? cursor) {
    final start = int.tryParse(cursor ?? '') ?? 0;
    final end = (start + _pageSize).clamp(0, items.length);
    return ResultPage(
      items.sublist(start.clamp(0, items.length), end),
      nextCursor: end < items.length ? '$end' : null,
    );
  }

  /// Temporal y único, nunca `length + 1`: ese esquema repite un id apenas se
  /// borra algo, y dos pestañas escribiendo a la vez lo repiten siempre.
  String _id(String prefix) =>
      '$prefix-${_now().microsecondsSinceEpoch}-${_sequence++}';

  /// Todo o nada. Si [change] lanza, el estado vuelve a como estaba antes:
  /// una auditoría que registra una acción que falló miente tanto como una
  /// acción sin auditar.
  void _commit(void Function() change) {
    final snapshot = _encode();
    try {
      change();
    } catch (_) {
      _decode(snapshot);
      rethrow;
    }
    unawaited(_save());
    _emit();
  }

  void _emit() {
    if (!_changes.isClosed) _changes.add(null);
  }

  Future<void> _rehydrate() async {
    await _preferences.reload();
    _load();
    _emit();
  }

  // ---------------------------------------------------------------------------
  // Persistencia
  // ---------------------------------------------------------------------------

  void _load() {
    final raw = _preferences.getString(storageKey);
    if (raw == null) {
      _seed();
      return;
    }
    try {
      _decode(raw);
    } on Object {
      // Un estado ilegible no puede dejar la demo sin arrancar.
      _seed();
    }
  }

  Future<void> _save() => _preferences.setString(storageKey, _encode());

  String _encode() => jsonEncode({
    'accounts': [for (final account in _accounts.values) account.toJson()],
    'lives': [for (final session in _lives.values) _liveToJson(session)],
    'comments': [for (final comment in _comments) comment.toJson()],
    'reports': [for (final report in _reports) report.toJson()],
    'sanctions': [for (final sanction in _sanctions) sanction.toJson()],
    'audit': [for (final record in _audit) record.toJson()],
  });

  void _decode(String raw) {
    final json = jsonDecode(raw) as Map<String, dynamic>;
    List<Map<String, dynamic>> list(String key) =>
        (json[key] as List<dynamic>).cast<Map<String, dynamic>>();
    _accounts = {
      for (final item in list('accounts'))
        item['id'] as String: _Account.fromJson(item),
    };
    _lives = {
      for (final item in list('lives'))
        item['id'] as String: _liveFromJson(item),
    };
    _comments = list('comments').map(_Comment.fromJson).toList();
    _reports = list('reports').map(_Report.fromJson).toList();
    _sanctions = list('sanctions').map(_SanctionRecord.fromJson).toList();
    _audit = list('audit').map(_AuditRecord.fromJson).toList();
  }

  void _seed() {
    final now = _now();
    _Account account(
      DemoAccount demo, {
      UserRole role = UserRole.user,
      bool creator = false,
      int daysAgo = 90,
    }) => _Account(
      AppUser(
        id: demo.id,
        username: demo.username,
        name: demo.name,
        email: demo.email,
        role: role,
        isCreator: creator,
        verification: creator
            ? VerificationStatus.verified
            : VerificationStatus.none,
      ),
      now.subtract(Duration(days: daysAgo)),
    );

    _accounts = {
      for (final item in [
        account(DemoAccounts.elena, creator: true, daysAgo: 420),
        account(DemoAccounts.carlos, creator: true, daysAgo: 300),
        account(DemoAccounts.operator, role: UserRole.operator, daysAgo: 700),
        account(DemoAccounts.moderator, role: UserRole.moderator, daysAgo: 500),
        account(DemoAccounts.viewer, daysAgo: 60),
        account(DemoAccounts.troll, daysAgo: 3),
        account(DemoAccounts.spammer, daysAgo: 1),
      ])
        item.user.id: item,
    };

    _lives = {
      for (final session in [
        LiveSession(
          id: 'live-1',
          title: 'Masterclass de Diseño Mobile',
          hostId: DemoAccounts.elena.id,
          hostName: DemoAccounts.elena.name,
          status: LiveStatus.live,
          viewers: 2845,
        ),
        LiveSession(
          id: 'live-2',
          title: 'Café entre creadores',
          hostId: DemoAccounts.elena.id,
          hostName: DemoAccounts.elena.name,
          status: LiveStatus.scheduled,
          viewers: 120,
        ),
        const LiveSession(
          id: 'live-3',
          title: 'Construyendo en público',
          hostId: 'lucia-torres',
          hostName: 'Lucía Torres',
          status: LiveStatus.recorded,
          viewers: 940,
          isPremium: true,
        ),
        LiveSession(
          id: 'live-4',
          title: 'Sistemas de diseño en Figma',
          hostId: DemoAccounts.carlos.id,
          hostName: DemoAccounts.carlos.name,
          status: LiveStatus.live,
          viewers: 530,
        ),
      ])
        session.id: session,
    };

    _Comment comment(String id, String authorId, String author, String body) =>
        _Comment(
          id: id,
          liveId: 'live-1',
          authorId: authorId,
          author: author,
          body: body,
          createdAt: now,
        );

    _comments = [
      comment(
        'c1',
        'viewer-sofia',
        'Sofía',
        'Increíble explicación sobre tokens 🔥',
      ),
      comment('c2', 'viewer-marcos', 'Marcos', '¿Vas a subir el replay?'),
      comment('c3', 'viewer-laura', 'Laura', 'Acabo de donar 50 NexoCoins'),
      comment(
        'c-troll',
        DemoAccounts.troll.id,
        DemoAccounts.troll.name,
        'Esto no aporta nada a la conversación, ándate de aquí',
      ),
      comment(
        'c-spam',
        DemoAccounts.spammer.id,
        DemoAccounts.spammer.name,
        'Compra seguidores baratos en este enlace',
      ),
    ];

    _reports = [
      _Report(
        ModerationReport(
          id: 'report-1',
          content: 'Esto no aporta nada a la conversación, ándate de aquí',
          author: '@${DemoAccounts.troll.username}',
          authorId: DemoAccounts.troll.id,
          reason: ModerationReason.harassment,
          severity: ModerationReason.harassment.severity,
          createdAt: now.subtract(const Duration(minutes: 8)),
          commentId: 'c-troll',
          liveId: 'live-1',
        ),
        reporterId: DemoAccounts.viewer.id,
      ),
      _Report(
        ModerationReport(
          id: 'report-2',
          content: 'Compra seguidores baratos en este enlace',
          author: '@${DemoAccounts.spammer.username}',
          authorId: DemoAccounts.spammer.id,
          reason: ModerationReason.spam,
          severity: ModerationReason.spam.severity,
          createdAt: now.subtract(const Duration(hours: 1)),
          commentId: 'c-spam',
          liveId: 'live-1',
        ),
        reporterId: DemoAccounts.viewer.id,
      ),
    ];
    _sanctions = [];
    _audit = [];
  }

  static AppUser _copyUser(
    AppUser user, {
    AccountStatus? status,
    VerificationStatus? verification,
  }) => AppUser(
    id: user.id,
    username: user.username,
    name: user.name,
    email: user.email,
    role: user.role,
    isCreator: user.isCreator,
    verification: verification ?? user.verification,
    status: status ?? user.status,
  );

  static Map<String, Object?> _liveToJson(LiveSession session) => {
    'id': session.id,
    'title': session.title,
    'hostId': session.hostId,
    'hostName': session.hostName,
    'status': session.status.name,
    'viewers': session.viewers,
    'isPremium': session.isPremium,
    'endedByModeration': session.endedByModeration,
    'description': session.description,
    'scheduledAt': session.scheduledAt?.toIso8601String(),
    'durationMinutes': session.durationMinutes,
    'cohostIds': session.cohostIds,
    'allowQuestions': session.allowQuestions,
    'recordReplay': session.recordReplay,
  };

  static LiveSession _liveFromJson(Map<String, dynamic> json) => LiveSession(
    id: json['id'] as String,
    title: json['title'] as String,
    hostId: json['hostId'] as String,
    hostName: json['hostName'] as String,
    status: LiveStatus.values.byName(json['status'] as String),
    viewers: json['viewers'] as int,
    isPremium: json['isPremium'] as bool,
    endedByModeration: json['endedByModeration'] as bool,
    description: json['description'] as String? ?? '',
    scheduledAt: _date(json['scheduledAt']),
    durationMinutes: json['durationMinutes'] as int?,
    cohostIds: (json['cohostIds'] as List<dynamic>? ?? const []).cast<String>(),
    allowQuestions: json['allowQuestions'] as bool? ?? true,
    recordReplay: json['recordReplay'] as bool? ?? true,
  );
}

DateTime? _date(Object? value) =>
    value == null ? null : DateTime.parse(value as String);

class _Account {
  _Account(this.user, this.joinedAt);

  factory _Account.fromJson(Map<String, dynamic> json) => _Account(
    AppUser(
      id: json['id'] as String,
      username: json['username'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      role: UserRole.values.byName(json['role'] as String),
      isCreator: json['isCreator'] as bool,
      verification: VerificationStatus.values.byName(
        json['verification'] as String,
      ),
      status: AccountStatus.values.byName(json['status'] as String),
    ),
    DateTime.parse(json['joinedAt'] as String),
  );

  AppUser user;
  final DateTime joinedAt;

  Map<String, Object?> toJson() => {
    'id': user.id,
    'username': user.username,
    'name': user.name,
    'email': user.email,
    'role': user.role.name,
    'isCreator': user.isCreator,
    'verification': user.verification.name,
    'status': user.status.name,
    'joinedAt': joinedAt.toIso8601String(),
  };
}

class _Comment {
  _Comment({
    required this.id,
    required this.liveId,
    required this.authorId,
    required this.author,
    required this.body,
    required this.createdAt,
    this.hiddenAt,
    this.hiddenBy,
  });

  factory _Comment.fromJson(Map<String, dynamic> json) => _Comment(
    id: json['id'] as String,
    liveId: json['liveId'] as String,
    authorId: json['authorId'] as String,
    author: json['author'] as String,
    body: json['body'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
    hiddenAt: _date(json['hiddenAt']),
    hiddenBy: json['hiddenBy'] as String?,
  );

  final String id;
  final String liveId;
  final String authorId;
  final String author;
  final String body;
  final DateTime createdAt;
  DateTime? hiddenAt;
  String? hiddenBy;

  Map<String, Object?> toJson() => {
    'id': id,
    'liveId': liveId,
    'authorId': authorId,
    'author': author,
    'body': body,
    'createdAt': createdAt.toIso8601String(),
    'hiddenAt': hiddenAt?.toIso8601String(),
    'hiddenBy': hiddenBy,
  };
}

enum _ReportStatus { open, resolved, dismissed }

class _Report {
  _Report(
    this.report, {
    required this.reporterId,
    this.status = _ReportStatus.open,
    this.resolvedBy,
  });

  factory _Report.fromJson(Map<String, dynamic> json) => _Report(
    ModerationReport(
      id: json['id'] as String,
      content: json['content'] as String,
      author: json['author'] as String,
      authorId: json['authorId'] as String,
      reason: ModerationReason.values.byName(json['reason'] as String),
      severity: ReportSeverity.values.byName(json['severity'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      commentId: json['commentId'] as String?,
      liveId: json['liveId'] as String?,
    ),
    reporterId: json['reporterId'] as String,
    status: _ReportStatus.values.byName(json['status'] as String),
    resolvedBy: json['resolvedBy'] as String?,
  );

  final ModerationReport report;
  final String reporterId;
  _ReportStatus status;
  String? resolvedBy;

  Map<String, Object?> toJson() => {
    'id': report.id,
    'content': report.content,
    'author': report.author,
    'authorId': report.authorId,
    'reason': report.reason.name,
    'severity': report.severity.name,
    'createdAt': report.createdAt.toIso8601String(),
    'commentId': report.commentId,
    'liveId': report.liveId,
    'reporterId': reporterId,
    'status': status.name,
    'resolvedBy': resolvedBy,
  };
}

class _SanctionRecord {
  _SanctionRecord(this.accountId, this.sanction);

  factory _SanctionRecord.fromJson(Map<String, dynamic> json) =>
      _SanctionRecord(
        json['accountId'] as String,
        Sanction(
          id: json['id'] as String,
          kind: SanctionKind.values.byName(json['kind'] as String),
          reason: ModerationReason.values.byName(json['reason'] as String),
          createdBy: json['createdBy'] as String,
          createdAt: DateTime.parse(json['createdAt'] as String),
          expiresAt: _date(json['expiresAt']),
          liftedAt: _date(json['liftedAt']),
        ),
      );

  final String accountId;
  final Sanction sanction;

  Map<String, Object?> toJson() => {
    'accountId': accountId,
    'id': sanction.id,
    'kind': sanction.kind.name,
    'reason': sanction.reason.name,
    'createdBy': sanction.createdBy,
    'createdAt': sanction.createdAt.toIso8601String(),
    'expiresAt': sanction.expiresAt?.toIso8601String(),
    'liftedAt': sanction.liftedAt?.toIso8601String(),
  };
}

/// Append-only. No hay método que lo edite ni lo borre.
class _AuditRecord {
  const _AuditRecord({
    required this.id,
    required this.actorId,
    required this.action,
    required this.entityId,
    required this.target,
    required this.createdAt,
    this.reason,
    this.liveId,
  });

  factory _AuditRecord.fromJson(Map<String, dynamic> json) => _AuditRecord(
    id: json['id'] as String,
    actorId: json['actorId'] as String?,
    action: AuditAction.values.byName(json['action'] as String),
    entityId: json['entityId'] as String,
    target: json['target'] as String,
    reason: switch (json['reason']) {
      final String name => ModerationReason.values.byName(name),
      _ => null,
    },
    liveId: json['liveId'] as String?,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );

  final String id;
  final String? actorId;
  final AuditAction action;
  final String entityId;
  final String target;
  final ModerationReason? reason;
  final String? liveId;
  final DateTime createdAt;

  Map<String, Object?> toJson() => {
    'id': id,
    'actorId': actorId,
    'action': action.name,
    'entityId': entityId,
    'target': target,
    'reason': reason?.name,
    'liveId': liveId,
    'createdAt': createdAt.toIso8601String(),
  };
}
