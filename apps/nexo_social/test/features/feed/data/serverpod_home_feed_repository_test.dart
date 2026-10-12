import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_client/nexo_client.dart' as api;
import 'package:nexo_social/features/feed/data/repositories/serverpod_home_feed_repository.dart';
import 'package:nexo_social/features/feed/domain/entities/home_feed.dart';
import 'package:nexo_social/features/live/domain/entities/live_session.dart';
import 'package:nexo_social/features/profile/data/repositories/serverpod_follow_repository.dart';

void main() {
  final elena = api.UuidValue.fromString(
    '550e8400-e29b-41d4-a716-446655440000',
  );

  api.PostView post(int id) => api.PostView(
    id: id,
    authorId: elena,
    authorUsername: 'elena_ux',
    authorName: 'Elena Vega',
    body: 'Hola $id',
    tags: const ['uiux'],
    visibility: api.PostVisibility.public,
    allowComments: true,
    likeCount: 0,
    isLiked: false,
    commentCount: 0,
    media: const [],
    createdAt: DateTime.utc(2026, 10, 1, 12),
    canEdit: false,
    canDelete: false,
  );

  api.LiveShowView show() => api.LiveShowView(
    id: 5,
    hostId: elena,
    hostUsername: 'elena_ux',
    hostName: 'Elena Vega',
    title: 'Masterclass',
    description: '',
    startsAt: DateTime.utc(2026, 10, 11, 20),
    durationMinutes: 60,
    access: api.LiveShowAccess.public,
    allowQuestions: true,
    recordReplay: true,
    status: api.LiveShowStatus.live,
    endedByModeration: false,
    viewerCount: 4,
    guestIds: const [],
  );

  api.ProfileView carlos({bool viewerFollows = false}) => api.ProfileView(
    userId: api.UuidValue.fromString('6ba7b810-9dad-11d1-80b4-00c04fd430c8'),
    username: 'carlos_mendez',
    displayName: 'Carlos Méndez',
    isCreator: true,
    verification: api.VerificationStatus.verified,
    status: api.AccountStatus.active,
    followerCount: 31,
    viewerFollows: viewerFollows,
    createdAt: DateTime.utc(2026, 9, 1),
  );

  /// Lo que filtra el chip "Siguiendo": un post de la sección de seguidos
  /// lleva la marca, uno de "descubrir" no.
  test('posts of the following section are marked as followed', () {
    final following = ServerpodHomeFeedRepository.toSection(
      api.FeedSection(
        kind: api.FeedSectionKind.following,
        items: [api.FeedItem(kind: api.FeedItemKind.textPost, post: post(1))],
        accounts: const [],
      ),
    );
    final discover = ServerpodHomeFeedRepository.toSection(
      api.FeedSection(
        kind: api.FeedSectionKind.discover,
        items: [api.FeedItem(kind: api.FeedItemKind.textPost, post: post(2))],
        accounts: const [],
      ),
    );

    expect(following.kind, FeedSectionKind.following);
    expect(following.posts.single.isFollowed, isTrue);
    expect(discover.posts.single.isFollowed, isFalse);
  });

  test('lives and suggested accounts map to their own items', () {
    final live = ServerpodHomeFeedRepository.toSection(
      api.FeedSection(
        kind: api.FeedSectionKind.liveNow,
        items: [
          api.FeedItem(kind: api.FeedItemKind.liveShow, liveShow: show()),
        ],
        accounts: const [],
      ),
    );
    final suggested = ServerpodHomeFeedRepository.toSection(
      api.FeedSection(
        kind: api.FeedSectionKind.suggestedAccounts,
        items: const [],
        accounts: [carlos()],
      ),
    );

    expect(live.lives.single.status, LiveStatus.live);
    expect(live.lives.single.hostUsername, 'elena_ux');
    expect(suggested.accounts.single.username, 'carlos_mendez');
    expect(suggested.accounts.single.isVerified, isTrue);
  });

  /// Un ítem sin carga (un kind que esta versión no conoce) no rompe la
  /// página: se descarta.
  test('an item without payload is dropped', () {
    final section = ServerpodHomeFeedRepository.toSection(
      api.FeedSection(
        kind: api.FeedSectionKind.discover,
        items: [api.FeedItem(kind: api.FeedItemKind.imagePost)],
        accounts: const [],
      ),
    );

    expect(section.items, isEmpty);
  });

  test('the two-position cursor survives the round trip as opaque text', () {
    final cursor = api.HomeFeedCursor(
      followingAfter: api.PageCursor(
        createdAt: DateTime.utc(2026, 10, 1),
        id: 9,
      ),
      followingDone: false,
      discoverDone: true,
    );

    final text = ServerpodHomeFeedRepository.encodeCursor(cursor);
    final back = ServerpodHomeFeedRepository.decodeCursor(text);

    expect(back?.followingAfter?.id, 9);
    expect(back?.followingDone, isFalse);
    expect(back?.discoverDone, isTrue);
    expect(ServerpodHomeFeedRepository.decodeCursor('basura'), isNull);
  });

  test('a suggested account keeps the follow state the server computed', () {
    final summary = ServerpodFollowRepository.toSummary(
      carlos(viewerFollows: true),
    );

    expect(summary.id, '6ba7b810-9dad-11d1-80b4-00c04fd430c8');
    expect(summary.viewerFollows, isTrue);
    expect(summary.followerCount, 31);
  });
}
