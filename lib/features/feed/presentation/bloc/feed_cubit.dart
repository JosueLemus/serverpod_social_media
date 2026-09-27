import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/storage/mock_social_store.dart';
import '../../../../core/utils/mock_content.dart';
import '../../domain/entities/post.dart';
import '../../domain/usecases/get_feed_status.dart';

sealed class FeedState {
  const FeedState();
}

class FeedInitial extends FeedState {
  const FeedInitial();
}

class FeedLoading extends FeedState {
  const FeedLoading();
}

class FeedLoaded extends FeedState {
  const FeedLoaded(this.posts);
  final List<Post> posts;
}

class FeedReady extends FeedState {
  const FeedReady();
}

class FeedFailure extends FeedState {
  const FeedFailure();
}

class FeedCubit extends Cubit<FeedState> {
  FeedCubit(this._getFeedStatus, [this._store]) : super(const FeedInitial());
  final GetFeedStatus _getFeedStatus;
  final MockSocialStore? _store;
  Future<void> load() async {
    emit(const FeedLoading());
    try {
      final status = await _getFeedStatus(const NoParams());
      emit(
        status.isReady
            ? FeedLoaded(_store?.readPosts() ?? List.of(MockContent.posts))
            : const FeedFailure(),
      );
    } catch (_) {
      emit(const FeedFailure());
    }
  }

  Future<void> checkStatus() async => load();
  void toggleLike(String id) =>
      _update(id, (post) => post.copyWith(isLiked: !post.isLiked));
  void toggleSave(String id) =>
      _update(id, (post) => post.copyWith(isSaved: !post.isSaved));
  void _update(String id, Post Function(Post) transform) {
    final current = state;
    if (current is FeedLoaded) {
      final posts = current.posts
          .map((post) => post.id == id ? transform(post) : post)
          .toList();
      emit(FeedLoaded(posts));
      _store?.savePosts(posts);
    }
  }
}
