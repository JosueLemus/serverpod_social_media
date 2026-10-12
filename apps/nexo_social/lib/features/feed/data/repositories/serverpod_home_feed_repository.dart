import 'dart:convert';

import 'package:nexo_client/nexo_client.dart' as api;

import '../../../../core/errors/failures.dart';
import '../../../../core/network/serverpod_failures.dart';
import '../../../live/data/repositories/serverpod_live_repository.dart';
import '../../../profile/data/repositories/serverpod_follow_repository.dart';
import '../../domain/entities/home_feed.dart';
import '../../domain/repositories/home_feed_repository.dart';
import 'serverpod_post_repository.dart';

/// El inicio sobre `client.feed.home`. El servidor arma las secciones; acá
/// sólo se traducen.
class ServerpodHomeFeedRepository implements HomeFeedRepository {
  ServerpodHomeFeedRepository(this._client);

  final api.Client _client;

  @override
  Future<HomeFeedPage> home({String? cursor}) => _guard(() async {
    final page = await _client.feed.home(cursor: decodeCursor(cursor));
    return HomeFeedPage([
      for (final section in page.sections) toSection(section),
    ], nextCursor: encodeCursor(page.nextCursor));
  });

  /// Público para los tests.
  static FeedSection toSection(api.FeedSection section) {
    final kind = FeedSectionKind.values.byName(section.kind.name);
    return FeedSection(
      kind: kind,
      items: [
        for (final item in section.items)
          ?_toItem(item, following: kind == FeedSectionKind.following),
      ],
      accounts: [
        for (final view in section.accounts)
          ServerpodFollowRepository.toSummary(view),
      ],
    );
  }

  /// Un ítem sin su carga (un kind nuevo que esta versión no conoce, o un
  /// post que el servidor no mandó) se descarta en vez de romper la página.
  static FeedItem? _toItem(api.FeedItem item, {required bool following}) {
    if (item.post case final post?) {
      // Los de la sección "following" son, por definición, de cuentas que
      // seguís: es lo que filtra el chip "Siguiendo".
      return PostFeedItem(
        ServerpodPostRepository.toPost(post).copyWith(isFollowed: following),
      );
    }
    if (item.liveShow case final show?) {
      return LiveFeedItem(ServerpodLiveRepository.toSession(show));
    }
    return null;
  }

  /// El cursor del servidor tiene dos posiciones (seguidos y descubrir). Para
  /// la app es un texto opaco que se devuelve tal cual.
  static String? encodeCursor(api.HomeFeedCursor? cursor) =>
      cursor == null ? null : jsonEncode(cursor.toJson());

  static api.HomeFeedCursor? decodeCursor(String? cursor) {
    if (cursor == null) return null;
    try {
      return api.HomeFeedCursor.fromJson(
        jsonDecode(cursor) as Map<String, dynamic>,
      );
    } on Object {
      // Un cursor que no se entiende es la primera página, no un error.
      return null;
    }
  }

  static Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on Failure {
      rethrow;
    } catch (error) {
      throw failureFromServer(error);
    }
  }
}
