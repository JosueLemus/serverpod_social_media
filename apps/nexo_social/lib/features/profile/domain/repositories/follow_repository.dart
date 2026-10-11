import '../entities/follow.dart';

/// Seguir y dejar de seguir, y las listas que salen del grafo.
///
/// `follow` y `unfollow` son idempotentes: dos toques seguidos no suman dos.
/// Los errores salen como `Failure`: `ForbiddenFailure` sin sesión,
/// `AccountSuspendedFailure` si la cuenta está sancionada, `NotFoundFailure`
/// si la otra cuenta ya no existe.
abstract interface class FollowRepository {
  Future<FollowState> follow(String userId);

  Future<FollowState> unfollow(String userId);

  /// Quién sigue a [userId] ([FollowListKind.followers]) o a quién sigue
  /// ([FollowListKind.following]), del más reciente al más viejo. Pasar el
  /// `nextCursor` de la página anterior para seguir.
  Future<FollowPage> list(String userId, FollowListKind kind, {String? cursor});

  /// Creadores verificados que quien mira todavía no sigue. Sin sesión, los
  /// más seguidos.
  Future<List<ProfileSummary>> suggestions({int? limit});
}
