import 'failures.dart';

String failureMessage(Failure failure) => switch (failure) {
  NetworkFailure() => 'Revisa tu conexión e inténtalo de nuevo.',
  ServerFailure() => 'No pudimos completar la solicitud. Inténtalo pronto.',
  ForbiddenFailure() => 'Tu cuenta no tiene permiso para hacer esto.',
  NotFoundFailure() => 'Lo que buscas ya no existe.',
  ConflictFailure() => 'Esta acción ya no es posible desde el estado actual.',
  AccountSuspendedFailure() => 'Tu cuenta está suspendida.',
  AuthenticationFailure() =>
    'No pudimos comprobar tu acceso. Inténtalo de nuevo.',
  CreatorNotVerifiedFailure() =>
    'Tu cuenta de creador no está verificada. Solo las cuentas verificadas '
        'pueden iniciar un vivo.',
  MutedFailure() => 'Estás silenciado en este momento.',
  UnexpectedFailure() => 'Ocurrió algo inesperado. Inténtalo nuevamente.',
};
