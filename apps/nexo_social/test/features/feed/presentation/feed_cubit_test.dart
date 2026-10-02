import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_social/core/errors/failures.dart';
import 'package:nexo_social/features/feed/domain/entities/feed_filter.dart';
import 'package:nexo_social/features/feed/domain/entities/post_extras.dart';
import 'package:nexo_social/features/feed/presentation/bloc/feed_cubit.dart';
import 'package:nexo_social/features/moderation/domain/entities/moderation_action.dart';

import '../../../support/fake_post_repository.dart';

void main() {
  late FakePostRepository repository;

  setUp(() {
    repository = FakePostRepository([
      fakePost('1', likes: 482),
      fakePost('2'),
      fakePost('3'),
    ]);
  });

  group('load', () {
    blocTest<FeedCubit, FeedState>(
      'shows the posts the server returns',
      build: () => FeedCubit(repository),
      act: (cubit) => cubit.load(),
      expect: () => [
        const FeedLoading(),
        isA<FeedLoaded>().having((s) => s.posts, 'posts', hasLength(3)),
      ],
    );

    /// Sin red y con el servidor caído son dos promesas distintas: una se
    /// puede esperar, la otra es nuestra.
    blocTest<FeedCubit, FeedState>(
      'a dead network is a failure that says so',
      build: () => FeedCubit(repository),
      setUp: () => repository.failNext = const NetworkFailure('offline'),
      act: (cubit) => cubit.load(),
      expect: () => [const FeedLoading(), const FeedFailure(offline: true)],
    );

    blocTest<FeedCubit, FeedState>(
      'a failed refresh keeps what was on screen',
      build: () => FeedCubit(repository),
      act: (cubit) async {
        await cubit.load();
        repository.failNext = const ServerFailure('500');
        await cubit.refresh();
      },
      verify: (cubit) => expect(cubit.state, isA<FeedLoaded>()),
    );

    blocTest<FeedCubit, FeedState>(
      'pages until there is no cursor, without repeating posts',
      build: () => FeedCubit(repository..pageSize = 2),
      act: (cubit) async {
        await cubit.load();
        await cubit.loadMore();
        await cubit.loadMore();
      },
      verify: (cubit) {
        final state = cubit.state as FeedLoaded;
        expect(state.posts.map((p) => p.id), ['1', '2', '3']);
        expect(state.hasMore, isFalse);
      },
    );

    /// Publicar desde el compositor vuelve al mismo feed (el shell guarda un
    /// Navigator por pestaña): el feed se entera por el repositorio.
    blocTest<FeedCubit, FeedState>(
      'a change in the repository refreshes the feed',
      build: () => FeedCubit(repository),
      act: (cubit) async {
        await cubit.load();
        repository.posts = [fakePost('nuevo'), ...repository.posts];
        repository.emitChange();
        await Future<void>.delayed(Duration.zero);
      },
      verify: (cubit) =>
          expect((cubit.state as FeedLoaded).posts.first.id, 'nuevo'),
    );
  });

  group('filters', () {
    test('forYou shows everything', () {
      final state = FeedLoaded([fakePost('1'), fakePost('2', live: true)]);
      expect(state.visible, hasLength(2));
    });

    test('live shows only broadcasting posts', () {
      final state = FeedLoaded([
        fakePost('1'),
        fakePost('2', live: true),
      ], filter: FeedFilter.live);
      expect(state.visible.single.id, '2');
    });

    test('following shows only followed authors', () {
      final state = FeedLoaded([
        fakePost('1'),
        fakePost('2', followed: true),
      ], filter: FeedFilter.following);
      expect(state.visible.single.id, '2');
    });

    /// An empty filter is a legitimate result, not an error — the screen shows
    /// a way back rather than a retry.
    test('a filter that matches nothing yields an empty list', () {
      final state = FeedLoaded([fakePost('1')], filter: FeedFilter.live);
      expect(state.visible, isEmpty);
    });

    /// Filtering never drops posts from the state, so switching back needs no
    /// refetch.
    test('switching filters does not lose posts', () {
      final state = FeedLoaded([fakePost('1'), fakePost('2', live: true)]);
      final filtered = state.copyWith(filter: FeedFilter.live);
      expect(filtered.visible, hasLength(1));
      expect(
        filtered.copyWith(filter: FeedFilter.forYou).visible,
        hasLength(2),
      );
    });
  });

  group('likes', () {
    blocTest<FeedCubit, FeedState>(
      'liking flips only the targeted post and the server count wins',
      build: () => FeedCubit(repository),
      act: (cubit) async {
        await cubit.load();
        await cubit.toggleLike('1');
      },
      verify: (cubit) {
        final posts = (cubit.state as FeedLoaded).posts;
        expect(posts.first.isLiked, isTrue);
        expect(posts.first.likes, 483);
        expect(posts.skip(1).every((post) => !post.isLiked), isTrue);
      },
    );

    /// Optimista, pero no mentiroso: si el servidor no lo guardó, el corazón
    /// vuelve como estaba y se avisa.
    blocTest<FeedCubit, FeedState>(
      'a like the server rejects is rolled back and reported',
      build: () => FeedCubit(repository),
      act: (cubit) async {
        await cubit.load();
        repository.failNext = const NetworkFailure('offline');
        await cubit.toggleLike('1');
      },
      verify: (cubit) {
        final state = cubit.state as FeedLoaded;
        expect(state.posts.first.isLiked, isFalse);
        expect(state.posts.first.likes, 482);
        expect(state.notice, FeedNotice.likeFailed);
      },
    );
  });

  group('post actions', () {
    blocTest<FeedCubit, FeedState>(
      'deleting removes the post and confirms it',
      build: () => FeedCubit(repository),
      act: (cubit) async {
        await cubit.load();
        await cubit.delete(fakePost('2'));
      },
      verify: (cubit) {
        final state = cubit.state as FeedLoaded;
        expect(state.posts.map((p) => p.id), ['1', '3']);
        expect(state.notice, FeedNotice.deleted);
      },
    );

    blocTest<FeedCubit, FeedState>(
      'a delete the server forbids keeps the post and says why',
      build: () => FeedCubit(repository),
      act: (cubit) async {
        await cubit.load();
        repository.failNext = const ForbiddenFailure('not yours');
        await cubit.delete(fakePost('2'));
      },
      verify: (cubit) {
        final state = cubit.state as FeedLoaded;
        expect(state.posts, hasLength(3));
        expect(state.notice, FeedNotice.forbidden);
      },
    );

    blocTest<FeedCubit, FeedState>(
      'editing replaces the post with what the server returns',
      build: () => FeedCubit(repository),
      act: (cubit) async {
        await cubit.load();
        await cubit.edit(fakePost('1'), 'texto nuevo');
      },
      verify: (cubit) {
        final state = cubit.state as FeedLoaded;
        expect(state.posts.first.body, 'texto nuevo');
        expect(state.notice, FeedNotice.edited);
      },
    );

    blocTest<FeedCubit, FeedState>(
      'reporting sends the typed reason',
      build: () => FeedCubit(repository),
      act: (cubit) async {
        await cubit.load();
        await cubit.report(fakePost('3'), ModerationReason.spam);
      },
      verify: (cubit) {
        expect(repository.reports.single, (
          ReportTarget.post,
          '3',
          ModerationReason.spam,
        ));
        expect((cubit.state as FeedLoaded).notice, FeedNotice.reported);
      },
    );
  });
}
