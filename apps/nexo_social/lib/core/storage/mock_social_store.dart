import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../features/feed/domain/entities/post.dart';
import '../utils/mock_content.dart';

/// Stands in for the content repository until Serverpod exists.
///
/// It is **observable**, and that is not incidental. The shell keeps one
/// navigator per tab, so the feed is not rebuilt when the user comes back from
/// composing a post — it is the same widget with the same cubit and the same
/// in-memory list. Before this stream, publishing wrote to disk and the feed
/// kept showing the old list until the app was restarted. The old shell hid
/// the problem by rebuilding everything on every tab change.
///
/// A real backend has the same shape: a new post arrives through the feed's
/// own channel, not because a screen happened to remount.
class MockSocialStore {
  MockSocialStore(this._preferences);

  final SharedPreferences _preferences;

  static const _postsKey = 'mock_posts';
  static const _followingKey = 'mock_following';

  final _posts = StreamController<List<Post>>.broadcast();

  /// Emits the full list every time it changes. Broadcast because the feed and
  /// a profile can both be listening.
  Stream<List<Post>> watchPosts() => _posts.stream;

  List<Post> readPosts() {
    final raw = _preferences.getString(_postsKey);
    if (raw == null) return MockContent.seed();
    return (jsonDecode(raw) as List<dynamic>)
        .map((item) => Post.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> savePosts(List<Post> posts) async {
    await _preferences.setString(
      _postsKey,
      jsonEncode(posts.map((post) => post.toJson()).toList()),
    );
    // After the write, so a listener that re-reads storage sees what was just
    // saved rather than the previous value.
    if (!_posts.isClosed) _posts.add(List.unmodifiable(posts));
  }

  bool isFollowing(String username) =>
      _preferences.getStringList(_followingKey)?.contains(username) ?? false;

  Future<void> toggleFollowing(String username) async {
    final values =
        _preferences.getStringList(_followingKey)?.toSet() ?? <String>{};
    if (values.contains(username)) {
      values.remove(username);
    } else {
      values.add(username);
    }
    await _preferences.setStringList(_followingKey, values.toList());
  }

  Future<void> dispose() => _posts.close();
}
