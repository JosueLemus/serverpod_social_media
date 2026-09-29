import 'package:equatable/equatable.dart';

/// Un fallo de dominio. [message] es para telemetría, nunca para pintar: la
/// copy la elige la View según el tipo (`failureMessage`).
///
/// Implementa [Exception] para que un repositorio lo pueda lanzar tal cual:
/// el mock lanza el mismo tipo que va a mapear el cliente de Serverpod desde
/// `NexoErrorCode`, así que la View no cambia el día que se conecte.
sealed class Failure extends Equatable implements Exception {
  const Failure(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

class UnexpectedFailure extends Failure {
  const UnexpectedFailure(super.message);
}

/// `NexoErrorCode.forbidden`: la cuenta no tiene permiso para la acción.
class ForbiddenFailure extends Failure {
  const ForbiddenFailure(super.message);
}

/// `NexoErrorCode.notFound`.
class NotFoundFailure extends Failure {
  const NotFoundFailure(super.message);
}

/// `NexoErrorCode.conflict`: la transición no es legal desde el estado actual.
class ConflictFailure extends Failure {
  const ConflictFailure(super.message);
}

/// `NexoErrorCode.accountSuspended`: la sesión ya no vale. El cliente la
/// cierra y muestra la pantalla de cuenta suspendida.
class AccountSuspendedFailure extends Failure {
  const AccountSuspendedFailure(super.message);
}

/// Public, typed reasons for an authentication form failure. The server's
/// exception text is deliberately not carried into the UI or logs.
enum AuthFailureReason {
  invalidCredentials,
  invalidCode,
  expiredCode,
  tooManyAttempts,
  passwordPolicy,
  storage,
  network,
  unavailable,
}

class AuthenticationFailure extends Failure {
  const AuthenticationFailure(this.reason, [super.message = 'authentication']);

  final AuthFailureReason reason;

  @override
  List<Object?> get props => [reason, message];
}

/// `NexoErrorCode.creatorNotVerified`: el gate de vivos.
class CreatorNotVerifiedFailure extends Failure {
  const CreatorNotVerifiedFailure(super.message);
}

/// La cuenta tiene un silenciamiento vigente.
class MutedFailure extends Failure {
  const MutedFailure(super.message);
}
