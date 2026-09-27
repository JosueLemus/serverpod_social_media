import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/live_session.dart';
import '../../domain/repositories/live_repository.dart';

class LiveRoomState {
  const LiveRoomState({
    required this.session,
    this.loved = false,
    this.comments = const ['Sofía: increíble explicación sobre tokens'],
    this.hiddenComments = const [],
    this.guests = const ['Marcos Dev'],
    this.audit = const [],
  });
  final LiveSession session;
  final bool loved;
  final List<String> comments;
  final List<String> hiddenComments;
  final List<String> guests;
  final List<String> audit;
  LiveRoomState copyWith({
    LiveSession? session,
    bool? loved,
    List<String>? comments,
    List<String>? hiddenComments,
    List<String>? guests,
    List<String>? audit,
  }) => LiveRoomState(
    session: session ?? this.session,
    loved: loved ?? this.loved,
    comments: comments ?? this.comments,
    hiddenComments: hiddenComments ?? this.hiddenComments,
    guests: guests ?? this.guests,
    audit: audit ?? this.audit,
  );
}

class LiveRoomCubit extends Cubit<LiveRoomState> {
  LiveRoomCubit(this._repository, LiveSession session)
    : super(LiveRoomState(session: session));
  final LiveRepository _repository;
  void toggleLove() => emit(state.copyWith(loved: !state.loved));
  void sendComment(String text) {
    if (text.trim().isNotEmpty) {
      emit(state.copyWith(comments: [...state.comments, 'Tú: ${text.trim()}']));
    }
  }

  void hideComment(String comment) => emit(
    state.copyWith(
      comments: state.comments.where((item) => item != comment).toList(),
      hiddenComments: [...state.hiddenComments, comment],
      audit: [...state.audit, 'Moderación ocultó: $comment'],
    ),
  );
  void approveGuest(String guest) => emit(
    state.copyWith(
      guests: state.guests.where((item) => item != guest).toList(),
      audit: [...state.audit, '$guest fue aprobado como cohost'],
    ),
  );
  Future<void> transition(LiveStatus status) async => emit(
    state.copyWith(
      session: await _repository.transition(state.session.id, status),
    ),
  );
}
