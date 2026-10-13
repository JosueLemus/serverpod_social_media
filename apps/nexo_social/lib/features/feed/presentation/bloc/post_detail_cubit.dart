import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../../moderation/domain/entities/moderation_action.dart';
import '../../domain/entities/post.dart';
import '../../domain/entities/post_extras.dart';
import '../../domain/repositories/post_repository.dart';

/// Un estado por resultado: una pantalla que sólo tiene spinner y contenido
/// hace que una publicación borrada se vea igual que una red lenta.
enum PostDetailStatus { loading, ready, notFound, failure, deleted }

/// Por qué avisar. La copy la elige la View: el cubit no tiene contexto.
enum PostDetailNotice { edited, reported, likeFailed, actionFailed, forbidden }

class PostDetailState extends Equatable {
  const PostDetailState({
    this.status = PostDetailStatus.loading,
    this.post,
    this.notice,
    this.noticeSerial = 0,
  });

  final PostDetailStatus status;
  final Post? post;
  final PostDetailNotice? notice;

  /// Crece con cada aviso, para que el mismo aviso dos veces seguidas se
  /// muestre dos veces.
  final int noticeSerial;

  PostDetailState copyWith({
    PostDetailStatus? status,
    Post? post,
    PostDetailNotice? notice,
    int? noticeSerial,
  }) => PostDetailState(
    status: status ?? this.status,
    post: post ?? this.post,
    notice: notice ?? this.notice,
    noticeSerial: noticeSerial ?? this.noticeSerial,
  );

  @override
  List<Object?> get props => [status, post, notice, noticeSerial];
}

/// Una publicación sola: la que se abre desde el feed, la grilla de un
/// perfil, una notificación o un enlace compartido.
class PostDetailCubit extends Cubit<PostDetailState> {
  PostDetailCubit(this._posts, this.postId) : super(const PostDetailState());

  final PostRepository _posts;
  final String postId;

  Future<void> load() async {
    emit(state.copyWith(status: PostDetailStatus.loading));
    await _fetch(silent: false);
  }

  /// Vuelve a pedirla sin pasar por "cargando": después de cerrar los
  /// comentarios, para que el contador quede al día.
  Future<void> refresh() => _fetch(silent: true);

  Future<void> _fetch({required bool silent}) async {
    try {
      final post = await _posts.get(postId);
      if (!isClosed) {
        emit(state.copyWith(status: PostDetailStatus.ready, post: post));
      }
    } on NotFoundFailure {
      if (!isClosed) emit(state.copyWith(status: PostDetailStatus.notFound));
    } on Failure {
      // Un refresco que falla no tapa lo que ya se ve.
      if (isClosed || (silent && state.post != null)) return;
      emit(state.copyWith(status: PostDetailStatus.failure));
    }
  }

  /// Optimista, como en el feed: el corazón cambia al toque y la respuesta
  /// del servidor manda. Si falla, vuelve como estaba.
  Future<void> toggleLike() async {
    final post = state.post;
    if (post == null) return;
    final liked = !post.isLiked;
    emit(
      state.copyWith(
        post: post.copyWith(
          isLiked: liked,
          likes: post.likes + (liked ? 1 : -1),
        ),
      ),
    );
    try {
      final result = await _posts.setLiked(post.id, liked: liked);
      final latest = state.post;
      if (!isClosed && latest != null) {
        emit(
          state.copyWith(
            post: latest.copyWith(isLiked: result.isLiked, likes: result.likes),
          ),
        );
      }
    } on Failure {
      if (isClosed) return;
      emit(state.copyWith(post: post));
      _notify(PostDetailNotice.likeFailed);
    }
  }

  /// Guardar todavía no tiene backend: es local, como en el feed.
  void toggleSave() {
    final post = state.post;
    if (post == null) return;
    emit(state.copyWith(post: post.copyWith(isSaved: !post.isSaved)));
  }

  /// Quién dio like. Lo pide la hoja; el cubit sólo pasa la consulta para
  /// que la vista no toque el repositorio.
  Future<List<PostLiker>> likers() => _posts.likers(postId);

  Future<void> edit(String body) async {
    try {
      final updated = await _posts.update(postId, body: body);
      if (isClosed) return;
      emit(state.copyWith(post: updated));
      _notify(PostDetailNotice.edited);
    } on Failure catch (failure) {
      _notify(_noticeFor(failure));
    }
  }

  /// Borrada, la pantalla no tiene qué mostrar: la View la cierra.
  Future<void> delete() async {
    try {
      await _posts.delete(postId);
      if (!isClosed) emit(state.copyWith(status: PostDetailStatus.deleted));
    } on Failure catch (failure) {
      _notify(_noticeFor(failure));
    }
  }

  Future<void> report(ModerationReason reason) async {
    try {
      await _posts.report(ReportTarget.post, postId, reason);
      _notify(PostDetailNotice.reported);
    } on Failure catch (failure) {
      _notify(_noticeFor(failure));
    }
  }

  void _notify(PostDetailNotice notice) {
    if (isClosed) return;
    emit(state.copyWith(notice: notice, noticeSerial: state.noticeSerial + 1));
  }

  static PostDetailNotice _noticeFor(Failure failure) =>
      failure is ForbiddenFailure
      ? PostDetailNotice.forbidden
      : PostDetailNotice.actionFailed;
}
