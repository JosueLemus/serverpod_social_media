import 'package:nexo_client/nexo_client.dart' as api;

import '../../../../core/network/serverpod_failures.dart';
import '../../../feed/data/repositories/serverpod_post_repository.dart';
import '../../../live/data/repositories/serverpod_live_repository.dart';
import '../../../profile/data/repositories/serverpod_follow_repository.dart';
import '../../domain/entities/search_results.dart';
import '../../domain/repositories/search_repository.dart';

/// `client.search.query`, con los mismos mapeos que el resto de la app: una
/// cuenta, un post o un vivo encontrados son los mismos que en el feed.
class ServerpodSearchRepository implements SearchRepository {
  ServerpodSearchRepository(this._client);

  final api.Client _client;

  @override
  Future<SearchResults> search(String text) async {
    try {
      return toResults(await _client.search.query(text));
    } catch (error) {
      throw failureFromServer(error);
    }
  }

  static SearchResults toResults(api.SearchResults results) => SearchResults(
    query: results.query,
    accounts: [
      for (final account in results.accounts)
        ServerpodFollowRepository.toSummary(account),
    ],
    posts: [
      for (final post in results.posts) ServerpodPostRepository.toPost(post),
    ],
    lives: [
      for (final live in results.lives) ServerpodLiveRepository.toSession(live),
    ],
    tags: results.tags,
  );
}
