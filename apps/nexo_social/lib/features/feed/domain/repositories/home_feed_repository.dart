import '../entities/home_feed.dart';

/// El inicio por secciones: vivos ahora, de quienes seguís, a quién seguir y
/// para descubrir. Pasar el `nextCursor` de la página anterior para seguir.
abstract interface class HomeFeedRepository {
  Future<HomeFeedPage> home({String? cursor});
}
