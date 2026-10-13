import 'package:serverpod/serverpod.dart';

/// Las reglas puras de los mensajes directos (SDD 0010). Sin base ni sesión:
/// se prueban solas.
abstract final class MessagesRules {
  static const maxBodyLength = 1000;
  static const defaultPageSize = 20;
  static const maxPageSize = 50;

  /// Un mensaje por segundo por cuenta, como el chat de los vivos.
  static const cooldown = Duration(seconds: 1);

  /// El par ordenado que identifica la conversación de [x] con [y]: el mismo
  /// par en cualquier orden da la misma fila (M2).
  static (UuidValue, UuidValue) pair(UuidValue x, UuidValue y) =>
      '$x'.compareTo('$y') <= 0 ? (x, y) : (y, x);

  /// El cuerpo listo para guardar, o `null` si no es válido: vacío o de más
  /// de [maxBodyLength] después del `trim`.
  static String? body(String raw) {
    final text = raw.trim();
    if (text.isEmpty || text.length > maxBodyLength) return null;
    return text;
  }

  static int pageSize(int? limit) =>
      (limit ?? defaultPageSize).clamp(1, maxPageSize);

  /// Si hay algo sin leer: el último mensaje es posterior al último leído.
  /// Mandar un mensaje mueve el puntero de quien lo manda (M5), así que lo
  /// propio nunca cuenta como no leído.
  static bool hasUnread({
    required int? lastMessageId,
    required int? lastRead,
  }) => lastMessageId != null && lastMessageId > (lastRead ?? 0);
}

/// Un envío por segundo por cuenta, en memoria del proceso (D12: una
/// instancia).
class MessagesThrottle {
  MessagesThrottle._();

  static final instance = MessagesThrottle._();

  final _lastSent = <UuidValue, DateTime>{};

  /// `true` y registra el envío si [userId] puede mandar ahora.
  bool tryAcquire(UuidValue userId, DateTime now) {
    final last = _lastSent[userId];
    if (last != null && now.difference(last) < MessagesRules.cooldown) {
      return false;
    }
    _lastSent[userId] = now;
    if (_lastSent.length > 10000) _lastSent.clear();
    return true;
  }

  /// Para los tests: cada uno arranca sin envíos previos.
  void reset() => _lastSent.clear();
}
