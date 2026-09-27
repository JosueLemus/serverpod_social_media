import 'failures.dart';

String failureMessage(Failure failure) => switch (failure) {
  NetworkFailure() => 'Revisa tu conexión e inténtalo de nuevo.',
  ServerFailure() => 'No pudimos completar la solicitud. Inténtalo pronto.',
  _ => 'Ocurrió algo inesperado. Inténtalo nuevamente.',
};
