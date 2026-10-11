import 'package:nexo_client/nexo_client.dart' as api;

import '../../../../core/errors/failures.dart';
import '../../../../core/network/serverpod_failures.dart';
import '../../../profile/domain/entities/follow.dart';
import '../../../profile/domain/repositories/follow_repository.dart';
import '../../domain/entities/discovery.dart';
import '../../domain/repositories/discovery_repository.dart';

/// Explorar con datos reales: los creadores sugeridos salen de
/// `follows.suggestions` y seguir pasa por el servidor.
///
/// Las tendencias no tienen endpoint todavía. En vez de los números fijos del
/// mock, se cuentan las etiquetas de las publicaciones recientes: un número
/// chico pero cierto.
class ServerpodDiscoveryRepository implements DiscoveryRepository {
  ServerpodDiscoveryRepository(this._client, this._follows);

  final api.Client _client;
  final FollowRepository _follows;

  /// Username → id, de la última lista de sugeridos. Seguir pide el id.
  final _ids = <String, String>{};

  /// Seguir un tema todavía no tiene backend: queda en la sesión.
  final _followedTopics = <String>{};

  static const _topicCount = 5;

  @override
  Future<List<TrendingTopic>> trending() async {
    final api.PostPage page;
    try {
      page = await _client.posts.feed();
    } catch (error) {
      throw failureFromServer(error);
    }
    final counts = <String, int>{};
    for (final post in page.items) {
      for (final tag in post.tags.toSet()) {
        counts[tag] = (counts[tag] ?? 0) + 1;
      }
    }
    final ranked = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return [
      for (final entry in ranked.take(_topicCount))
        TrendingTopic(
          tag: entry.key,
          posts: entry.value,
          isFollowed: _followedTopics.contains(entry.key),
        ),
    ];
  }

  @override
  Future<List<SuggestedCreator>> suggestedCreators() async => [
    for (final account in await _follows.suggestions()) _toCreator(account),
  ];

  @override
  Future<void> setFollowingTopic(String tag, {required bool following}) async {
    if (following) {
      _followedTopics.add(tag);
    } else {
      _followedTopics.remove(tag);
    }
  }

  @override
  Future<void> setFollowingCreator(
    String username, {
    required bool following,
  }) async {
    final userId = _ids[username] ?? await _idOf(username);
    if (following) {
      await _follows.follow(userId);
    } else {
      await _follows.unfollow(userId);
    }
  }

  Future<String> _idOf(String username) async {
    try {
      final view = await _client.profiles.byUsername(username);
      return _ids[username] = view.userId.toString();
    } on Failure {
      rethrow;
    } catch (error) {
      throw failureFromServer(error);
    }
  }

  SuggestedCreator _toCreator(ProfileSummary account) {
    _ids[account.username] = account.id;
    return SuggestedCreator(
      userId: account.id,
      username: account.username,
      name: account.name,
      // Una línea sobre qué hace. Sin bio, se dice lo que se sabe.
      headline:
          account.bio ??
          (account.isVerified ? 'Creador verificado' : 'Creador en Nexo'),
      isVerified: account.isVerified,
      isFollowed: account.viewerFollows,
      avatarUrl: account.avatarUrl,
    );
  }
}
