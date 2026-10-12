import 'package:serverpod/serverpod.dart';

import '../../../generated/protocol.dart';
import '../services/follow_service.dart';

/// Seguir cuentas. Desde Flutter: `client.follows`.
///
/// Seguir y dejar de seguir exigen sesión y son idempotentes. Las listas y
/// las sugerencias son públicas.
class FollowsEndpoint extends Endpoint {
  static const _follows = FollowService();

  /// Sigue a [userId]. No se puede seguir a uno mismo; la cuenta tiene que
  /// estar activa.
  Future<FollowState> follow(Session session, UuidValue userId) =>
      _follows.follow(session, userId);

  /// Deja de seguir a [userId]. Sin efecto si no lo seguía.
  Future<FollowState> unfollow(Session session, UuidValue userId) =>
      _follows.unfollow(session, userId);

  /// Quién sigue a [userId], del más reciente al más viejo.
  Future<FollowPage> followers(
    Session session,
    UuidValue userId, {
    PageCursor? after,
    int? limit,
  }) => _follows.followers(session, userId, after: after, limit: limit);

  /// A quién sigue [userId], del más reciente al más viejo.
  Future<FollowPage> following(
    Session session,
    UuidValue userId, {
    PageCursor? after,
    int? limit,
  }) => _follows.following(session, userId, after: after, limit: limit);

  /// Creadores verificados que la sesión todavía no sigue, por seguidores
  /// (hasta 20; 10 por defecto). Sin sesión, los más seguidos.
  Future<List<ProfileView>> suggestions(Session session, {int? limit}) =>
      _follows.suggestions(session, limit: limit);
}
