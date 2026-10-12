import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../../moderation/domain/entities/moderation_action.dart';
import '../../domain/entities/post_extras.dart';
import '../../domain/repositories/post_repository.dart';

/// Qué pasó con la última acción de la hoja. La View lo traduce.
enum CommentsNotice { sent, deleted, reported, failed, forbidden, closed }

class CommentsState extends Equatable {
  const CommentsState({
    this.comments = const [],
    this.nextCursor,
    this.isLoading = true,
    this.isSending = false,
    this.failed = false,
    this.notice,
    this.noticeSerial = 0,
  });

  /// Del más viejo al más nuevo: se leen como conversación.
  final List<PostComment> comments;
  final String? nextCursor;
  final bool isLoading;
  final bool isSending;

  /// La lista no se pudo leer. Distinto de una lista vacía.
  final bool failed;
  final CommentsNotice? notice;
  final int noticeSerial;

  CommentsState copyWith({
    List<PostComment>? comments,
    String? Function()? nextCursor,
    bool? isLoading,
    bool? isSending,
    bool? failed,
    CommentsNotice? notice,
    int? noticeSerial,
  }) => CommentsState(
    comments: comments ?? this.comments,
    nextCursor: nextCursor == null ? this.nextCursor : nextCursor(),
    isLoading: isLoading ?? this.isLoading,
    isSending: isSending ?? this.isSending,
    failed: failed ?? this.failed,
    notice: notice ?? this.notice,
    noticeSerial: noticeSerial ?? this.noticeSerial,
  );

  @override
  List<Object?> get props => [
    comments,
    nextCursor,
    isLoading,
    isSending,
    failed,
    notice,
    noticeSerial,
  ];
}

/// Los comentarios de un post: leer, comentar, borrar y reportar.
class CommentsCubit extends Cubit<CommentsState> {
  CommentsCubit(this._posts, this.postId) : super(const CommentsState());

  final PostRepository _posts;
  final String postId;

  static const maxLength = 1000;

  Future<void> load() async {
    emit(state.copyWith(isLoading: true, failed: false));
    try {
      final page = await _posts.comments(postId);
      if (isClosed) return;
      emit(
        state.copyWith(
          comments: page.comments,
          nextCursor: () => page.nextCursor,
          isLoading: false,
        ),
      );
    } on Failure {
      if (!isClosed) emit(state.copyWith(isLoading: false, failed: true));
    }
  }

  Future<void> loadMore() async {
    final cursor = state.nextCursor;
    if (cursor == null) return;
    try {
      final page = await _posts.comments(postId, cursor: cursor);
      if (isClosed) return;
      emit(
        state.copyWith(
          comments: [...state.comments, ...page.comments],
          nextCursor: () => page.nextCursor,
        ),
      );
    } on Failure {
      // Se puede volver a intentar con el mismo cursor.
    }
  }

  /// Devuelve si se envió, para que la View limpie el campo sólo entonces:
  /// un comentario que falló no se pierde.
  Future<bool> send(String text) async {
    final body = text.trim();
    if (body.isEmpty || body.length > maxLength || state.isSending) {
      return false;
    }
    emit(state.copyWith(isSending: true));
    try {
      final comment = await _posts.addComment(postId, body);
      if (isClosed) return true;
      emit(
        state.copyWith(
          comments: [...state.comments, comment],
          isSending: false,
          notice: CommentsNotice.sent,
          noticeSerial: state.noticeSerial + 1,
        ),
      );
      return true;
    } on Failure catch (failure) {
      if (isClosed) return false;
      emit(
        state.copyWith(
          isSending: false,
          // `forbidden` al comentar es casi siempre un post con los
          // comentarios cerrados.
          notice: failure is ForbiddenFailure
              ? CommentsNotice.closed
              : CommentsNotice.failed,
          noticeSerial: state.noticeSerial + 1,
        ),
      );
      return false;
    }
  }

  Future<void> delete(PostComment comment) async {
    try {
      await _posts.deleteComment(comment.id);
      if (isClosed) return;
      emit(
        state.copyWith(
          comments: state.comments
              .where((item) => item.id != comment.id)
              .toList(),
          notice: CommentsNotice.deleted,
          noticeSerial: state.noticeSerial + 1,
        ),
      );
    } on Failure catch (failure) {
      _notify(failure);
    }
  }

  Future<void> report(PostComment comment, ModerationReason reason) async {
    try {
      await _posts.report(ReportTarget.comment, comment.id, reason);
      if (isClosed) return;
      emit(
        state.copyWith(
          notice: CommentsNotice.reported,
          noticeSerial: state.noticeSerial + 1,
        ),
      );
    } on Failure catch (failure) {
      _notify(failure);
    }
  }

  void _notify(Failure failure) {
    if (isClosed) return;
    emit(
      state.copyWith(
        notice: failure is ForbiddenFailure
            ? CommentsNotice.forbidden
            : CommentsNotice.failed,
        noticeSerial: state.noticeSerial + 1,
      ),
    );
  }
}
