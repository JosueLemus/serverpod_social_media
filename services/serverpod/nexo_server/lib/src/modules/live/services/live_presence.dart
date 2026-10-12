import 'package:serverpod/serverpod.dart';

/// Quién está mirando cada show, en memoria del proceso: una entrada por
/// conexión de `live.watch`.
///
/// Vale con una sola instancia (D12 del SDD 0004). Un contador en la base pide
/// una escritura por cada entrada y salida, y queda desincronizado si el
/// proceso muere sin restar; acá, si el proceso muere, la presencia arranca
/// vacía, que es lo correcto.
class LivePresence {
  LivePresence._();

  static final instance = LivePresence._();

  final _watching = <int, Set<Session>>{};
  final _peaks = <int, int>{};

  /// Suma [session] a [showId] y devuelve cuántos miran ahora.
  int join(int showId, Session session) {
    final sessions = _watching.putIfAbsent(showId, () => <Session>{});
    sessions.add(session);
    final count = sessions.length;
    if (count > (_peaks[showId] ?? 0)) _peaks[showId] = count;
    return count;
  }

  /// Resta [session] y devuelve cuántos quedan, o `null` si ya no estaba:
  /// así quien llama publica una sola vez aunque la baja llegue dos veces.
  int? leave(int showId, Session session) {
    final sessions = _watching[showId];
    if (sessions == null || !sessions.remove(session)) return null;
    if (sessions.isEmpty) _watching.remove(showId);
    return sessions.length;
  }

  int count(int showId) => _watching[showId]?.length ?? 0;

  /// El máximo de espectadores simultáneos desde que arrancó el proceso.
  int peak(int showId) => _peaks[showId] ?? 0;
}

/// Un mensaje por segundo por cuenta, en memoria del proceso.
class LiveChatThrottle {
  LiveChatThrottle._();

  static final instance = LiveChatThrottle._();

  final _lastSent = <UuidValue, DateTime>{};

  /// `true` y registra el envío si [userId] puede mandar ahora.
  bool tryAcquire(UuidValue userId, DateTime now, Duration cooldown) {
    final last = _lastSent[userId];
    if (last != null && now.difference(last) < cooldown) return false;
    _lastSent[userId] = now;
    if (_lastSent.length > 10000) _lastSent.clear();
    return true;
  }
}
