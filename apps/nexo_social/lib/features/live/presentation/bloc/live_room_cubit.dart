import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../../moderation/domain/entities/moderation_action.dart';
import '../../../moderation/domain/repositories/moderation_repository.dart';
import '../../../subscriptions/domain/repositories/subscription_repository.dart';
import '../../domain/entities/live_comment.dart';
import '../../domain/entities/live_reaction.dart';
import '../../domain/entities/live_room_event.dart';
import '../../domain/entities/live_moderation.dart';
import '../../domain/entities/live_permissions.dart';
import '../../domain/entities/live_session.dart';
import '../../domain/entities/live_stage.dart';
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
    this.audit = const [],
    this.isLoading = true,
    this.notFound = false,
    this.newSubscribers,
    this.donationsUsd,
    this.elapsed = Duration.zero,
    this.issue,
    this.issueSerial = 0,
    this.reconnecting = false,
    this.stage = LiveStage.empty,
    this.highlightedComment,
    this.myMute,
    this.exclusion,
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

  /// Quién habla y quién pidió la palabra (SDD 0011).
  final LiveStage stage;

  /// La pregunta que host, moderador o un invitado destacaron.
  final LiveComment? highlightedComment;

  /// El silencio propio en el chat de esta sala. La View lo compara con el
  /// reloj (`LiveChatMute.activeAt`): vence solo.
  final LiveChatMute? myMute;

  /// Si quien mira fue expulsado o baneado. La sala lo dice y deja de
  /// reconectarse: insistir sería pedirle al servidor que repita el "no".
  final LiveSanctionKind? exclusion;

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

  bool get isOnStage => stage.meOnStage;
  bool get handRaised => stage.myHandRaised;

  /// Si se dibuja el control de una acción propia: el repertorio del rol. La
  /// hoja de una persona usa `LivePermissions.on`.
  bool can(LiveAction action) => LivePermissions.hasAction(role, action);

  bool get canModerate => LivePermissions.hasAction(role, LiveAction.hideChat);

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
    List<String>? audit,
    bool? isLoading,
    bool? notFound,
    int? newSubscribers,
    int? donationsUsd,
    Duration? elapsed,
    LiveRoomIssue? issue,
    int? issueSerial,
    bool? reconnecting,
    LiveStage? stage,
    LiveComment? highlightedComment,
    LiveChatMute? myMute,
    LiveSanctionKind? exclusion,
    bool clearPinned = false,
    bool clearHighlighted = false,
    bool clearMute = false,
    bool? loadFailed,
    bool? locked,
    bool? handedOff,
  }) => LiveRoomState(
    session: session ?? this.session,
    role: role ?? this.role,
    loved: loved ?? this.loved,
    comments: comments ?? this.comments,
    pinnedComment: clearPinned ? null : pinnedComment ?? this.pinnedComment,
    audit: audit ?? this.audit,
    isLoading: isLoading ?? this.isLoading,
    notFound: notFound ?? this.notFound,
    newSubscribers: newSubscribers ?? this.newSubscribers,
    donationsUsd: donationsUsd ?? this.donationsUsd,
    elapsed: elapsed ?? this.elapsed,
    issue: issue ?? this.issue,
    issueSerial: issueSerial ?? this.issueSerial,
    reconnecting: reconnecting ?? this.reconnecting,
    stage: stage ?? this.stage,
    highlightedComment: clearHighlighted
        ? null
        : highlightedComment ?? this.highlightedComment,
    myMute: clearMute ? null : myMute ?? this.myMute,
    exclusion: exclusion ?? this.exclusion,
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
    audit,
    isLoading,
    notFound,
    newSubscribers,
    donationsUsd,
    elapsed,
    issue,
    issueSerial,
    reconnecting,
    stage,
    highlightedComment,
    myMute,
    exclusion,
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
            if (error is ForbiddenFailure) {
              // Al conectarse sólo se rechaza a quien fue expulsado o
              // baneado de esta sala.
              _exclude(state.exclusion ?? LiveSanctionKind.kick);
              return settle();
            }
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
      case LiveRoomSnapshot(
        :final session,
        :final role,
        :final comments,
        :final stage,
        :final pinned,
        :final highlighted,
        :final myMute,
        :final exclusion,
      ):
        if (exclusion != null) return _exclude(exclusion);
        emit(
          state.copyWith(
            session: session,
            role: role,
            comments: comments,
            stage: stage,
            pinnedComment: pinned,
            clearPinned: pinned == null,
            highlightedComment: highlighted,
            clearHighlighted: highlighted == null,
            myMute: myMute,
            clearMute: myMute == null,
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
      case LiveStageChanged(:final stage):
        emit(state.copyWith(stage: stage));
      case LiveRoleChanged(:final role, isMine: true):
        emit(state.copyWith(role: role));
      case LiveRoleChanged():
        break;
      case LiveSanctioned(:final kind, :final until, isMine: true):
        if (kind == LiveSanctionKind.chatMute) {
          final mute = LiveChatMute(until: until);
          emit(
            mute.activeAt(_now())
                ? state.copyWith(myMute: mute)
                : state.copyWith(clearMute: true),
          );
        } else {
          return _exclude(kind);
        }
      case LiveSanctioned():
        break;
      case LiveCommentDeleted(:final commentId):
        _dropComment(commentId);
      case LiveCommentRestored(:final comment):
        _restoreComment(comment);
      case LivePinnedChanged(:final comment):
        emit(
          state.copyWith(pinnedComment: comment, clearPinned: comment == null),
        );
      case LiveHighlightChanged(:final comment):
        emit(
          state.copyWith(
            highlightedComment: comment,
            clearHighlighted: comment == null,
          ),
        );
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

  /// Fuera de la sala: deja de escuchar y de reconectarse.
  void _exclude(LiveSanctionKind kind) {
    _reconnect?.cancel();
    unawaited(_events?.cancel());
    _events = null;
    emit(
      state.copyWith(exclusion: kind, isLoading: false, reconnecting: false),
    );
  }

  /// Un comentario que vuelve entra en su lugar, no al final: el orden del
  /// chat es el de llegada.
  void _restoreComment(LiveComment comment) {
    if (state.comments.any((c) => c.id == comment.id)) return;
    final id = int.tryParse(comment.id);
    final comments = [...state.comments];
    final at = id == null
        ? comments.length
        : comments.indexWhere((c) => (int.tryParse(c.id) ?? 0) > id);
    comments.insert(at < 0 ? comments.length : at, comment);
    emit(state.copyWith(comments: comments));
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

  /// Registra una acción de moderación que no oculta nada (silenciar,
  /// bloquear). El registro es append-only: una auditoría que borra lo que
  /// audita no prueba nada.
  void recordModeration(String entry) =>
      emit(state.copyWith(audit: [...state.audit, entry]));

  /// Fija un mensaje arriba del chat, reemplazando el anterior, o lo despega
  /// con null. Lo que se ve es lo que vuelve del servidor.
  Future<void> pinComment(LiveComment? comment) =>
      _moderate((id) => _repository.pinComment(id, comment?.id));

  // --- Moderación de la sala (SDD 0011, Etapa 3) ---------------------------

  Future<void> highlightQuestion(LiveComment? comment) =>
      _moderate((id) => _repository.highlightQuestion(id, comment?.id));

  /// Borra para todos y del replay. A diferencia de ocultar, no vuelve.
  Future<void> deleteComment(LiveComment comment) =>
      _moderate((id) => _repository.deleteComment(id, comment.id));

  Future<void> unhideComment(String commentId) =>
      _moderate((id) => _repository.unhideComment(id, commentId));

  Future<void> muteInChat(String userId, LiveMuteDuration duration) =>
      _moderate((id) => _repository.muteChat(id, userId, duration));

  Future<void> unmuteInChat(String userId) =>
      _moderate((id) => _repository.unmuteChat(id, userId));

  Future<void> kick(String userId) =>
      _moderate((id) => _repository.kick(id, userId));

  Future<void> ban(String userId) =>
      _moderate((id) => _repository.ban(id, userId));

  /// Nombra al moderador del vivo, o lo quita con null.
  Future<void> assignModerator(String? userId) =>
      _moderate((id) => _repository.assignModerator(id, userId));

  Future<void> _moderate(Future<void> Function(String liveId) action) =>
      _onStage(action);

  // --- Escenario (SDD 0011) -------------------------------------------------
  //
  // El servidor decide y el resultado vuelve por `watch` (`stage` y, si
  // cambió un rol, `roleChanged`): acá no se aplica nada a mano, así que la
  // sala nunca muestra un escenario que el servidor no aceptó. Un rechazo
  // llega como `issue`.

  Future<void> raiseHand() => _onStage((id) => _repository.raiseHand(id));
  Future<void> lowerHand() => _onStage((id) => _repository.lowerHand(id));
  Future<void> leaveStage() => _onStage((id) => _repository.leaveStage(id));

  Future<void> approveRequest(String userId) =>
      _onStage((id) => _repository.approveRequest(id, userId));

  Future<void> denyRequest(String userId) =>
      _onStage((id) => _repository.denyRequest(id, userId));

  Future<void> inviteToStage(String userId) =>
      _onStage((id) => _repository.inviteToStage(id, userId));

  Future<void> removeFromStage(String userId) =>
      _onStage((id) => _repository.removeFromStage(id, userId));

  /// El micrófono propio: lo apaga o lo prende.
  Future<void> toggleMyMic() {
    final me = state.stage.me;
    if (me == null) return Future.value();
    return _onStage(
      (id) => _repository.setMicMuted(id, me.userId, muted: !me.micMuted),
    );
  }

  /// Silenciar el micrófono de otro. Reactivarlo es de esa persona (S11).
  Future<void> muteSpeaker(String userId) =>
      _onStage((id) => _repository.setMicMuted(id, userId, muted: true));

  Future<void> toggleMyCamera() {
    final me = state.stage.me;
    if (me == null) return Future.value();
    return _onStage((id) => _repository.setCamera(id, on: !me.cameraOn));
  }

  /// Manda una reacción efímera. El servidor rechaza al pasarse del límite —
  /// y lo descarta en silencio, no es error (D7 del SDD 0011) —, así que acá
  /// un `tooFast` se traga para que no se le pida nada al usuario por una
  /// restricción propia nuestra. El eco llega por el stream.
  Future<void> react(LiveReactionKind kind) async {
    final session = state.session;
    if (session == null) return;
    try {
      await _repository.react(session.id, kind);
    } on RateLimitedFailure {
      // Silencio deliberado: no es un fallo del usuario.
    } on Failure catch (failure) {
      if (isClosed) return;
      emit(
        state.copyWith(
          issue: switch (failure) {
            CreatorNotVerifiedFailure() => LiveRoomIssue.notVerified,
            ForbiddenFailure() => LiveRoomIssue.forbidden,
            AccountSuspendedFailure() => LiveRoomIssue.suspended,
            MutedFailure() => LiveRoomIssue.muted,
            ConflictFailure() => LiveRoomIssue.conflict,
            _ => LiveRoomIssue.other,
          },
          issueSerial: state.issueSerial + 1,
        ),
      );
    }
  }

  Future<void> _onStage(Future<void> Function(String liveId) action) async {
    final session = state.session;
    if (session == null) return;
    await _try(() => action(session.id));
  }

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
