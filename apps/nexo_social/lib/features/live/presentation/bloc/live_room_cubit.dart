import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/live_session.dart';
import '../../domain/repositories/live_repository.dart';

/// A chat message in the room. A value type rather than a formatted string:
/// the list needs to know who wrote it to render the author differently, and
/// moderation needs an id to hide the right one.
class LiveComment extends Equatable {
  const LiveComment({
    required this.id,
    required this.author,
    required this.body,
    this.isMine = false,
  });

  final String id;
  final String author;
  final String body;
  final bool isMine;

  @override
  List<Object?> get props => [id, author, body, isMine];
}

class LiveRoomState extends Equatable {
  const LiveRoomState({
    this.session,
    this.loved = false,
    this.comments = const [],
    this.hiddenComments = const [],
    this.pinnedComment,
    this.pendingGuests = const [],
    this.audit = const [],
    this.isLoading = true,
    this.notFound = false,
    this.newSubscribers = 0,
    this.donationsUsd = 0,
    this.elapsed = Duration.zero,
  });

  /// Null while loading, and when the id does not resolve.
  final LiveSession? session;
  final bool loved;
  final List<LiveComment> comments;
  final List<LiveComment> hiddenComments;

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

  LiveRoomState copyWith({
    LiveSession? session,
    bool? loved,
    List<LiveComment>? comments,
    List<LiveComment>? hiddenComments,
    LiveComment? pinnedComment,
    List<String>? pendingGuests,
    List<String>? audit,
    bool? isLoading,
    bool? notFound,
    int? newSubscribers,
    int? donationsUsd,
    Duration? elapsed,
  }) => LiveRoomState(
    session: session ?? this.session,
    loved: loved ?? this.loved,
    comments: comments ?? this.comments,
    hiddenComments: hiddenComments ?? this.hiddenComments,
    pinnedComment: pinnedComment ?? this.pinnedComment,
    pendingGuests: pendingGuests ?? this.pendingGuests,
    audit: audit ?? this.audit,
    isLoading: isLoading ?? this.isLoading,
    notFound: notFound ?? this.notFound,
    newSubscribers: newSubscribers ?? this.newSubscribers,
    donationsUsd: donationsUsd ?? this.donationsUsd,
    elapsed: elapsed ?? this.elapsed,
  );

  @override
  List<Object?> get props => [
    session,
    loved,
    comments,
    hiddenComments,
    pinnedComment,
    pendingGuests,
    audit,
    isLoading,
    notFound,
    newSubscribers,
    donationsUsd,
    elapsed,
  ];
}

class LiveRoomCubit extends Cubit<LiveRoomState> {
  LiveRoomCubit(this._repository) : super(const LiveRoomState());

  final LiveRepository _repository;

  static const _seedComments = [
    LiveComment(
      id: 'c1',
      author: 'Sofía',
      body: 'Increíble explicación sobre tokens 🔥',
    ),
    LiveComment(id: 'c2', author: 'Marcos', body: '¿Vas a subir el replay?'),
    LiveComment(id: 'c3', author: 'Laura', body: 'Acabo de donar 50 NexoCoins'),
  ];

  static const _seedPinned = LiveComment(
    id: 'pinned',
    author: 'Sofía Streamer',
    body: '¡Bienvenidos al directo! Descarguen el repo del enlace fijado.',
  );

  var _nextCommentId = 0;

  Future<void> load(String id) async {
    emit(state.copyWith(isLoading: true, notFound: false));
    final session = await _repository.byId(id);
    if (session == null) {
      emit(state.copyWith(isLoading: false, notFound: true));
      return;
    }
    emit(
      state.copyWith(
        session: session,
        isLoading: false,
        comments: _seedComments,
        pinnedComment: _seedPinned,
        pendingGuests: const ['Marcos Dev', 'Lucía Torres'],
        newSubscribers: 14,
        donationsUsd: 185,
        elapsed: const Duration(minutes: 42, seconds: 15),
      ),
    );
  }

  void toggleLove() => emit(state.copyWith(loved: !state.loved));

  void sendComment(String text) {
    final body = text.trim();
    if (body.isEmpty) return;
    emit(
      state.copyWith(
        comments: [
          ...state.comments,
          LiveComment(
            id: 'mine-${_nextCommentId++}',
            author: 'Tú',
            body: body,
            isMine: true,
          ),
        ],
      ),
    );
  }

  /// Hides for everyone and keeps the evidence. The comment moves to
  /// [LiveRoomState.hiddenComments] rather than being dropped: an audit trail
  /// that deletes what it audits proves nothing.
  void hideComment(LiveComment comment) => emit(
    state.copyWith(
      comments: state.comments.where((item) => item.id != comment.id).toList(),
      hiddenComments: [...state.hiddenComments, comment],
      audit: [...state.audit, 'Moderación ocultó a ${comment.author}'],
    ),
  );

  /// Registra una acción de moderación que no oculta nada (silenciar,
  /// bloquear, reportar). El registro es append-only: una auditoría que borra
  /// lo que audita no prueba nada.
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

  Future<void> transition(LiveStatus status) async {
    final session = state.session;
    if (session == null) return;
    emit(
      state.copyWith(session: await _repository.transition(session.id, status)),
    );
  }
}
