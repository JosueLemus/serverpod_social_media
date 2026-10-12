import 'package:serverpod/serverpod.dart';

import '../../../generated/future_calls.dart';
import '../../../generated/protocol.dart';

/// Los identificadores de las Future Calls de un show. Con identificador se
/// pueden cancelar cuando el show cambia (S15 del SDD 0008).
abstract final class ShowCallIds {
  static String reminder(int showId) => 'show:$showId:reminder';
  static String expire(int showId) => 'show:$showId:expire';
  static String replay(int showId) => 'show:$showId:replay';
}

/// Qué tareas diferidas tiene un show en cada momento de su vida. Interfaz
/// para que los tests verifiquen qué se programó sin esperar el reloj (S16).
abstract interface class ShowScheduler {
  /// Recordatorio 15 min antes (si todavía es futuro) y expiración a los
  /// 30 min del inicio.
  Future<void> scheduled(Session session, LiveShow show);

  /// El show salió al aire: ya no hace falta recordar ni expirar.
  Future<void> started(Session session, int showId);

  /// El show se canceló antes de empezar.
  Future<void> cancelled(Session session, int showId);

  /// El show terminó: si guarda replay, se publica solo a +1 min.
  Future<void> ended(Session session, LiveShow show);

  /// El replay se publicó a mano: la publicación automática sobra.
  Future<void> published(Session session, int showId);
}

/// [ShowScheduler] sobre las Future Calls de Serverpod: quedan en la base y
/// sobreviven a un reinicio del servidor.
class FutureCallShowScheduler implements ShowScheduler {
  const FutureCallShowScheduler();

  static const reminderLead = Duration(minutes: 15);
  static const expireAfter = Duration(minutes: 30);
  static const replayDelay = Duration(minutes: 1);

  @override
  Future<void> scheduled(Session session, LiveShow show) => _safely(
    session,
    () async {
      final calls = session.serverpod.futureCalls;
      final id = show.id!;
      await _cancelPending(session, id);
      final remindAt = show.startsAt.subtract(reminderLead);
      if (remindAt.isAfter(DateTime.now().toUtc())) {
        await calls
            .callAtTime(remindAt, identifier: ShowCallIds.reminder(id))
            .liveShow
            .remind(id);
      }
      await calls
          .callAtTime(
            show.startsAt.add(expireAfter),
            identifier: ShowCallIds.expire(id),
          )
          .liveShow
          .expire(id);
    },
  );

  @override
  Future<void> started(Session session, int showId) =>
      _safely(session, () => _cancelPending(session, showId));

  @override
  Future<void> cancelled(Session session, int showId) =>
      _safely(session, () => _cancelPending(session, showId));

  @override
  Future<void> ended(Session session, LiveShow show) => _safely(
    session,
    () async {
      if (!show.recordReplay) return;
      final id = show.id!;
      await session.serverpod.futureCalls
          .callWithDelay(replayDelay, identifier: ShowCallIds.replay(id))
          .liveShow
          .publishReplay(id);
    },
  );

  @override
  Future<void> published(Session session, int showId) => _safely(
    session,
    () => session.serverpod.futureCalls.cancel(ShowCallIds.replay(showId)),
  );

  Future<void> _cancelPending(Session session, int showId) async {
    final calls = session.serverpod.futureCalls;
    await calls.cancel(ShowCallIds.reminder(showId));
    await calls.cancel(ShowCallIds.expire(showId));
  }

  /// Programar una tarea nunca tumba la acción que la origina: el show ya
  /// cambió y quedó auditado. Si no se pudo, se registra y se sigue.
  static Future<void> _safely(
    Session session,
    Future<void> Function() action,
  ) async {
    try {
      await action();
    } on Object catch (error, stack) {
      session.log(
        'No se pudo programar una tarea del show: $error',
        level: LogLevel.warning,
        exception: error,
        stackTrace: stack,
      );
    }
  }
}
