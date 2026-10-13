import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../../moderation/domain/entities/moderation_action.dart';
import '../../../moderation/domain/repositories/moderation_repository.dart';
import '../../../subscriptions/domain/repositories/subscription_repository.dart';
import '../../domain/entities/live_comment.dart';
import '../../domain/entities/live_room_event.dart';
import '../../domain/entities/live_session.dart';
import '../../domain/repositories/live_repository.dart';
import '../../domain/studio_show.dart';

export '../../domain/entities/live_comment.dart';

/// Por qué el servidor rechazó una acción de la sala. Un motivo tipado y no
/// un mensaje: el cubit no tiene `BuildContext` y la copy la elige la View.
enum LiveRoomIssue {
  notVerified,
  forbidden,
  suspended,
  muted,
  tooFast,
  conflict,
  other,
}

class LiveRoomState extends Equatable {
  const LiveRoomState({
    this.session,
    this.role = LiveRole.audience,
    this.loved = false,
    this.comments = const [],
    this.pinnedComment,
    this.pendingGuests = const [],
    this.audit = const [],
    this.isLoading = true,
    this.notFound = false,
    this.newSubscribers,
    this.donationsUsd,
    this.elapsed = Duration.zero,
    this.issue,
    this.issueSerial = 0,
    this.reconnecting = false,
    this.loadFailed = false,
    this.locked = false,
    this.handedOff = false,
  });

  /// Null while loading, and when the id does not resolve.
  final LiveSession? session;

  /// El rol de quien mira. Decide qué ofrece la hoja de moderación; el
  /// permiso lo vuelve a verificar el servidor igual.
  final LiveRole role;
  final bool loved;

  /// Sólo los visibles. Los ocultos no salen del servidor: siguen ahí como
  /// evidencia, pero no para la audiencia.
  final List<LiveComment> comments;

  /// El mensaje que moderación fijó arriba del chat. Uno solo: dos mensajes
  /// fijados no destacan nada, y el chat de un vivo sólo tiene espacio para
  /// una cosa que importe más que lo que está pasando.
  final LiveComment? pinnedComment;
  final List<String> pendingGuests;

  /// Every moderation action, newest last. The demo shows this to prove the
  /// action was recorded and not just hidden from view.
  final List<String> audit;

  final bool isLoading;
  final bool notFound;

  // Métricas de sesión del panel de host. Sin módulo de billing no hay de
  // dónde sacarlas, así que son null y el Studio dibuja "—": un número
  // inventado en un panel de host se lee como un dato.
  final int? newSubscribers;
  final int? donationsUsd;

  /// Cuánto lleva al aire. La cuenta la lleva el estado y no un timer en el
  /// widget: la pantalla del host se reconstruye con cada aprobación de cohost
  /// y un contador en el State se reiniciaría en cada una.
  final Duration elapsed;

  /// El último rechazo. [issueSerial] crece con cada uno, así que el mismo
  /// rechazo dos veces seguidas también se avisa dos veces.
  final LiveRoomIssue? issue;
  final int issueSerial;

  /// Se cortó la conexión en tiempo real y la sala está volviendo a
  /// conectarse. La View lo dice en vez de quedarse congelada.
  final bool reconnecting;

  /// El Studio no pudo traer los shows del host. No es lo mismo que no tener
  /// ninguno: con `notFound` la View ofrecía programar uno mientras el
  /// servidor estaba caído, y el host creía haber perdido su agenda.
  final bool loadFailed;

  /// El vivo es sólo para miembros y quien mira no lo es (o todavía no se
  /// sabe). La sala no entra al video: muestra la invitación a sumarse.
  final bool locked;

  /// El host abrió su propio vivo desde la sala y se fue a su Studio. La sala
  /// deja de escucharlo: si no, el branch de Inicio lo seguía contando como
  /// espectador de sí mismo.
  final bool handedOff;

  bool get canModerate => role == LiveRole.host || role == LiveRole.moderator;

  /// Si quien mira puede escribir en el chat. Con las preguntas apagadas
  /// sólo escriben el host y quienes moderan: la audiencia mira.
  bool get canComment =>
      session?.allowQuestions != false || role != LiveRole.audience;

  LiveRoomState copyWith({
    LiveSession? session,
    LiveRole? role,
    bool? loved,
    List<LiveComment>? comments,
    LiveComment? pinnedComment,
    List<String>? pendingGuests,
    List<String>? audit,
    bool? isLoading,
    bool? notFound,
    int? newSubscribers,
    int? donationsUsd,
    Duration? elapsed,
    LiveRoomIssue? issue,
    int? issueSerial,
    bool? reconnecting,
    bool? loadFailed,
    bool? locked,
    bool? handedOff,
  }) => LiveRoomState(
    session: session ?? this.session,
    role: role ?? this.role,
    loved: loved ?? this.loved,
    comments: comments ?? this.comments,
    pinnedComment: pinnedComment ?? this.pinnedComment,
    pendingGuests: pendingGuests ?? this.pendingGuests,
    audit: audit ?? this.audit,
    isLoading: isLoading ?? this.isLoading,
    notFound: notFound ?? this.notFound,
    newSubscribers: newSubscribers ?? this.newSubscribers,
    donationsUsd: donationsUsd ?? this.donationsUsd,
    elapsed: elapsed ?? this.elapsed,
    issue: issue ?? this.issue,
    issueSerial: issueSerial ?? this.issueSerial,
    reconnecting: reconnecting ?? this.reconnecting,
    loadFailed: loadFailed ?? this.loadFailed,
    locked: locked ?? this.locked,
    handedOff: handedOff ?? this.handedOff,
  );

  @override
  List<Object?> get props => [
    session,
    role,
    loved,
    comments,
    pinnedComment,
    pendingGuests,
    audit,
    isLoading,
    notFound,
    newSubscribers,
    donationsUsd,
    elapsed,
    issue,
    issueSerial,
    reconnecting,
    loadFailed,
    locked,
    handedOff,
  ];
}

class LiveRoomCubit extends Cubit<LiveRoomState> {
  LiveRoomCubit(
    this._repository,
    this._moderation, {
    this._subscriptions,
    DateTime Function()? now,
    this.reconnectDelays = defaultReconnectDelays,
  }) : _now = now ?? DateTime.now,
       super(const LiveRoomState());

  final LiveRepository _repository;
  final ModerationRepository _moderation;

  /// De dónde sale si quien mira es miembro del host. Null: no hay fuente, y
  /// la sala no bloquea nada (el servidor tampoco lo exige todavía).
  final SubscriptionRepository? _subscriptions;
  final DateTime Function() _now;

  StreamSubscription<LiveRoomEvent>? _events;
  StreamSubscription<void>? _studioChanges;
  Timer? _reconnect;
  Timer? _clock;
  int _attempt = 0;

  /// El vivo que escucha la sala, para retomarlo después de [pause].
  String? _liveId;

  /// La pantalla no está a la vista (otra pestaña, otra ruta encima). Sin
  /// escuchar, el servidor no la cuenta como espectadora.
  bool _paused = false;

  /// El host cuya membresía ya se consultó. Una consulta por host y no una
  /// por cada evento: la sala recibe uno cada pocos segundos.
  String? _accessCheckedFor;

  /// El `?show=` con el que se abrió el Studio, para recargarlo igual.
  String? _studioRequested;

  /// Entre reintentos cuando se corta la sala: rápido al principio y después
  /// cada 5 s, sin rendirse mientras la pantalla esté abierta.
  final List<Duration> reconnectDelays;

  static const defaultReconnectDelays = [
    Duration(seconds: 1),
    Duration(seconds: 2),
    Duration(seconds: 5),
  ];

  /// Abre la sala y se queda escuchándola. Termina cuando llega la primera
  /// foto (o cuando queda claro que la sala no existe).
  Future<void> load(String id) async {
    _liveId = id;
    _paused = false;
    emit(state.copyWith(isLoading: true, notFound: false, loadFailed: false));
    final ready = Completer<void>();
    _subscribe(id, ready);
    await ready.future;
  }

  /// La sala escucha al servidor: un comentario que se oculta desde la
  /// consola, un espectador que entra o un vivo que el operador corta llegan
  /// sin recargar.
  void _subscribe(String id, [Completer<void>? ready]) {
    unawaited(_events?.cancel());
    void settle() {
      if (ready != null && !ready.isCompleted) ready.complete();
    }

    _events = _repository
        .watch(id)
        .listen(
          (event) {
            if (isClosed) return;
            _attempt = 0;
            _apply(event);
            settle();
          },
          onError: (Object error) {
            if (isClosed) return settle();
            if (error is NotFoundFailure) {
              emit(
                state.copyWith(
                  isLoading: false,
                  notFound: true,
                  reconnecting: false,
                ),
              );
              unawaited(_events?.cancel());
              return settle();
            }
            _scheduleReconnect(id);
            settle();
          },
          onDone: () {
            settle();
            if (!isClosed && !state.notFound) _scheduleReconnect(id);
          },
          cancelOnError: false,
        );
  }

  void _scheduleReconnect(String id) {
    if (isClosed || _paused || (_reconnect?.isActive ?? false)) return;
    unawaited(_events?.cancel());
    _events = null;
    // Sin foto todavía, `reconnecting` sin `session` es la pantalla de
    // espera, no la de "este vivo ya no está": eso lo dice sólo `notFound`.
    emit(
      state.copyWith(
        isLoading: state.session == null ? false : null,
        reconnecting: true,
      ),
    );
    final delay =
        reconnectDelays[_attempt.clamp(0, reconnectDelays.length - 1)];
    _attempt++;
    _reconnect = Timer(delay, () {
      if (!isClosed) _subscribe(id);
    });
  }

  void _apply(LiveRoomEvent event) {
    switch (event) {
      case LiveRoomSnapshot(:final session, :final role, :final comments):
        emit(
          state.copyWith(
            session: session,
            role: role,
            comments: comments,
            isLoading: false,
            notFound: false,
            reconnecting: false,
          ),
        );
      case LiveSessionChanged(:final session):
        emit(state.copyWith(session: session));
      case LiveViewersChanged(:final viewers):
        final session = state.session;
        if (session != null) {
          emit(state.copyWith(session: session.copyWith(viewers: viewers)));
        }
      case LiveCommentAdded(:final comment):
        _addComment(comment);
      case LiveCommentHidden(:final commentId):
        _dropComment(commentId);
    }
    _syncClock();
    _syncAccess();
  }

  /// Un vivo "Solo miembros" no entra al video para quien no lo es. Mientras
  /// se consulta queda bloqueado: abrir el video y cortarlo un segundo
  /// después es mostrar justo lo que se cobra.
  ///
  /// El host, sus cohosts y quienes moderan no pasan por acá: el rol lo
  /// decide el servidor.
  void _syncAccess() {
    final session = state.session;
    final subscriptions = _subscriptions;
    if (session == null ||
        !session.isPremium ||
        state.role != LiveRole.audience ||
        subscriptions == null) {
      _accessCheckedFor = null;
      if (state.locked) emit(state.copyWith(locked: false));
      return;
    }
    // El mock no conoce el handle del host: cae a su id.
    final host = session.hostUsername.isEmpty
        ? session.hostId
        : session.hostUsername;
    if (_accessCheckedFor == host) return;
    _accessCheckedFor = host;
    emit(state.copyWith(locked: true));
    unawaited(_checkMembership(subscriptions, host));
  }

  Future<void> _checkMembership(
    SubscriptionRepository subscriptions,
    String host,
  ) async {
    try {
      final entitlement = await subscriptions.entitlement(host);
      if (isClosed || _accessCheckedFor != host) return;
      emit(state.copyWith(locked: !entitlement.active));
    } on Failure {
      // Sin respuesta no se abre: queda la invitación, y volver del paywall
      // pregunta de nuevo ([refreshAccess]).
    }
  }

  /// Vuelve a preguntar por la membresía, por ejemplo al volver del paywall.
  void refreshAccess() {
    _accessCheckedFor = null;
    _syncAccess();
  }

  /// La pantalla dejó de estar a la vista: deja de escuchar la sala para no
  /// contar como espectadora. No emite: se llama mientras el árbol cambia.
  void pause() {
    if (_paused) return;
    _paused = true;
    _reconnect?.cancel();
    _reconnect = null;
    unawaited(_events?.cancel());
    _events = null;
  }

  /// Vuelve a escuchar la sala. Llega una foto nueva, así que lo que pasó
  /// mientras no se miraba se resincroniza solo.
  void resume() {
    if (!_paused || isClosed || state.handedOff || state.notFound) return;
    _paused = false;
    final id = _liveId;
    if (id != null) _subscribe(id);
  }

  /// El host abrió su propio vivo como audiencia y se va a su Studio. La
  /// sala deja de escuchar y no lo retoma: el host no es espectador de sí
  /// mismo, y el branch de Inicio conserva la página montada.
  void handOffToStudio() {
    pause();
    emit(state.copyWith(handedOff: true));
  }

  /// El reloj del Studio sale de `startedAt`, no de un contador: cerrar y
  /// volver a abrir el panel a mitad de un vivo muestra el tiempo real.
  void _syncClock() {
    final startedAt = state.session?.startedAt;
    final onAir =
        state.session?.status == LiveStatus.live ||
        state.session?.status == LiveStatus.ending;
    if (startedAt == null || !onAir) {
      _clock?.cancel();
      _clock = null;
      return;
    }
    _tick(startedAt);
    _clock ??= Timer.periodic(const Duration(seconds: 1), (_) {
      final current = state.session?.startedAt;
      if (!isClosed && current != null) _tick(current);
    });
  }

  void _tick(DateTime startedAt) {
    final elapsed = _now().difference(startedAt);
    emit(state.copyWith(elapsed: elapsed.isNegative ? Duration.zero : elapsed));
  }

  /// Deduplica por id: el comentario propio vuelve como eco del servidor.
  void _addComment(LiveComment comment) {
    if (state.comments.any((item) => item.id == comment.id)) return;
    emit(state.copyWith(comments: [...state.comments, comment]));
  }

  void _dropComment(String commentId) {
    if (!state.comments.any((item) => item.id == commentId)) return;
    emit(
      state.copyWith(
        comments: [
          for (final item in state.comments)
            if (item.id != commentId) item,
        ],
      ),
    );
  }

  /// El Studio: abre el show del host en sesión según [pickStudioShow]. Sin
  /// ninguno, queda en `notFound` y la View ofrece programar uno; si el
  /// servidor falla, en `loadFailed` y la View ofrece reintentar.
  ///
  /// Mientras no hay show, el Studio escucha los cambios de vivos: uno recién
  /// programado (desde acá o desde "Crear") aparece sin recargar. Se cargaba
  /// una sola vez, y volver de programar dejaba "Todavía no tienes un vivo".
  Future<void> loadStudio({String? requested}) async {
    _studioRequested = requested;
    _studioChanges ??= _repository.changes().listen((_) {
      if (isClosed || state.session != null || state.isLoading) return;
      unawaited(loadStudio(requested: _studioRequested));
    });
    emit(state.copyWith(isLoading: true, notFound: false, loadFailed: false));
    final List<LiveSession> mine;
    try {
      mine = await _repository.mine();
    } on Failure {
      if (!isClosed) emit(state.copyWith(isLoading: false, loadFailed: true));
      return;
    }
    if (isClosed) return;
    final show = pickStudioShow(mine, requested: requested);
    if (show == null) {
      emit(state.copyWith(isLoading: false, notFound: true));
      return;
    }
    await load(show.id);
  }

  /// "Transmitir ahora": el servidor crea el vivo y lo pone al aire en un
  /// paso, con el mismo gate que iniciar uno programado. Después la pantalla
  /// pasa a escuchar el vivo nuevo, y el video entra solo porque ya está al
  /// aire.
  Future<void> goLive(String title) async {
    final body = title.trim();
    if (body.isEmpty) return;
    LiveSession? created;
    await _try(() async => created = await _repository.goLive(body));
    final session = created;
    if (session == null || isClosed) return;
    await load(session.id);
  }

  void toggleLove() => emit(state.copyWith(loved: !state.loved));

  /// `true` si el servidor lo aceptó. La View limpia el campo sólo entonces:
  /// borrarlo antes perdía el mensaje cuando el servidor decía que no
  /// (silenciado, demasiado rápido).
  Future<bool> sendComment(String text) async {
    final body = text.trim();
    final session = state.session;
    if (body.isEmpty || session == null || !state.canComment) return false;
    return _try(() async {
      _addComment(await _repository.postComment(session.id, body));
    });
  }

  /// Hides for everyone and keeps the evidence: the server marks it hidden
  /// instead of dropping it, because an audit trail that deletes what it
  /// audits proves nothing.
  Future<void> hideComment(LiveComment comment) async {
    final session = state.session;
    if (session == null) return;
    await _try(() async {
      await _repository.hideComment(session.id, comment.id);
      _dropComment(comment.id);
      emit(
        state.copyWith(
          audit: [...state.audit, 'Moderación ocultó a ${comment.author}'],
        ),
      );
    });
  }

  /// Cualquier cuenta puede reportar. El reporte va a la cola de la consola.
  Future<void> reportComment(
    LiveComment comment, [
    ModerationReason reason = ModerationReason.harassment,
  ]) async {
    final session = state.session;
    if (session == null) return;
    await _try(
      () => _moderation.reportComment(
        liveId: session.id,
        commentId: comment.id,
        reason: reason,
      ),
    );
  }

  /// Fija un mensaje arriba del chat, reemplazando el anterior.
  void pinComment(LiveComment comment) => emit(
    state.copyWith(
      pinnedComment: comment,
      audit: [
        ...state.audit,
        'Moderación fijó el mensaje de ${comment.author}',
      ],
    ),
  );

  void approveGuest(String guest) => emit(
    state.copyWith(
      pendingGuests: state.pendingGuests
          .where((item) => item != guest)
          .toList(),
      audit: [...state.audit, '$guest fue aprobado como cohost'],
    ),
  );

  /// "Rechazar" llamaba a [approveGuest]: el invitado se iba de la lista y la
  /// auditoría decía que había sido aprobado.
  void rejectGuest(String guest) => emit(
    state.copyWith(
      pendingGuests: state.pendingGuests
          .where((item) => item != guest)
          .toList(),
      audit: [...state.audit, 'Se rechazó la solicitud de $guest'],
    ),
  );

  /// El servidor decide. Un creador desverificado ve el botón de iniciar
  /// igual —esconderlo sería justo la trampa que la demo refuta— y es acá
  /// donde se entera de que no puede.
  Future<void> transition(LiveStatus status) async {
    final session = state.session;
    if (session == null) return;
    await _try(() async {
      emit(
        state.copyWith(
          session: await _repository.transition(session.id, status),
        ),
      );
      _syncClock();
    });
  }

  /// `true` si [action] terminó sin que el servidor la rechazara.
  Future<bool> _try(Future<void> Function() action) async {
    try {
      await action();
      return true;
    } on Failure catch (failure) {
      if (isClosed) return false;
      emit(
        state.copyWith(
          issue: switch (failure) {
            CreatorNotVerifiedFailure() => LiveRoomIssue.notVerified,
            ForbiddenFailure() => LiveRoomIssue.forbidden,
            AccountSuspendedFailure() => LiveRoomIssue.suspended,
            MutedFailure() => LiveRoomIssue.muted,
            RateLimitedFailure() => LiveRoomIssue.tooFast,
            ConflictFailure() => LiveRoomIssue.conflict,
            _ => LiveRoomIssue.other,
          },
          issueSerial: state.issueSerial + 1,
        ),
      );
      return false;
    }
  }

  @override
  Future<void> close() async {
    _reconnect?.cancel();
    _clock?.cancel();
    await _studioChanges?.cancel();
    await _events?.cancel();
    return super.close();
  }
}
