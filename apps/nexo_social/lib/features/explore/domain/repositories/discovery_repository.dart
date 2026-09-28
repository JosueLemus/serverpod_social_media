import '../entities/discovery.dart';

abstract interface class DiscoveryRepository {
  Future<List<TrendingTopic>> trending();
  Future<List<SuggestedCreator>> suggestedCreators();

  /// Idempotente, como manda el contrato del Notion para el grafo social:
  /// seguir dos veces es seguir una.
  Future<void> setFollowingTopic(String tag, {required bool following});
  Future<void> setFollowingCreator(String username, {required bool following});
}
