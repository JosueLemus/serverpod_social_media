import '../../../../core/errors/failures.dart';

/// Por qué el servidor rechazó una acción de la consola. La View lo traduce.
enum AdminIssue { forbidden, conflict, notFound, other }

/// Qué acaba de pasar, para confirmarlo. Una acción de consola que no deja
/// rastro visible se siente como que no se aplicó, y el operador la repite.
enum AdminNotice {
  suspended,
  banned,
  restored,
  verified,
  verificationRevoked,
  liveEnded,
}

AdminIssue adminIssueFor(Failure failure) => switch (failure) {
  ForbiddenFailure() || AccountSuspendedFailure() => AdminIssue.forbidden,
  ConflictFailure() => AdminIssue.conflict,
  NotFoundFailure() => AdminIssue.notFound,
  _ => AdminIssue.other,
};
