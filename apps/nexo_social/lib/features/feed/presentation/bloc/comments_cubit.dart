import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../../moderation/domain/entities/moderation_action.dart';
import '../../domain/entities/post_extras.dart';
import '../../domain/repositories/post_repository.dart';

/// Qué pasó con la última acción de la hoja. La View lo traduce.
///
/// [cannotComment] es un `forbidden` al comentar. Puede ser un post que
/// cerró los comentarios después de abrir la hoja o una sesión que el
/// servidor no reconoce: los dos llegan como `ForbiddenFailure`, así que la
/// copy no afirma cuál fue. El visitante ni siquiera llega acá: la hoja le
/// ofrece iniciar sesión en vez del campo.
enum CommentsNotice {
  sent,
  deleted,
  reported,
  failed,
  forbidden,
  cannotComment,
}

class CommentsState extends Equatable {
  const CommentsState({
    this.comments = const [],
    this.nextCursor,
    this.isLoading = true,
    this.isLoadingMore = false,
    this.isSending = false,
    this.failed = false,
    this.notice,
    this.noticeSerial = 0,
  });

  /// Del más viejo al más nuevo: se leen como conversación.
  final List<PostComment> comments;
  final String? nextCursor;
  final bool isLoading;

  /// Pidiendo la página siguiente. Sin esta guarda, dos toques rápidos en
  /// "ver más" pedían la misma página dos veces y la lista la mostraba doble.
  final bool isLoadingMore;
  final bool isSending;

  /// La lista no se pudo leer. Distinto de una lista vacía.
  final bool failed;
  final CommentsNotice? notice;
  final int noticeSerial;

  CommentsState copyWith({
    List<PostComment>? comments,
    String? Function()? nextCursor,
    bool? isLoading,
    bool? isLoadingMore,
    bool? isSending,
    bool? failed,
    CommentsNotice? notice,
    int? noticeSerial,
  }) => CommentsState(
    comments: comments ?? this.comments,
    nextCursor: nextCursor == null ? this.nextCursor : nextCursor(),
    isLoading: isLoading ?? this.isLoading,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
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
    isLoadingMore,
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
    if (cursor == null || state.isLoadingMore) return;
    emit(state.copyWith(isLoadingMore: true));
    try {
      final page = await _posts.comments(postId, cursor: cursor);
      if (isClosed) return;
      emit(
        state.copyWith(
          comments: mergeComments(state.comments, page.comments),
          nextCursor: () => page.nextCursor,
          isLoadingMore: false,
        ),
      );
    } on Failure {
      // Se puede volver a intentar con el mismo cursor.
      if (!isClosed) emit(state.copyWith(isLoadingMore: false));
    }
  }

  /// Une sin repetir y en orden de conversación.
  ///
  /// El servidor pagina del más viejo al más nuevo, así que un comentario
  /// propio enviado con páginas pendientes vuelve a llegar en la última: sin
  /// deduplicar aparecía dos veces, y sin ordenar quedaba arriba de
  /// comentarios más viejos que él.
  static List<PostComment> mergeComments(
    List<PostComment> current,
    List<PostComment> page,
  ) {
    final known = {for (final comment in current) comment.id};
    return [...current, ...page.where((comment) => !known.contains(comment.id))]
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
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
          // Antes todo `forbidden` se leía como "no acepta comentarios", y
          // eso le decía a un visitante que el post estaba cerrado.
          notice: switch (failure) {
            ForbiddenFailure() => CommentsNotice.cannotComment,
            MutedFailure() ||
            AccountSuspendedFailure() => CommentsNotice.forbidden,
            _ => CommentsNotice.failed,
          },
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
