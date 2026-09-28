import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nexo_social/core/usecases/usecase.dart';
import 'package:nexo_social/features/feed/domain/entities/feed_filter.dart';
import 'package:nexo_social/features/feed/domain/entities/feed_status.dart';
import 'package:nexo_social/features/feed/domain/entities/post.dart';
import 'package:nexo_social/features/feed/domain/usecases/get_feed_status.dart';
import 'package:nexo_social/features/feed/presentation/bloc/feed_cubit.dart';

class MockGetFeedStatus extends Mock implements GetFeedStatus {}

void main() {
  late MockGetFeedStatus getFeedStatus;

  setUp(() {
    getFeedStatus = MockGetFeedStatus();
  });

  void serviceIsReady({bool ready = true}) => when(
    () => getFeedStatus(const NoParams()),
  ).thenAnswer((_) async => FeedStatus(isReady: ready));

  group('load', () {
    blocTest<FeedCubit, FeedState>(
      'emits loading then content when the service is available',
      setUp: serviceIsReady,
      build: () => FeedCubit(getFeedStatus),
      act: (cubit) => cubit.load(),
      expect: () => [isA<FeedLoading>(), isA<FeedLoaded>()],
    );

    /// A failed read is its own state. Without it, a dead endpoint and a slow
    /// one look identical: a spinner that never resolves.
    blocTest<FeedCubit, FeedState>(
      'emits a failure the user can retry from',
      setUp: () => serviceIsReady(ready: false),
      build: () => FeedCubit(getFeedStatus),
      act: (cubit) => cubit.load(),
      expect: () => [isA<FeedLoading>(), isA<FeedFailure>()],
    );

    blocTest<FeedCubit, FeedState>(
      'a thrown error is a failure, not an unhandled exception',
      setUp: () => when(
        () => getFeedStatus(const NoParams()),
      ).thenThrow(Exception('boom')),
      build: () => FeedCubit(getFeedStatus),
      act: (cubit) => cubit.load(),
      expect: () => [isA<FeedLoading>(), isA<FeedFailure>()],
    );
  });

  group('filters', () {
    Post post(String id, {bool live = false, bool followed = false}) => Post(
      id: id,
      author: 'a',
      name: 'A',
      body: 'b',
      tags: const ['t'],
      likes: 0,
      comments: 0,
      createdAt: DateTime(2026),
      isLive: live,
      isFollowed: followed,
    );

    test('forYou shows everything', () {
      final state = FeedLoaded([post('1'), post('2', live: true)]);
      expect(state.visible, hasLength(2));
    });

    test('live shows only broadcasting posts', () {
      final state = FeedLoaded([
        post('1'),
        post('2', live: true),
      ], filter: FeedFilter.live);
      expect(state.visible.single.id, '2');
    });

    test('following shows only followed authors', () {
      final state = FeedLoaded([
        post('1'),
        post('2', followed: true),
      ], filter: FeedFilter.following);
      expect(state.visible.single.id, '2');
    });

    /// An empty filter is a legitimate result, not an error — the screen shows
    /// a way back rather than a retry.
    test('a filter that matches nothing yields an empty list', () {
      final state = FeedLoaded([post('1')], filter: FeedFilter.live);
      expect(state.visible, isEmpty);
    });

    /// Filtering never drops posts from the state, so switching back needs no
    /// refetch.
    test('switching filters does not lose posts', () {
      final state = FeedLoaded([post('1'), post('2', live: true)]);
      final filtered = state.copyWith(filter: FeedFilter.live);
      expect(filtered.visible, hasLength(1));
      expect(
        filtered.copyWith(filter: FeedFilter.forYou).visible,
        hasLength(2),
      );
    });
  });

  group('reactions', () {
    blocTest<FeedCubit, FeedState>(
      'liking flips only the targeted post',
      setUp: serviceIsReady,
      build: () => FeedCubit(getFeedStatus),
      act: (cubit) async {
        await cubit.load();
        final loaded = cubit.state as FeedLoaded;
        cubit.toggleLike(loaded.posts.first.id);
      },
      verify: (cubit) {
        final posts = (cubit.state as FeedLoaded).posts;
        expect(posts.first.isLiked, isTrue);
        expect(posts.skip(1).every((post) => !post.isLiked), isTrue);
      },
    );

    /// The stored count never changes; the user's own like is added on read,
    /// so an optimistic tap cannot permanently inflate the number that comes
    /// back from the server.
    test('the like count is derived, not mutated', () {
      final post = Post(
        id: '1',
        author: 'a',
        name: 'A',
        body: 'b',
        tags: const [],
        likes: 482,
        comments: 0,
        createdAt: DateTime(2026),
      );

      expect(post.displayLikes, 482);
      expect(post.copyWith(isLiked: true).displayLikes, 483);
      // The stored value is untouched, so un-liking returns to exactly 482.
      expect(post.copyWith(isLiked: true).likes, 482);
      expect(
        post.copyWith(isLiked: true).copyWith(isLiked: false).displayLikes,
        482,
      );
    });
  });
}
