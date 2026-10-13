import 'package:equatable/equatable.dart';

import '../../../auth/domain/entities/app_user.dart';

/// El perfil de una cuenta tal como lo ve cualquiera.
///
/// [followers], [following] y [likes] son opcionales a propósito (SDD 0007,
/// F8): un perfil real con "48.5K seguidores" inventados es justo el dato
/// falso que la auditoría encontró. Null quiere decir "no se sabe", y no se
/// dibuja. Con M2 el servidor cuenta seguidores y seguidos; los likes
/// todavía no.
class PublicProfile extends Equatable {
  const PublicProfile({
    required this.id,
    required this.username,
    required this.name,
    this.bio,
    this.isCreator = false,
    this.verification = VerificationStatus.none,
    this.status = AccountStatus.active,
    this.joinedAt,
    this.followers,
    this.following,
    this.likes,
    this.viewerFollows = false,
    this.avatarUrl,
    this.coverUrl,
    this.website,
    this.posts,
  });

  /// El id de la cuenta en el servidor. Es lo que pide `posts.byAuthor`.
  final String id;

  /// Sin `@`.
  final String username;
  final String name;
  final String? bio;
  final bool isCreator;
  final VerificationStatus verification;
  final AccountStatus status;
  final DateTime? joinedAt;
  final int? followers;
  final int? following;
  final int? likes;

  /// Si quien mira sigue a esta cuenta. Lo calcula el servidor por sesión.
  final bool viewerFollows;

  /// La foto de perfil. Null: se dibuja la inicial.
  final String? avatarUrl;

  /// El banner del encabezado. Null: el vinilo de la cuenta.
  final String? coverUrl;

  /// El enlace propio, ya con esquema (`https://…`).
  final String? website;

  /// Publicaciones no borradas, contadas en el servidor. Null en el mock,
  /// que no las cuenta: no se dibuja un número que no se sabe.
  final int? posts;

  bool get isVerified => verification == VerificationStatus.verified;

  /// Seguir cambia dos cosas a la vez: el botón y el contador.
  PublicProfile copyWith({bool? viewerFollows, int? Function()? followers}) =>
      PublicProfile(
        id: id,
        username: username,
        name: name,
        bio: bio,
        isCreator: isCreator,
        verification: verification,
        status: status,
        joinedAt: joinedAt,
        followers: followers == null ? this.followers : followers(),
        following: following,
        likes: likes,
        viewerFollows: viewerFollows ?? this.viewerFollows,
        avatarUrl: avatarUrl,
        coverUrl: coverUrl,
        website: website,
        posts: posts,
      );

  @override
  List<Object?> get props => [
    id,
    username,
    name,
    bio,
    isCreator,
    verification,
    status,
    joinedAt,
    followers,
    following,
    likes,
    viewerFollows,
    avatarUrl,
    coverUrl,
    website,
    posts,
  ];
}
