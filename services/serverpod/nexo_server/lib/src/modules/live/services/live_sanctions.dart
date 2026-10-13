import 'package:serverpod/serverpod.dart';

import '../../../generated/protocol.dart';

/// Las preguntas sobre sanciones que se hacen antes de dejar actuar a
/// alguien en una sala. Funciones sobre la base y nada más, para que las usen
/// el chat, el escenario y la moderación sin depender entre sí.
abstract final class LiveSanctions {
  /// Si [userId] no puede estar en [show]: expulsado de este vivo o baneado
  /// por su host.
  static Future<LiveSanctionKind?> exclusion(
    Session session,
    LiveShow show,
    UuidValue userId, {
    Transaction? transaction,
  }) async {
    final banned = await LiveHostBan.db.count(
      session,
      where: (t) => t.hostId.equals(show.hostId) & t.userId.equals(userId),
      transaction: transaction,
    );
    if (banned > 0) return LiveSanctionKind.ban;
    final kicked = await LiveSanction.db.count(
      session,
      where: (t) =>
          t.showId.equals(show.id) &
          t.targetId.equals(userId) &
          t.kind.equals(LiveSanctionKind.kick),
      transaction: transaction,
    );
    return kicked > 0 ? LiveSanctionKind.kick : null;
  }

  /// El silencio vigente de [userId] en [showId], si hay. Uno sin `until` es
  /// "el resto del vivo".
  static Future<LiveSanction?> activeMute(
    Session session,
    int showId,
    UuidValue userId,
    DateTime now, {
    Transaction? transaction,
  }) async {
    final mutes = await LiveSanction.db.find(
      session,
      where: (t) =>
          t.showId.equals(showId) &
          t.targetId.equals(userId) &
          t.kind.equals(LiveSanctionKind.chatMute),
      orderByList: (t) => [t.id.desc()],
      transaction: transaction,
    );
    for (final m in mutes) {
      if (m.until == null || m.until!.isAfter(now)) return m;
    }
    return null;
  }

  /// Lanza `forbidden` si [userId] está expulsado o baneado de [show].
  static Future<void> requireAdmitted(
    Session session,
    LiveShow show,
    UuidValue? userId, {
    Transaction? transaction,
  }) async {
    if (userId == null) return;
    final excluded = await exclusion(
      session,
      show,
      userId,
      transaction: transaction,
    );
    if (excluded == null) return;
    throw NexoException(
      code: NexoErrorCode.forbidden,
      message: excluded == LiveSanctionKind.ban
          ? 'El host te bloqueó de sus vivos.'
          : 'Te sacaron de este vivo.',
    );
  }
}
