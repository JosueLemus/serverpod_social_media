import 'package:serverpod/serverpod.dart';

import '../../../generated/protocol.dart';
import '../../../shared/auth/auth_context.dart';
import '../../content/services/post_service.dart';
import '../../live/services/live_service.dart';
import '../../social/services/follow_service.dart';

/// El feed de inicio, armado en el servidor por secciones (D6 del SDD 0004,
/// S6 del 0008): vivos ahora → de quienes seguís → cuentas sugeridas →
/// descubrir.
///
/// No tiene reglas propias de visibilidad: cada sección le pide sus datos al
/// módulo que las tiene, así "quién ve qué" sigue siendo una sola regla.
class HomeFeedService {
  HomeFeedService({
    this._posts = const PostService(),
    this._follows = const FollowService(),
    LiveService? live,
  }) : _live = live ?? LiveService();

  static const suggestedAccounts = 10;
  static const liveNowLimit = 10;

  final PostService _posts;
  final FollowService _follows;
  final LiveService _live;

  Future<HomeFeedPage> home(Session session, {HomeFeedCursor? cursor}) async {
    final viewer = session.userIdOrNull;
    final followees = viewer == null
        ? const <UuidValue>{}
        : await _follows.followeesOf(session, viewer);

    if (cursor == null) return _firstPage(session, viewer, followees);

    if (!cursor.followingDone) {
      final page = await _posts.byAuthors(
        session,
        followees,
        after: cursor.followingAfter,
      );
      return HomeFeedPage(
        sections: [
          if (page.items.isNotEmpty)
            _postSection(FeedSectionKind.following, page.items),
        ],
        nextCursor: _cursor(
          followingAfter: page.nextCursor,
          discoverAfter: cursor.discoverAfter,
          discoverDone: cursor.discoverDone,
        ),
      );
    }

    if (!cursor.discoverDone) {
      final page = await _discover(
        session,
        viewer,
        followees,
        after: cursor.discoverAfter,
      );
      return HomeFeedPage(
        sections: [
          if (page.items.isNotEmpty)
            _postSection(FeedSectionKind.discover, page.items),
        ],
        nextCursor: _cursor(
          followingAfter: null,
          discoverAfter: page.nextCursor,
        ),
      );
    }

    return HomeFeedPage(sections: const []);
  }

  Future<HomeFeedPage> _firstPage(
    Session session,
    UuidValue? viewer,
    Set<UuidValue> followees,
  ) async {
    final live = await _live.onAir(
      session,
      prioritize: followees,
      limit: liveNowLimit,
    );
    final following = await _posts.byAuthors(session, followees);
    final suggested = await _follows.suggestions(
      session,
      limit: suggestedAccounts,
    );
    final discover = await _discover(session, viewer, followees);

    return HomeFeedPage(
      sections: [
        if (live.isNotEmpty)
          FeedSection(
            kind: FeedSectionKind.liveNow,
            items: [for (final show in live) _showItem(show)],
            accounts: const [],
          ),
        if (following.items.isNotEmpty)
          _postSection(FeedSectionKind.following, following.items),
        if (suggested.isNotEmpty)
          FeedSection(
            kind: FeedSectionKind.suggestedAccounts,
            items: const [],
            accounts: suggested,
          ),
        if (discover.items.isNotEmpty)
          _postSection(FeedSectionKind.discover, discover.items),
      ],
      nextCursor: _cursor(
        followingAfter: following.nextCursor,
        discoverAfter: discover.nextCursor,
      ),
    );
  }

  Future<PostPage> _discover(
    Session session,
    UuidValue? viewer,
    Set<UuidValue> followees, {
    PageCursor? after,
  }) async => _posts.discover(
    session,
    excludeAuthors: {...followees, ?viewer},
    preferredTags: viewer == null
        ? const {}
        : await _posts.likedTags(session, viewer),
    after: after,
  );

  /// `null` cuando las dos secciones paginadas se agotaron. Se agota primero
  /// `following` y después `discover`.
  static HomeFeedCursor? _cursor({
    required PageCursor? followingAfter,
    required PageCursor? discoverAfter,
    bool discoverDone = false,
  }) {
    final followingDone = followingAfter == null;
    final discoverFinished = discoverDone || discoverAfter == null;
    if (followingDone && discoverFinished) return null;
    return HomeFeedCursor(
      followingAfter: followingAfter,
      followingDone: followingDone,
      discoverAfter: discoverAfter,
      discoverDone: discoverFinished,
    );
  }

  static FeedSection _postSection(
    FeedSectionKind kind,
    List<PostView> posts,
  ) => FeedSection(
    kind: kind,
    items: [for (final post in posts) postItem(post)],
    accounts: const [],
  );

  /// Un post sin adjuntos es `textPost`; con adjuntos, lo decide el primero.
  static FeedItem postItem(PostView post) => FeedItem(
    kind: switch (post.media.firstOrNull?.kind) {
      null => FeedItemKind.textPost,
      PostMediaKind.image => FeedItemKind.imagePost,
      PostMediaKind.video => FeedItemKind.videoPost,
    },
    post: post,
  );

  static FeedItem _showItem(LiveShowView show) => FeedItem(
    kind: switch (show.status) {
      LiveShowStatus.live || LiveShowStatus.ending => FeedItemKind.liveShow,
      LiveShowStatus.recorded ||
      LiveShowStatus.published => FeedItemKind.recordedShow,
      _ => FeedItemKind.scheduledShow,
    },
    liveShow: show,
  );
}
