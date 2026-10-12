import 'package:equatable/equatable.dart';

import '../../../auth/domain/entities/app_user.dart';

/// El perfil de una cuenta tal como lo ve cualquiera.
///
/// [followers], [following] y [likes] son opcionales a propósito (SDD 0007,
/// F8): el servidor todavía no los tiene (llegan con los follows, M2), y un
/// perfil real con "48.5K seguidores" inventados es justo el dato falso que
/// la auditoría encontró. Null quiere decir "no se sabe", y no se dibuja.
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

  bool get isVerified => verification == VerificationStatus.verified;

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
  ];
}
