import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../../moderation/domain/entities/moderation_action.dart';
import '../../../moderation/domain/repositories/moderation_repository.dart';
import '../../domain/entities/live_comment.dart';
import '../../domain/entities/live_session.dart';
import '../../domain/repositories/live_repository.dart';

export '../../domain/entities/live_comment.dart';

/// Por qué el servidor rechazó una acción de la sala. Un motivo tipado y no
/// un mensaje: el cubit no tiene `BuildContext` y la copy la elige la View.
enum LiveRoomIssue { notVerified, forbidden, suspended, muted, conflict, other }

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
    this.newSubscribers = 0,
    this.donationsUsd = 0,
    this.elapsed = Duration.zero,
    this.issue,
    this.issueSerial = 0,
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

  // Métricas de sesión del panel de host. Mock hasta que exista el módulo de
  // billing — el Notion lo marca P1 con gateway falso, así que estos números
  // son de demo y no salen de ningún cobro real.
  final int newSubscribers;
  final int donationsUsd;

  /// Cuánto lleva al aire. La cuenta la lleva el estado y no un timer en el
  /// widget: la pantalla del host se reconstruye con cada aprobación de cohost
  /// y un contador en el State se reiniciaría en cada una.
  final Duration elapsed;

  /// El último rechazo. [issueSerial] crece con cada uno, así que el mismo
  /// rechazo dos veces seguidas también se avisa dos veces.
  final LiveRoomIssue? issue;
  final int issueSerial;

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
  ];
}

class LiveRoomCubit extends Cubit<LiveRoomState> {
  LiveRoomCubit(this._repository, this._moderation)
    : super(const LiveRoomState());

  final LiveRepository _repository;
  final ModerationRepository _moderation;
  StreamSubscription<void>? _changes;

  static const _seedPinned = LiveComment(
    id: 'pinned',
    author: 'Sofía Streamer',
    body: '¡Bienvenidos al directo! Descarguen el repo del enlace fijado.',
  );

  Future<void> load(String id) async {
    emit(state.copyWith(isLoading: true, notFound: false));
    final session = await _repository.byId(id);
    if (isClosed) return;
    if (session == null) {
      emit(state.copyWith(isLoading: false, notFound: true));
      return;
    }
    final role = await _repository.roleIn(id);
    final comments = await _repository.comments(id);
    if (isClosed) return;
    emit(
      state.copyWith(
        session: session,
        role: role,
        isLoading: false,
        comments: comments,
        pinnedComment: _seedPinned,
        pendingGuests: const ['Marcos Dev', 'Lucía Torres'],
        newSubscribers: 14,
        donationsUsd: 185,
        elapsed: const Duration(minutes: 42, seconds: 15),
      ),
    );
    // La sala escucha al servidor: un comentario que se oculta desde la
    // consola, o un vivo que el operador corta, llega sin recargar.
    await _changes?.cancel();
    _changes = _repository.changes().listen((_) => unawaited(_refresh(id)));
  }

  Future<void> _refresh(String id) async {
    final session = await _repository.byId(id);
    final role = await _repository.roleIn(id);
    final comments = await _repository.comments(id);
    // Cada await es una ventana en la que la sala pudo cerrarse.
    if (isClosed) return;
    if (session == null) {
      emit(state.copyWith(notFound: true));
      return;
    }
    emit(state.copyWith(session: session, role: role, comments: comments));
  }

  void toggleLove() => emit(state.copyWith(loved: !state.loved));

  Future<void> sendComment(String text) async {
    final body = text.trim();
    final session = state.session;
    if (body.isEmpty || session == null) return;
    await _attempt(() async {
      await _repository.postComment(session.id, body);
      emit(state.copyWith(comments: await _repository.comments(session.id)));
    });
  }

  /// Hides for everyone and keeps the evidence: the server marks it hidden
  /// instead of dropping it, because an audit trail that deletes what it
  /// audits proves nothing.
  Future<void> hideComment(LiveComment comment) async {
    final session = state.session;
    if (session == null) return;
    await _attempt(() async {
      await _repository.hideComment(session.id, comment.id);
      emit(
        state.copyWith(
          comments: await _repository.comments(session.id),
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
    await _attempt(
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

  /// El servidor decide. Un creador desverificado ve el botón de iniciar
  /// igual —esconderlo sería justo la trampa que la demo refuta— y es acá
  /// donde se entera de que no puede.
  Future<void> transition(LiveStatus status) async {
    final session = state.session;
    if (session == null) return;
    await _attempt(() async {
      emit(
        state.copyWith(
          session: await _repository.transition(session.id, status),
        ),
      );
    });
  }

  Future<void> _attempt(Future<void> Function() action) async {
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
    await _changes?.cancel();
    return super.close();
  }
}
