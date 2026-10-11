import 'package:equatable/equatable.dart';

/// Una cuenta en una lista: seguidores, seguidos o "a quién seguir".
///
/// Es menos que un [PublicProfile] a propósito: una fila no necesita la bio
/// ni el estado de la cuenta, y una lista de cien perfiles completos es una
/// lectura de cien perfiles.
class ProfileSummary extends Equatable {
  const ProfileSummary({
    required this.id,
    required this.username,
    required this.name,
    this.bio,
    this.avatarUrl,
    this.isCreator = false,
    this.isVerified = false,
    this.followerCount,
    this.viewerFollows = false,
  });

  /// El id de la cuenta en el servidor. Es lo que piden `follow`/`unfollow`.
  final String id;

  /// Sin `@`.
  final String username;
  final String name;
  final String? bio;
  final String? avatarUrl;
  final bool isCreator;
  final bool isVerified;

  /// Null cuando no se sabe (el mock). No se dibuja un número inventado.
  final int? followerCount;

  /// Si quien mira ya la sigue. Lo calcula el servidor para cada sesión.
  final bool viewerFollows;

  ProfileSummary copyWith({
    bool? viewerFollows,
    int? Function()? followerCount,
  }) => ProfileSummary(
    id: id,
    username: username,
    name: name,
    bio: bio,
    avatarUrl: avatarUrl,
    isCreator: isCreator,
    isVerified: isVerified,
    followerCount: followerCount == null ? this.followerCount : followerCount(),
    viewerFollows: viewerFollows ?? this.viewerFollows,
  );

  @override
  List<Object?> get props => [
    id,
    username,
    name,
    bio,
    avatarUrl,
    isCreator,
    isVerified,
    followerCount,
    viewerFollows,
  ];
}

/// Lo que dice el servidor después de seguir o dejar de seguir.
///
/// La respuesta reemplaza al cambio optimista: el contador de la pantalla
/// queda en el número real, no en "lo que había más uno".
class FollowState extends Equatable {
  const FollowState({
    required this.userId,
    required this.viewerFollows,
    this.followerCount,
  });

  final String userId;
  final bool viewerFollows;

  /// Null cuando la fuente no cuenta seguidores (el mock).
  final int? followerCount;

  @override
  List<Object?> get props => [userId, viewerFollows, followerCount];
}

class FollowPage extends Equatable {
  const FollowPage(this.items, {this.nextCursor});

  final List<ProfileSummary> items;

  /// Null cuando no hay más.
  final String? nextCursor;

  @override
  List<Object?> get props => [items, nextCursor];
}

/// Qué lista de cuentas se pide sobre un perfil.
enum FollowListKind { followers, following }
