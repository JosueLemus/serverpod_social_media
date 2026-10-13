import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nexo_social/core/errors/failures.dart';
import 'package:nexo_social/features/feed/data/repositories/mock_home_feed_repository.dart';
import 'package:nexo_social/features/feed/domain/entities/post.dart';
import 'package:nexo_social/features/feed/domain/entities/feed_filter.dart';
import 'package:nexo_social/features/feed/domain/entities/home_feed.dart';
import 'package:nexo_social/features/feed/domain/repositories/home_feed_repository.dart';
import 'package:nexo_social/features/profile/domain/entities/follow.dart';
import 'package:nexo_social/features/profile/domain/repositories/follow_repository.dart';
import 'package:nexo_social/features/feed/domain/entities/post_extras.dart';
import 'package:nexo_social/features/feed/presentation/bloc/feed_cubit.dart';
import 'package:nexo_social/features/moderation/domain/entities/moderation_action.dart';

import '../../../support/fake_post_repository.dart';

class _MockHome extends Mock implements HomeFeedRepository {}

class _MockFollows extends Mock implements FollowRepository {}

const _carlos = ProfileSummary(
  id: 'uuid-carlos',
  username: 'carlos_mendez',
  name: 'Carlos Méndez',
  isVerified: true,
);

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
      build: () => FeedCubit(repository, MockHomeFeedRepository(repository)),
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
      build: () => FeedCubit(repository, MockHomeFeedRepository(repository)),
      setUp: () => repository.failNext = const NetworkFailure('offline'),
      act: (cubit) => cubit.load(),
      expect: () => [const FeedLoading(), const FeedFailure(offline: true)],
    );

    blocTest<FeedCubit, FeedState>(
      'a failed refresh keeps what was on screen',
      build: () => FeedCubit(repository, MockHomeFeedRepository(repository)),
      act: (cubit) async {
        await cubit.load();
        repository.failNext = const ServerFailure('500');
        await cubit.refresh();
      },
      verify: (cubit) => expect(cubit.state, isA<FeedLoaded>()),
    );

    blocTest<FeedCubit, FeedState>(
      'pages until there is no cursor, without repeating posts',
      build: () => FeedCubit(
        repository..pageSize = 2,
        MockHomeFeedRepository(repository),
      ),
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
      build: () => FeedCubit(repository, MockHomeFeedRepository(repository)),
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
      build: () => FeedCubit(repository, MockHomeFeedRepository(repository)),
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
      build: () => FeedCubit(repository, MockHomeFeedRepository(repository)),
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
      build: () => FeedCubit(repository, MockHomeFeedRepository(repository)),
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
      build: () => FeedCubit(repository, MockHomeFeedRepository(repository)),
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
      build: () => FeedCubit(repository, MockHomeFeedRepository(repository)),
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
      build: () => FeedCubit(repository, MockHomeFeedRepository(repository)),
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

  group('a change does not throw away what was paginated', () {
    /// Del más nuevo al más viejo, un minuto entre cada uno, como el feed.
    List<Post> timeline(int count) =>
        [
          for (var i = 0; i < count; i++)
            fakePost('$i').copyWith(body: 'post $i'),
        ].indexed.map((entry) {
          final (index, post) = entry;
          return Post(
            id: post.id,
            author: post.author,
            name: post.name,
            body: post.body,
            tags: post.tags,
            likes: 0,
            comments: 0,
            createdAt: DateTime(
              2026,
              10,
              11,
              12,
            ).subtract(Duration(minutes: index)),
          );
        }).toList();

    /// Regresión: publicar, editar o comentar releía la primera página y la
    /// ponía en lugar de todo, así que quien había bajado volvía arriba y
    /// perdía sus guardados.
    test('the loaded pages and the saved posts survive a refresh', () async {
      repository = FakePostRepository(timeline(25))..pageSize = 10;
      final cubit = FeedCubit(repository, MockHomeFeedRepository(repository));
      await cubit.load();
      await cubit.loadMore();
      cubit.toggleSave('15');

      repository.emitChange();
      await pumpEventQueue();

      final state = cubit.state as FeedLoaded;
      expect(state.posts, hasLength(20));
      expect(state.hasMore, isTrue);
      expect(state.posts.firstWhere((post) => post.id == '15').isSaved, isTrue);
      await cubit.close();
    });

    test('a new post goes on top and nothing is repeated', () {
      final loaded = timeline(20);
      final current = FeedLoaded(loaded, nextCursor: '20');
      final newest = Post(
        id: 'new',
        author: 'a',
        name: 'A',
        body: 'recién publicado',
        tags: const [],
        likes: 0,
        comments: 0,
        createdAt: DateTime(2026, 10, 11, 13),
      );

      final merged = FeedCubit.mergeFirstPage(
        current,
        PostPage([newest, ...loaded.take(9)], nextCursor: '9'),
      );

      expect(merged.posts.first.id, 'new');
      expect(merged.posts, hasLength(21));
      expect(merged.posts.map((post) => post.id).toSet(), hasLength(21));
      expect(merged.nextCursor, '20');
    });

    test('a feed that fits in one page is just that page', () {
      final merged = FeedCubit.mergeFirstPage(
        FeedLoaded(timeline(3)),
        PostPage(timeline(2)),
      );

      expect(merged.posts, hasLength(2));
      expect(merged.nextCursor, isNull);
    });
  });

  group('home by sections', () {
    late _MockHome home;
    late _MockFollows follows;

    late StreamController<void> followChanges;

    setUp(() {
      home = _MockHome();
      follows = _MockFollows();
      followChanges = StreamController<void>.broadcast();
      when(() => follows.changes()).thenAnswer((_) => followChanges.stream);
      when(() => home.home()).thenAnswer(
        (_) async => HomeFeedPage([
          FeedSection(
            kind: FeedSectionKind.following,
            items: [PostFeedItem(fakePost('f1', followed: true))],
          ),
          const FeedSection(
            kind: FeedSectionKind.suggestedAccounts,
            accounts: [_carlos],
          ),
          FeedSection(
            kind: FeedSectionKind.discover,
            items: [PostFeedItem(fakePost('d1'))],
          ),
        ], nextCursor: 'opaque-1'),
      );
    });

    FeedCubit build() => FeedCubit(repository, home, follows);

    test('splits followed posts, suggestions and discover', () async {
      final cubit = build();

      await cubit.load();

      final state = cubit.state as FeedLoaded;
      expect(state.followingPosts.map((p) => p.id), ['f1']);
      expect(state.discoverPosts.map((p) => p.id), ['d1']);
      expect(state.suggestions, [_carlos]);
      // El chip "Siguiendo" es la sección de seguidos.
      expect(
        state.copyWith(filter: FeedFilter.following).visible.map((p) => p.id),
        ['f1'],
      );
      await cubit.close();
    });

    /// El cursor del inicio es opaco: la pantalla lo devuelve tal cual.
    test('pages with the opaque cursor and appends', () async {
      when(() => home.home(cursor: 'opaque-1')).thenAnswer(
        (_) async => HomeFeedPage([
          FeedSection(
            kind: FeedSectionKind.discover,
            items: [PostFeedItem(fakePost('d2'))],
          ),
        ]),
      );
      final cubit = build();
      await cubit.load();

      await cubit.loadMore();

      final state = cubit.state as FeedLoaded;
      expect(state.posts.map((p) => p.id), ['f1', 'd1', 'd2']);
      expect(state.hasMore, isFalse);
      // Las sugerencias son de la primera página y se quedan.
      expect(state.suggestions, [_carlos]);
      await cubit.close();
    });

    test('following a suggestion is optimistic and rolls back', () async {
      when(
        () => follows.follow('uuid-carlos'),
      ).thenThrow(const NetworkFailure('offline'));
      final cubit = build();
      await cubit.load();
      final states = <FeedState>[];
      final sub = cubit.stream.listen(states.add);

      await cubit.toggleFollow(_carlos);

      expect(
        (states.first as FeedLoaded).suggestions.single.viewerFollows,
        isTrue,
      );
      final state = cubit.state as FeedLoaded;
      expect(state.suggestions.single.viewerFollows, isFalse);
      expect(state.notice, FeedNotice.followFailed);
      await sub.cancel();
      await cubit.close();
    });

    test('following a suggestion keeps what the server says', () async {
      when(() => follows.follow('uuid-carlos')).thenAnswer(
        (_) async => const FollowState(
          userId: 'uuid-carlos',
          viewerFollows: true,
          followerCount: 40,
        ),
      );
      final cubit = build();
      await cubit.load();

      await cubit.toggleFollow(_carlos);

      final account = (cubit.state as FeedLoaded).suggestions.single;
      expect(account.viewerFollows, isTrue);
      expect(account.followerCount, 40);
      await cubit.close();
    });

    // Regresión: seguir desde un perfil o Explorar no movía nada en el feed
    // hasta reiniciar: los posts de esa cuenta seguían en "descubrir".
    test('following elsewhere reloads the home', () async {
      final cubit = build();
      await cubit.load();
      when(() => home.home()).thenAnswer(
        (_) async => HomeFeedPage([
          FeedSection(
            kind: FeedSectionKind.following,
            items: [
              PostFeedItem(fakePost('f1', followed: true)),
              PostFeedItem(fakePost('d1', followed: true)),
            ],
          ),
        ]),
      );

      followChanges.add(null);
      await pumpEventQueue();

      final state = cubit.state as FeedLoaded;
      expect(state.followingPosts.map((p) => p.id), ['f1', 'd1']);
      expect(state.discoverPosts, isEmpty);
      await cubit.close();
    });

    test('closing stops listening to follows', () async {
      final cubit = build();
      await cubit.load();
      await cubit.close();

      expect(followChanges.hasListener, isFalse);
    });

    // El servidor deja de sugerir a quien ya se sigue: sin esto, la fila
    // desaparecía debajo del dedo apenas se tocaba "Seguir".
    test('the account just followed stays in the suggestions', () {
      const followed = ProfileSummary(
        id: 'uuid-carlos',
        username: 'carlos_mendez',
        name: 'Carlos Méndez',
        viewerFollows: true,
      );
      const other = ProfileSummary(id: 'u2', username: 'u2', name: 'U2');
      const gone = ProfileSummary(id: 'u3', username: 'u3', name: 'U3');

      expect(FeedCubit.mergeSuggestions([followed, gone], [other]), [
        followed,
        other,
      ]);
    });
  });

  group('likes elsewhere', () {
    /// Un like desde la publicación avisa por el repositorio, y el feed que
    /// quedó debajo lo refleja sin perder lo paginado.
    test('a like from the post detail shows up in the feed', () async {
      repository = FakePostRepository([
        fakePost('1', likes: 2),
        fakePost('2'),
        fakePost('3'),
      ])..pageSize = 2;
      final cubit = FeedCubit(repository, MockHomeFeedRepository(repository));
      await cubit.load();
      await cubit.loadMore();

      await repository.setLiked('1', liked: true);
      await pumpEventQueue();

      final state = cubit.state as FeedLoaded;
      expect(state.posts.first.isLiked, isTrue);
      expect(state.posts.first.likes, 3);
      expect(state.posts, hasLength(3));
      await cubit.close();
    });

    /// Con un like en vuelo, la relectura espera: si no, traía el dato de
    /// antes del toque y el corazón parpadeaba.
    test('a change while a like is in flight waits for it', () async {
      final cubit = FeedCubit(repository, MockHomeFeedRepository(repository));
      await cubit.load();
      final hearts = <bool>[];
      final sub = cubit.stream.listen((state) {
        if (state is FeedLoaded) hearts.add(state.posts.first.isLiked);
      });

      final like = cubit.toggleLike('1');
      repository.emitChange();
      await like;
      await pumpEventQueue();

      expect(hearts, isNot(contains(false)));
      expect((cubit.state as FeedLoaded).posts.first.isLiked, isTrue);
      await sub.cancel();
      await cubit.close();
    });

    test('editing keeps what is only local', () async {
      repository = FakePostRepository([
        fakePost('1', canEdit: true, followed: true),
      ]);
      final cubit = FeedCubit(repository, MockHomeFeedRepository(repository));
      await cubit.load();
      cubit.toggleSave('1');

      await cubit.edit(fakePost('1'), 'texto nuevo');

      final post = (cubit.state as FeedLoaded).posts.single;
      expect(post.body, 'texto nuevo');
      expect(post.isSaved, isTrue);
      expect(post.isFollowed, isTrue);
      await cubit.close();
    });
  });
}
