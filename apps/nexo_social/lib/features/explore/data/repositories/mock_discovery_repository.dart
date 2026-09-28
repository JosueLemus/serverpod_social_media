import '../../domain/entities/discovery.dart';
import '../../domain/repositories/discovery_repository.dart';

class MockDiscoveryRepository implements DiscoveryRepository {
  final _topics = <TrendingTopic>[
    const TrendingTopic(tag: 'UIUX', posts: 1240),
    const TrendingTopic(tag: 'FlutterDev', posts: 980),
    const TrendingTopic(tag: 'ProductDesign', posts: 744),
    const TrendingTopic(tag: 'DesignSystems', posts: 612),
    const TrendingTopic(tag: 'Creadores', posts: 430),
  ];

  final _creators = <SuggestedCreator>[
    const SuggestedCreator(
      username: 'elena_ux',
      name: 'Elena Vega',
      headline: 'Diseñadora de Producto & Mentora de Creadores',
      isVerified: true,
      isLive: true,
    ),
    const SuggestedCreator(
      username: 'carlos_dev',
      name: 'Carlos Méndez',
      headline: 'Ingeniero de Software & Flutter',
      isPro: true,
    ),
    const SuggestedCreator(
      username: 'lucia_design',
      name: 'Lucía Torres',
      headline: 'Directora Creativa & Motion',
      isVerified: true,
    ),
  ];

  @override
  Future<List<TrendingTopic>> trending() async => List.of(_topics);

  @override
  Future<List<SuggestedCreator>> suggestedCreators() async =>
      List.of(_creators);

  @override
  Future<void> setFollowingTopic(String tag, {required bool following}) async {
    final index = _topics.indexWhere((topic) => topic.tag == tag);
    if (index == -1) return;
    _topics[index] = _topics[index].copyWith(isFollowed: following);
  }

  @override
  Future<void> setFollowingCreator(
    String username, {
    required bool following,
  }) async {
    final index = _creators.indexWhere(
      (creator) => creator.username == username,
    );
    if (index == -1) return;
    _creators[index] = _creators[index].copyWith(isFollowed: following);
  }
}
