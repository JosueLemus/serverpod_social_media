import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_client/nexo_client.dart' as api;
import 'package:nexo_social/features/explore/data/repositories/serverpod_search_repository.dart';
import 'package:nexo_social/features/live/domain/entities/live_session.dart';

void main() {
  final elena = api.UuidValue.fromString(
    '550e8400-e29b-41d4-a716-446655440000',
  );

  test('maps every section with the same mappers as the rest of the app', () {
    final results = ServerpodSearchRepository.toResults(
      api.SearchResults(
        query: 'ele',
        accounts: [
          api.ProfileView(
            userId: elena,
            username: 'elena_ux',
            displayName: 'Elena Vega',
            isCreator: true,
            verification: api.VerificationStatus.verified,
            status: api.AccountStatus.active,
            followerCount: 3,
            viewerFollows: true,
            createdAt: DateTime.utc(2026, 9, 1),
          ),
        ],
        posts: [
          api.PostView(
            id: 7,
            authorId: elena,
            authorUsername: 'elena_ux',
            authorName: 'Elena Vega',
            body: 'Hola',
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
          ),
        ],
        lives: [
          api.LiveShowView(
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
          ),
        ],
        tags: const ['uiux'],
      ),
    );

    expect(results.query, 'ele');
    expect(results.accounts.single.username, 'elena_ux');
    expect(results.accounts.single.viewerFollows, isTrue);
    expect(results.accounts.single.followerCount, 3);
    expect(results.posts.single.id, '7');
    expect(results.posts.single.author, 'elena_ux');
    expect(results.lives.single.id, '5');
    expect(results.lives.single.status, LiveStatus.live);
    expect(results.tags, ['uiux']);
  });
}
