import 'package:serverpod/serverpod.dart';

import '../services/live_service.dart';

/// Las tareas diferidas de un show (S15 del SDD 0008). Cada una vuelve a
/// mirar el estado: si el show ya cambió, no hace nada. Así un reintento o
/// un reinicio del servidor no duplica efectos.
class LiveShowFutureCall extends FutureCall {
  /// 15 minutos antes: avisa a los seguidores y a los invitados.
  Future<void> remind(Session session, int showId) =>
      LiveService().remind(session, showId);

  /// A los 30 minutos del inicio, un show que no arrancó se cancela.
  Future<void> expire(Session session, int showId) =>
      LiveService().expire(session, showId);

  /// 1 minuto después de terminar, el replay se publica solo.
  Future<void> publishReplay(Session session, int showId) =>
      LiveService().autoPublish(session, showId);
}
