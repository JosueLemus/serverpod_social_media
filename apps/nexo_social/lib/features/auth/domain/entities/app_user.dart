import 'package:equatable/equatable.dart';

/// El nivel de permiso de la cuenta. Espeja los scopes de Serverpod
/// (`NexoScopes.moderator`, `NexoScopes.admin`) y son excluyentes.
///
/// "Creador" **no** es un rol: vive en el perfil ([AppUser.isCreator]), igual
/// que en el backend. Mezclarlo con los scopes obligaría a reescribir los
/// guards el día que un moderador también publique.
enum UserRole { visitor, user, moderator, operator }

/// Si la cuenta puede operar. Suspender es reversible; banear, no desde la
/// consola.
enum AccountStatus { active, suspended, banned }

/// La verificación es una capacidad y no una insignia: sin ella el servidor
/// rechaza iniciar un vivo.
enum VerificationStatus { none, verified, revoked }

class AppUser extends Equatable {
  const AppUser({
    required this.id,
    required this.username,
    required this.name,
    required this.role,
    this.email = '',
    this.isCreator = false,
    this.verification = VerificationStatus.none,
    this.status = AccountStatus.active,
  });

  final String id;
  final String username;
  final String name;
  final String email;
  final UserRole role;
  final bool isCreator;
  final VerificationStatus verification;
  final AccountStatus status;

  bool get isVerified => verification == VerificationStatus.verified;
  bool get isActive => status == AccountStatus.active;
  bool get canModerate =>
      role == UserRole.moderator || role == UserRole.operator;
  bool get isOperator => role == UserRole.operator;

  @override
  List<Object?> get props => [
    id,
    username,
    name,
    email,
    role,
    isCreator,
    verification,
    status,
  ];
}
