import 'package:serverpod/serverpod.dart';

import '../../../generated/protocol.dart';

/// Límites, normalización y máquina de estados de un show. Reglas puras: no
/// tocan la base.
abstract final class LiveRules {
  static const maxTitleLength = 100;
  static const maxDescriptionLength = 2000;
  static const minDurationMinutes = 15;
  static const maxDurationMinutes = 240;
  /// Lugares en el escenario además del host (SDD 0011, S4). Cuenta a los
  /// invitados de la agenda y a los que suben durante el vivo: 1 + 16 es el
  /// tope de publicadores por canal de Agora.
  static const maxGuests = 16;
  static const maxChatLength = 280;
  static const chatPageSize = 50;
  static const listLimit = 50;

  /// Entre dos mensajes de la misma cuenta.
  static const chatCooldown = Duration(seconds: 1);

  /// Cuánto dura un vivo de "Transmitir ahora" en la agenda. No lo corta:
  /// el vivo termina cuando el host lo termina.
  static const goLiveDurationMinutes = 60;

  /// Cuánto vale un token de video. Un vivo más largo pide otro al
  /// reconectarse.
  static const mediaTokenTtl = Duration(hours: 2);

  /// El canal de video de un show. El mismo nombre que arma la app: Agora
  /// acepta letras, números y guion bajo.
  static String mediaChannel(int showId) => 'nexo_live_$showId';

  /// Un uid de Agora estable por cuenta, para que dos personas del mismo
  /// canal no choquen. FNV-1a de 32 bits sobre el UUID, acotado a 31 bits
  /// (Agora acepta de 1 a 2^32-1; se deja el bit alto libre). Sin sesión, 0:
  /// Agora asigna uno.
  static int mediaUid(UuidValue? userId) {
    if (userId == null) return 0;
    var hash = 0x811c9dc5;
    for (final unit in userId.uuid.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    final uid = hash & 0x7fffffff;
    return uid == 0 ? 1 : uid;
  }

  /// La del SDD 0001, la misma que aplicaba el mock. Lo que no está acá es
  /// una transición ilegal y responde `conflict`.
  static const transitions = <LiveShowStatus, Set<LiveShowStatus>>{
    LiveShowStatus.draft: {LiveShowStatus.scheduled, LiveShowStatus.cancelled},
    LiveShowStatus.scheduled: {LiveShowStatus.live, LiveShowStatus.cancelled},
    LiveShowStatus.live: {
      LiveShowStatus.ending,
      LiveShowStatus.recorded,
      LiveShowStatus.failed,
    },
    LiveShowStatus.ending: {LiveShowStatus.recorded},
    LiveShowStatus.recorded: {
      LiveShowStatus.published,
      LiveShowStatus.removed,
    },
    LiveShowStatus.published: {LiveShowStatus.removed},
  };

  static bool canTransition(LiveShowStatus from, LiveShowStatus to) =>
      transitions[from]?.contains(to) ?? false;

  static bool isOnAir(LiveShowStatus status) =>
      status == LiveShowStatus.live || status == LiveShowStatus.ending;

  static bool isEnded(LiveShowStatus status) =>
      status == LiveShowStatus.recorded || status == LiveShowStatus.published;

  static String normalizeTitle(String title) {
    final trimmed = title.trim();
    if (trimmed.isEmpty) throw _invalid('El show necesita un título.');
    if (trimmed.length > maxTitleLength) {
      throw _invalid('El título supera los $maxTitleLength caracteres.');
    }
    return trimmed;
  }

  static String normalizeDescription(String description) {
    final trimmed = description.trim();
    if (trimmed.length > maxDescriptionLength) {
      throw _invalid(
        'La descripción supera los $maxDescriptionLength caracteres.',
      );
    }
    return trimmed;
  }

  static int checkDuration(int minutes) {
    if (minutes < minDurationMinutes || minutes > maxDurationMinutes) {
      throw _invalid(
        'La duración va de $minDurationMinutes a $maxDurationMinutes minutos.',
      );
    }
    return minutes;
  }

  static DateTime checkStartsAt(DateTime startsAt, DateTime now) {
    if (!startsAt.isAfter(now)) {
      throw _invalid('El show tiene que empezar en el futuro.');
    }
    return startsAt.toUtc();
  }

  /// Quita el `@`, pasa a minúsculas y descarta repetidos.
  static List<String> normalizeGuests(List<String> usernames) {
    final result = <String>{
      for (final raw in usernames)
        if (raw.trim().replaceFirst(RegExp('^@+'), '').isNotEmpty)
          raw.trim().replaceFirst(RegExp('^@+'), '').toLowerCase(),
    }.toList();
    if (result.length > maxGuests) {
      throw _invalid('Un show admite hasta $maxGuests invitados.');
    }
    return result;
  }

  static String normalizeChat(String body) {
    final trimmed = body.trim();
    if (trimmed.isEmpty) throw _invalid('El mensaje está vacío.');
    if (trimmed.length > maxChatLength) {
      throw _invalid('El mensaje supera los $maxChatLength caracteres.');
    }
    return trimmed;
  }

  static NexoException _invalid(String message) =>
      NexoException(code: NexoErrorCode.invalidInput, message: message);
}

/// Nombres de los canales de `session.messages`.
abstract final class LiveChannels {
  /// Lo que pasa dentro de un show: estado, espectadores y chat.
  static String show(int showId) => 'live:$showId';

  /// Cada cambio de estado de cualquier show, para "quién está en vivo".
  static const index = 'live:index';
}
