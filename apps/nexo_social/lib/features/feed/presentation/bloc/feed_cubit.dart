import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/storage/mock_social_store.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/mock_content.dart';
import '../../domain/entities/feed_filter.dart';
import '../../domain/entities/post.dart';
import '../../domain/usecases/get_feed_status.dart';

sealed class FeedState extends Equatable {
  const FeedState();

  @override
  List<Object?> get props => const [];
}

class FeedInitial extends FeedState {
  const FeedInitial();
}

class FeedLoading extends FeedState {
  const FeedLoading();
}

class FeedLoaded extends FeedState {
  const FeedLoaded(this.posts, {this.filter = FeedFilter.forYou});

  /// Everything the feed holds, unfiltered. The filter is applied on read so
  /// switching tabs never drops a post from memory and never needs a refetch.
  final List<Post> posts;
  final FeedFilter filter;

  List<Post> get visible => switch (filter) {
    FeedFilter.forYou => posts,
    FeedFilter.following => posts.where((post) => post.isFollowed).toList(),
    FeedFilter.live => posts.where((post) => post.isLive).toList(),
    FeedFilter.communities =>
      posts.where((post) => post.tags.isNotEmpty).toList(),
  };

  FeedLoaded copyWith({List<Post>? posts, FeedFilter? filter}) =>
      FeedLoaded(posts ?? this.posts, filter: filter ?? this.filter);

  // Equatable on every field. A missing entry here is a silent no-rebuild:
  // the cubit emits, the state compares equal and the UI never redraws.
  @override
  List<Object?> get props => [posts, filter];
}

class FeedFailure extends FeedState {
  const FeedFailure();
}

class FeedCubit extends Cubit<FeedState> {
  FeedCubit(this._getFeedStatus, [this._store]) : super(const FeedInitial()) {
    // The feed is not rebuilt when the user returns from the composer: the
    // shell keeps one navigator per tab, so this cubit and its list survive.
    // Without this subscription a published post only showed up after a
    // restart.
    _changes = _store?.watchPosts().listen(_onStoreChanged);
  }

  final GetFeedStatus _getFeedStatus;
  final MockSocialStore? _store;

  StreamSubscription<List<Post>>? _changes;

  void _onStoreChanged(List<Post> posts) {
    final current = state;
    // Only while showing content. Overwriting a loading or failed state with
    // a store write would hide the fact that the read never succeeded.
    if (current is FeedLoaded) emit(current.copyWith(posts: posts));
  }

  @override
  Future<void> close() async {
    await _changes?.cancel();
    return super.close();
  }

  Future<void> load() async {
    emit(const FeedLoading());
    try {
      final status = await _getFeedStatus(const NoParams());
      if (!status.isReady) {
        emit(const FeedFailure());
        return;
      }
      emit(FeedLoaded(_store?.readPosts() ?? MockContent.seed()));
    } catch (_) {
      emit(const FeedFailure());
    }
  }

  Future<void> refresh() => load();

  void selectFilter(FeedFilter filter) {
    final current = state;
    if (current is FeedLoaded) emit(current.copyWith(filter: filter));
  }

  void toggleLike(String id) =>
      _update(id, (post) => post.copyWith(isLiked: !post.isLiked));

  void toggleSave(String id) =>
      _update(id, (post) => post.copyWith(isSaved: !post.isSaved));

  void _update(String id, Post Function(Post) transform) {
    final current = state;
    if (current is! FeedLoaded) return;
    final posts = current.posts
        .map((post) => post.id == id ? transform(post) : post)
        .toList();
    emit(current.copyWith(posts: posts));
    _store?.savePosts(posts);
  }
}
