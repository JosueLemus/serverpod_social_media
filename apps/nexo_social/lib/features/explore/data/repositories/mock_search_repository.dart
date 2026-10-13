import '../../../../core/mock/demo_accounts.dart';
import '../../../feed/domain/repositories/post_repository.dart';
import '../../../live/domain/repositories/live_repository.dart';
import '../../../profile/domain/entities/follow.dart';
import '../../domain/entities/search_results.dart';
import '../../domain/repositories/search_repository.dart';

/// El buscador sobre los datos del mock: las cuentas de demo, el feed y los
/// vivos que ya conoce la app. Mismas reglas de texto que el servidor.
class MockSearchRepository implements SearchRepository {
  MockSearchRepository(this._posts, this._lives);

  final PostRepository _posts;
  final LiveRepository _lives;

  static String normalize(String text) {
    var value = text.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
    while (value.startsWith('@') || value.startsWith('#')) {
      value = value.substring(1).trimLeft();
    }
    return value;
  }

  @override
  Future<SearchResults> search(String text) async {
    final query = normalize(text);
    if (query.length < 2) return SearchResults(query: query);
    bool has(String? value) => value?.toLowerCase().contains(query) ?? false;

    final posts = (await _posts.feed()).posts;
    final lives = await _lives.list();
    final tags = <String, int>{};
    for (final post in posts) {
      for (final tag in post.tags) {
        final key = tag.toLowerCase();
        if (has(key)) {
          tags[key] = (tags[key] ?? 0) + 1;
        }
      }
    }
    return SearchResults(
      query: query,
      accounts: [
        for (final account in DemoAccounts.all)
          if (has(account.username) || has(account.name))
            ProfileSummary(
              id: account.id,
              username: account.username,
              name: account.name,
            ),
      ],
      posts: [
        for (final post in posts)
          if (has(post.body) || post.tags.any(has)) post,
      ],
      lives: [
        for (final live in lives)
          if (has(live.title)) live,
      ],
      tags: (tags.entries.toList()..sort((a, b) => b.value.compareTo(a.value)))
          .map((entry) => entry.key)
          .toList(),
    );
  }
}
