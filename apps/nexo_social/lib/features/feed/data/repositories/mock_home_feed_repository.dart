import '../../../../core/errors/failures.dart';
import '../../../live/domain/entities/live_session.dart';
import '../../../live/domain/repositories/live_repository.dart';
import '../../../profile/domain/repositories/follow_repository.dart';
import '../../domain/entities/home_feed.dart';
import '../../domain/entities/post.dart';
import '../../domain/repositories/home_feed_repository.dart';
import '../../domain/repositories/post_repository.dart';

/// El inicio por secciones en el modo mock y en los tests, armado con lo que
/// ya dan los repositorios: los posts que dicen que seguís a su autor van a
/// "seguidos", el resto a "descubrir".
///
/// [lives] y [follows] son opcionales: sin ellos no hay fila de vivos ni de
/// sugeridos, y el feed sigue siendo el de siempre.
class MockHomeFeedRepository implements HomeFeedRepository {
  MockHomeFeedRepository(this._posts, {this.lives, this.follows});

  final PostRepository _posts;
  final LiveRepository? lives;
  final FollowRepository? follows;

  @override
  Future<HomeFeedPage> home({String? cursor}) async {
    final page = await _posts.feed(cursor: cursor);
    final first = cursor == null;
    final onAir = first ? await _onAir() : const <LiveSession>[];
    final suggested = first ? await _suggestions() : const <FeedSection>[];
    return HomeFeedPage([
      if (onAir.isNotEmpty)
        FeedSection(
          kind: FeedSectionKind.liveNow,
          items: [for (final session in onAir) LiveFeedItem(session)],
        ),
      ..._postSection(
        FeedSectionKind.following,
        page.posts.where((post) => post.isFollowed),
      ),
      ...suggested,
      ..._postSection(
        FeedSectionKind.discover,
        page.posts.where((post) => !post.isFollowed),
      ),
    ], nextCursor: page.nextCursor);
  }

  static List<FeedSection> _postSection(
    FeedSectionKind kind,
    Iterable<Post> posts,
  ) {
    final items = [for (final post in posts) PostFeedItem(post)];
    return items.isEmpty ? const [] : [FeedSection(kind: kind, items: items)];
  }

  Future<List<LiveSession>> _onAir() async {
    final source = lives;
    if (source == null) return const [];
    try {
      return [
        for (final session in await source.list())
          if (session.status == LiveStatus.live) session,
      ];
    } on Failure {
      return const [];
    }
  }

  Future<List<FeedSection>> _suggestions() async {
    final source = follows;
    if (source == null) return const [];
    try {
      final accounts = await source.suggestions();
      return accounts.isEmpty
          ? const []
          : [
              FeedSection(
                kind: FeedSectionKind.suggestedAccounts,
                accounts: accounts,
              ),
            ];
    } on Failure {
      // Sin sugerencias el inicio se sigue viendo.
      return const [];
    }
  }
}
