import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/feed/domain/entities/post.dart';
import '../utils/mock_content.dart';

class MockSocialStore {
  MockSocialStore(this._preferences);
  final SharedPreferences _preferences;
  static const _postsKey = 'mock_posts';
  static const _followingKey = 'mock_following';

  List<Post> readPosts() {
    final raw = _preferences.getString(_postsKey);
    if (raw == null) return List.of(MockContent.posts);
    return (jsonDecode(raw) as List<dynamic>)
        .map((item) => Post.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> savePosts(List<Post> posts) => _preferences.setString(
    _postsKey,
    jsonEncode(posts.map((post) => post.toJson()).toList()),
  );
  bool isFollowing(String username) =>
      _preferences.getStringList(_followingKey)?.contains(username) ?? false;
  Future<void> toggleFollowing(String username) async {
    final values =
        _preferences.getStringList(_followingKey)?.toSet() ?? <String>{};
    values.contains(username) ? values.remove(username) : values.add(username);
    await _preferences.setStringList(_followingKey, values.toList());
  }
}
