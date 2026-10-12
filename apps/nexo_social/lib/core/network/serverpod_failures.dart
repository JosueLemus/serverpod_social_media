import 'package:nexo_client/nexo_client.dart' as api;

import '../errors/failures.dart';

/// Traduce lo que lanza el cliente de Serverpod a un [Failure] tipado.
///
/// Un solo lugar para todos los repositorios: si cada uno mapeara por su
/// cuenta, el mismo `forbidden` terminaría con tres copys distintas. El
/// `message` del servidor queda en el Failure para telemetría y nunca se
/// pinta.
Failure failureFromServer(Object error) {
  if (error is Failure) return error;
  if (error is api.NexoException) {
    final message = error.message;
    return switch (error.code) {
      api.NexoErrorCode.unauthenticated ||
      api.NexoErrorCode.forbidden => ForbiddenFailure(message),
      api.NexoErrorCode.notFound => NotFoundFailure(message),
      api.NexoErrorCode.conflict => ConflictFailure(message),
      api.NexoErrorCode.invalidInput ||
      api.NexoErrorCode.rateLimited => ServerFailure(message),
    };
  }
  final description = '${error.runtimeType} $error'.toLowerCase();
  if (description.contains('socket') ||
      description.contains('connection') ||
      description.contains('xmlhttprequest') ||
      description.contains('timeout') ||
      description.contains('clientexception')) {
    return NetworkFailure(description);
  }
  if (error is api.ServerpodClientException) {
    return ServerFailure(error.message);
  }
  return UnexpectedFailure(description);
}
