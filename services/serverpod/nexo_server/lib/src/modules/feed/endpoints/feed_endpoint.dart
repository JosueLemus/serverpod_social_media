import 'package:serverpod/serverpod.dart';

import '../../../generated/protocol.dart';
import '../services/home_feed_service.dart';

/// El feed de inicio por secciones. Desde Flutter: `client.feed`.
class FeedEndpoint extends Endpoint {
  static final _feed = HomeFeedService();

  /// La primera página (sin [cursor]) trae las secciones con contenido:
  /// `liveNow`, `following`, `suggestedAccounts` y `discover`. Las
  /// siguientes, `following` hasta agotarse y después `discover`. Sin
  /// sesión, `following` no viene.
  Future<HomeFeedPage> home(Session session, {HomeFeedCursor? cursor}) =>
      _feed.home(session, cursor: cursor);
}
