import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../../moderation/domain/entities/moderation_action.dart';
import '../../../moderation/domain/repositories/moderation_repository.dart';
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

  bool get canModerate => role == LiveRole.host || role == LiveRole.moderator;

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
  ];
}

class LiveRoomCubit extends Cubit<LiveRoomState> {
  LiveRoomCubit(
    this._repository,
    this._moderation, {
    DateTime Function()? now,
    this.reconnectDelays = defaultReconnectDelays,
  }) : _now = now ?? DateTime.now,
       super(const LiveRoomState());

  final LiveRepository _repository;
  final ModerationRepository _moderation;
  final DateTime Function() _now;

  StreamSubscription<LiveRoomEvent>? _events;
  Timer? _reconnect;
  Timer? _clock;
  int _attempt = 0;

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
    emit(state.copyWith(isLoading: true, notFound: false));
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
    if (isClosed || (_reconnect?.isActive ?? false)) return;
    unawaited(_events?.cancel());
    _events = null;
    // Sin foto todavía no hay sala que mostrar "reconectando".
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
  /// ninguno, queda en `notFound` y la View ofrece programar uno.
  Future<void> loadStudio({String? requested}) async {
    emit(state.copyWith(isLoading: true, notFound: false));
    final List<LiveSession> mine;
    try {
      mine = await _repository.mine();
    } on Failure {
      if (!isClosed) emit(state.copyWith(isLoading: false, notFound: true));
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

  Future<void> sendComment(String text) async {
    final body = text.trim();
    final session = state.session;
    if (body.isEmpty || session == null) return;
    await _try(() async {
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

  Future<void> _try(Future<void> Function() action) async {
    try {
      await action();
    } on Failure catch (failure) {
      if (isClosed) return;
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
    }
  }

  @override
  Future<void> close() async {
    _reconnect?.cancel();
    _clock?.cancel();
    await _events?.cancel();
    return super.close();
  }
}
