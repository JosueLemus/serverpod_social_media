import 'package:serverpod/serverpod.dart';

import '../../../generated/protocol.dart';
import '../../../shared/audit/audit_service.dart';
import '../../../shared/auth/auth_context.dart';
import '../../identity/services/identity_service.dart';
import 'live_permissions.dart';
import 'live_rules.dart';
import 'live_sanctions.dart';
import 'live_stage_service.dart';

/// Arma la vista pública de mensajes del chat (autor, avatar). La tiene
/// `LiveService`; se inyecta para no depender de él.
typedef MessageViews =
    Future<List<LiveChatMessageView>> Function(
      Session session,
      List<LiveChatMessage> messages,
    );

/// La moderación dentro de una sala (SDD 0011, Etapa 3): silenciar en el
/// chat, expulsar, banear, ocultar, borrar, fijar, destacar y nombrar al
/// moderador.
///
/// Mismo esqueleto que [LiveStageService]: la tabla de `LivePermissions` con
/// la regla de rango, una transacción que bloquea el show, la auditoría de
/// todo lo que recae sobre otra persona (S13) y la publicación **después** del
/// commit.
class LiveModerationService {
  LiveModerationService({
    required this._stage,
    required this._messageViews,
    this._identity = const IdentityService(),
    this._audit = const AuditService(),
    DateTime Function()? now,
  }) : _now = now ?? (() => DateTime.now().toUtc());

  final LiveStageService _stage;
  final MessageViews _messageViews;
  final IdentityService _identity;
  final AuditService _audit;
  final DateTime Function() _now;

  // --- Personas --------------------------------------------------------------

  /// Nombra al moderador del vivo, o lo quita con [userId] null. Uno solo
  /// (S7): nombrar a otro baja al anterior. Se puede antes de salir al aire.
  Future<void> assignModerator(
    Session session,
    int showId,
    UuidValue? userId,
  ) => _change(
    session,
    showId,
    allowScheduled: true,
    (show, actor, role, tx) async {
      if (!LivePermissions.can(
        role,
        LiveAction.assignModerator,
        target: userId == null
            ? LiveShowRole.audience
            : await _stage.roleOf(session, show, userId, transaction: tx),
      )) {
        throw _forbidden();
      }
      final events = <LiveEvent>[];
      final current = await LiveParticipant.db.find(
        session,
        where: (t) =>
            t.showId.equals(showId) & t.role.equals(LiveShowRole.moderator),
        transaction: tx,
      );
      for (final previous in current) {
        if (previous.userId == userId) return const [];
        final demoted = previous.onStage
            ? LiveShowRole.cohost
            : LiveShowRole.audience;
        await LiveParticipant.db.updateRow(
          session,
          previous.copyWith(role: demoted, updatedAt: _now()),
          transaction: tx,
        );
        events.add(_roleChanged(previous.userId, demoted));
      }
      if (userId != null) {
        await _upsert(
          session,
          showId,
          userId,
          (r) => r.copyWith(role: LiveShowRole.moderator),
          tx,
        );
        events.add(_roleChanged(userId, LiveShowRole.moderator));
      }
      await _record(
        session,
        actor,
        userId == null ? 'live.unassignModerator' : 'live.assignModerator',
        showId,
        userId,
        tx,
      );
      return events;
    },
  );

  /// Silencio en el chat por [minutes] (5, 15 o 60) o, con null, el resto del
  /// vivo.
  Future<void> muteChat(
    Session session,
    int showId,
    UuidValue userId,
    int? minutes,
  ) => _change(session, showId, (show, actor, role, tx) async {
    LiveRules.checkChatMute(minutes);
    await _requireOver(session, show, role, LiveAction.muteChat, userId, tx);
    final until = minutes == null
        ? null
        : _now().add(Duration(minutes: minutes));
    await LiveSanction.db.insertRow(
      session,
      LiveSanction(
        showId: showId,
        targetId: userId,
        kind: LiveSanctionKind.chatMute,
        until: until,
        actorId: actor,
      ),
      transaction: tx,
    );
    await _record(session, actor, 'live.muteChat', showId, userId, tx, {
      'minutes': minutes,
    });
    return [_sanction(userId, LiveSanctionKind.chatMute, until)];
  });

  /// Levanta el silencio vigente antes de tiempo.
  Future<void> unmuteChat(Session session, int showId, UuidValue userId) =>
      _change(session, showId, (show, actor, role, tx) async {
        await _requireOver(
          session,
          show,
          role,
          LiveAction.muteChat,
          userId,
          tx,
        );
        final now = _now();
        final mute = await LiveSanctions.activeMute(
          session,
          showId,
          userId,
          now,
          transaction: tx,
        );
        if (mute == null) return const [];
        await LiveSanction.db.updateRow(
          session,
          mute.copyWith(until: now),
          transaction: tx,
        );
        await _record(session, actor, 'live.unmuteChat', showId, userId, tx);
        // `until` en el pasado: el silencio terminó.
        return [_sanction(userId, LiveSanctionKind.chatMute, now)];
      });

  /// Fuera de este vivo. Si estaba en el escenario, baja; si pidió la
  /// palabra, el pedido se va; si era el moderador, deja de serlo.
  Future<void> kick(Session session, int showId, UuidValue userId) => _change(
    session,
    showId,
    (show, actor, role, tx) async {
      await _requireOver(session, show, role, LiveAction.kick, userId, tx);
      await _exclude(session, show, userId, actor, tx);
      await _record(session, actor, 'live.kick', showId, userId, tx);
      return [_sanction(userId, LiveSanctionKind.kick, null)];
    },
  );

  /// Fuera de este vivo y de todos los del host, hasta que el host lo
  /// levante. Sólo el host.
  Future<void> ban(Session session, int showId, UuidValue userId) => _change(
    session,
    showId,
    (show, actor, role, tx) async {
      await _requireOver(session, show, role, LiveAction.ban, userId, tx);
      final existing = await LiveHostBan.db.count(
        session,
        where: (t) => t.hostId.equals(show.hostId) & t.userId.equals(userId),
        transaction: tx,
      );
      if (existing == 0) {
        await LiveHostBan.db.insertRow(
          session,
          LiveHostBan(hostId: show.hostId, userId: userId, actorId: actor),
          transaction: tx,
        );
      }
      await _exclude(session, show, userId, actor, tx);
      await _record(session, actor, 'live.ban', showId, userId, tx);
      return [_sanction(userId, LiveSanctionKind.ban, null)];
    },
  );

  /// Levanta un baneo propio: el de los vivos de quien lo pide.
  Future<void> unban(Session session, UuidValue userId) async {
    final host = session.requireUserId;
    await _identity.requireActive(session, host);
    await session.db.transaction((tx) async {
      final removed = await LiveHostBan.db.deleteWhere(
        session,
        where: (t) => t.hostId.equals(host) & t.userId.equals(userId),
        transaction: tx,
      );
      if (removed.isEmpty) return;
      await _audit.record(
        session,
        actorId: host,
        action: 'live.unban',
        entityType: 'account',
        entityId: userId.uuid,
        transaction: tx,
      );
    });
  }

  // --- Mensajes --------------------------------------------------------------

  /// Oculta un mensaje para todos. Reversible con [unhideChat].
  Future<void> hideChat(Session session, int messageId) =>
      _onMessage(session, messageId, LiveAction.hideChat, (
        show,
        message,
        actor,
        tx,
      ) async {
        if (message.hiddenAt != null) return const [];
        await LiveChatMessage.db.updateRow(
          session,
          message.copyWith(hiddenAt: _now(), hiddenBy: actor),
          columns: (t) => [t.hiddenAt, t.hiddenBy],
          transaction: tx,
        );
        await _audit.record(
          session,
          actorId: actor,
          action: 'live.hideChat',
          entityType: 'liveChatMessage',
          entityId: '$messageId',
          metadata: {'showId': message.showId},
          transaction: tx,
        );
        return [
          LiveEvent(kind: LiveEventKind.chatHidden, hiddenMessageId: messageId),
          ...await _unanchor(session, show, messageId, tx),
        ];
      });

  /// Devuelve un mensaje oculto al chat. Uno borrado no vuelve.
  Future<void> unhideChat(Session session, int messageId) =>
      _onMessage(session, messageId, LiveAction.hideChat, (
        show,
        message,
        actor,
        tx,
      ) async {
        if (message.hiddenAt == null || message.deletedAt != null) {
          return const [];
        }
        final restored = await LiveChatMessage.db.updateRow(
          session,
          message.copyWith(hiddenAt: null, hiddenBy: null),
          columns: (t) => [t.hiddenAt, t.hiddenBy],
          transaction: tx,
        );
        await _audit.record(
          session,
          actorId: actor,
          action: 'live.unhideChat',
          entityType: 'liveChatMessage',
          entityId: '$messageId',
          metadata: {'showId': message.showId},
          transaction: tx,
        );
        return [
          LiveEvent(
            kind: LiveEventKind.chatRestored,
            message: (await _messageViews(session, [restored])).single,
          ),
        ];
      });

  /// Borra un mensaje para todos y del replay. La fila queda para la
  /// auditoría (S12).
  Future<void> deleteChat(Session session, int messageId) => _onMessage(
    session,
    messageId,
    LiveAction.deleteChat,
    (
      show,
      message,
      actor,
      tx,
    ) async {
      if (message.deletedAt != null) return const [];
      await LiveChatMessage.db.updateRow(
        session,
        message.copyWith(deletedAt: _now(), deletedBy: actor),
        columns: (t) => [t.deletedAt, t.deletedBy],
        transaction: tx,
      );
      await _audit.record(
        session,
        actorId: actor,
        action: 'live.deleteChat',
        entityType: 'liveChatMessage',
        entityId: '$messageId',
        metadata: {'showId': message.showId},
        transaction: tx,
      );
      return [
        LiveEvent(kind: LiveEventKind.chatDeleted, hiddenMessageId: messageId),
        ...await _unanchor(session, show, messageId, tx),
      ];
    },
  );

  /// Fija un mensaje arriba del chat, o lo despega con [messageId] null.
  Future<void> pinChat(Session session, int showId, int? messageId) =>
      _anchor(session, showId, messageId, LiveAction.pinChat);

  /// Destaca una pregunta del chat para la conversación, o la quita con
  /// [messageId] null.
  Future<void> highlightQuestion(
    Session session,
    int showId,
    int? messageId,
  ) => _anchor(session, showId, messageId, LiveAction.highlightQuestion);

  // --- Lo que ve quien entra -------------------------------------------------

  /// El mensaje fijado y la pregunta destacada, si siguen visibles.
  Future<(LiveChatMessageView?, LiveChatMessageView?)> anchors(
    Session session,
    LiveShow show,
  ) async {
    final ids = {show.pinnedMessageId, show.highlightedMessageId}.nonNulls;
    if (ids.isEmpty) return (null, null);
    final rows = await LiveChatMessage.db.find(
      session,
      where: (t) =>
          t.id.inSet(ids.toSet()) &
          t.hiddenAt.equals(null) &
          t.deletedAt.equals(null),
    );
    final views = {
      for (final v in await _messageViews(session, rows)) v.id: v,
    };
    return (views[show.pinnedMessageId], views[show.highlightedMessageId]);
  }

  // --- Internos --------------------------------------------------------------

  Future<void> _anchor(
    Session session,
    int showId,
    int? messageId,
    LiveAction action,
  ) => _change(session, showId, (show, actor, role, tx) async {
    if (!LivePermissions.can(role, action)) throw _forbidden();
    LiveChatMessageView? view;
    if (messageId != null) {
      final message = await LiveChatMessage.db.findById(
        session,
        messageId,
        transaction: tx,
      );
      if (message == null ||
          message.showId != showId ||
          message.hiddenAt != null ||
          message.deletedAt != null) {
        throw _error(NexoErrorCode.notFound, 'El mensaje no existe.');
      }
      view = (await _messageViews(session, [message])).single;
    }
    final pin = action == LiveAction.pinChat;
    await LiveShow.db.updateRow(
      session,
      pin
          ? show.copyWith(pinnedMessageId: messageId)
          : show.copyWith(highlightedMessageId: messageId),
      columns: (t) => [pin ? t.pinnedMessageId : t.highlightedMessageId],
      transaction: tx,
    );
    await _audit.record(
      session,
      actorId: actor,
      action: pin ? 'live.pinChat' : 'live.highlightQuestion',
      entityType: 'liveShow',
      entityId: '$showId',
      metadata: {'messageId': messageId},
      transaction: tx,
    );
    return [
      pin
          ? LiveEvent(kind: LiveEventKind.pinned, pinned: view)
          : LiveEvent(kind: LiveEventKind.highlighted, highlighted: view),
    ];
  });

  /// Si el mensaje que se va estaba fijado o destacado, se despega: un ancla
  /// a un mensaje que nadie ve es un hueco arriba del chat.
  Future<List<LiveEvent>> _unanchor(
    Session session,
    LiveShow show,
    int messageId,
    Transaction tx,
  ) async {
    final pinned = show.pinnedMessageId == messageId;
    final highlighted = show.highlightedMessageId == messageId;
    if (!pinned && !highlighted) return const [];
    await LiveShow.db.updateRow(
      session,
      show.copyWith(
        pinnedMessageId: pinned ? null : show.pinnedMessageId,
        highlightedMessageId: highlighted ? null : show.highlightedMessageId,
      ),
      columns: (t) => [t.pinnedMessageId, t.highlightedMessageId],
      transaction: tx,
    );
    return [
      if (pinned) LiveEvent(kind: LiveEventKind.pinned),
      if (highlighted) LiveEvent(kind: LiveEventKind.highlighted),
    ];
  }

  /// Una acción sobre un mensaje: el rango se mide contra el de su autor.
  Future<void> _onMessage(
    Session session,
    int messageId,
    LiveAction action,
    Future<List<LiveEvent>> Function(
      LiveShow show,
      LiveChatMessage message,
      UuidValue actor,
      Transaction tx,
    )
    body,
  ) async {
    final actor = session.requireUserId;
    await _identity.requireActive(session, actor);
    final message = await LiveChatMessage.db.findById(session, messageId);
    if (message == null) {
      throw _error(NexoErrorCode.notFound, 'El mensaje no existe.');
    }
    await _change(
      session,
      message.showId,
      allowEnded: true,
      (show, actor, role, tx) async {
        final current = (await LiveChatMessage.db.findById(
          session,
          messageId,
          transaction: tx,
          lockMode: LockMode.forUpdate,
        ))!;
        await _requireOver(
          session,
          show,
          role,
          action,
          current.authorId,
          tx,
        );
        return body(show, current, actor, tx);
      },
    );
  }

  /// El esqueleto de toda acción: sesión activa, show al aire (o programado,
  /// o terminado, según la acción), bloqueado, y la publicación después del
  /// commit.
  Future<void> _change(
    Session session,
    int showId,
    Future<List<LiveEvent>> Function(
      LiveShow show,
      UuidValue actor,
      LiveShowRole role,
      Transaction tx,
    )
    body, {
    bool allowScheduled = false,
    bool allowEnded = false,
  }) async {
    final actor = session.requireUserId;
    await _identity.requireActive(session, actor);
    var stageChanged = false;
    final events = await session.db.transaction((tx) async {
      final show = await LiveShow.db.findById(
        session,
        showId,
        transaction: tx,
        lockMode: LockMode.forUpdate,
      );
      if (show == null || show.status == LiveShowStatus.removed) {
        throw _error(NexoErrorCode.notFound, 'El show no existe.');
      }
      final allowed =
          show.status == LiveShowStatus.live ||
          (allowScheduled && show.status == LiveShowStatus.scheduled) ||
          (allowEnded && LiveRules.isEnded(show.status));
      if (!allowed) {
        throw _error(NexoErrorCode.conflict, 'El show no está al aire.');
      }
      final role = await _stage.roleOf(
        session,
        show,
        actor,
        isStaff: session.isStaff,
        transaction: tx,
      );
      final result = await body(show, actor, role, tx);
      stageChanged = result.any(
        (e) =>
            e.kind == LiveEventKind.roleChanged ||
            (e.kind == LiveEventKind.sanction &&
                e.sanctionKind != LiveSanctionKind.chatMute),
      );
      return result;
    });

    final channel = LiveChannels.show(showId);
    for (final event in events) {
      await session.messages.postMessage(channel, event);
    }
    if (stageChanged) {
      await session.messages.postMessage(
        channel,
        LiveEvent(
          kind: LiveEventKind.stage,
          stage: await _stage.view(session, showId),
        ),
      );
    }
  }

  /// Saca a [userId] de la sala: sanción de expulsión, y fuera del escenario,
  /// de la cola y del rol de moderador.
  Future<void> _exclude(
    Session session,
    LiveShow show,
    UuidValue userId,
    UuidValue actor,
    Transaction tx,
  ) async {
    await LiveSanction.db.insertRow(
      session,
      LiveSanction(
        showId: show.id!,
        targetId: userId,
        kind: LiveSanctionKind.kick,
        actorId: actor,
      ),
      transaction: tx,
    );
    final row = await LiveParticipant.db.findFirstRow(
      session,
      where: (t) => t.showId.equals(show.id) & t.userId.equals(userId),
      transaction: tx,
    );
    if (row != null) {
      await LiveParticipant.db.updateRow(
        session,
        row.copyWith(
          role: LiveShowRole.audience,
          onStage: false,
          handRaisedAt: null,
          micMuted: false,
          cameraOn: false,
          updatedAt: _now(),
        ),
        transaction: tx,
      );
    }
  }

  Future<void> _upsert(
    Session session,
    int showId,
    UuidValue userId,
    LiveParticipant Function(LiveParticipant) change,
    Transaction tx,
  ) async {
    final row = await LiveParticipant.db.findFirstRow(
      session,
      where: (t) => t.showId.equals(showId) & t.userId.equals(userId),
      transaction: tx,
    );
    if (row == null) {
      await LiveParticipant.db.insertRow(
        session,
        change(
          LiveParticipant(
            showId: showId,
            userId: userId,
            role: LiveShowRole.audience,
            onStage: false,
            micMuted: false,
            cameraOn: false,
            updatedAt: _now(),
          ),
        ),
        transaction: tx,
      );
    } else {
      await LiveParticipant.db.updateRow(
        session,
        change(row).copyWith(updatedAt: _now()),
        transaction: tx,
      );
    }
  }

  Future<void> _requireOver(
    Session session,
    LiveShow show,
    LiveShowRole actorRole,
    LiveAction action,
    UuidValue target,
    Transaction tx,
  ) async {
    final targetRole = await _stage.roleOf(
      session,
      show,
      target,
      transaction: tx,
    );
    if (!LivePermissions.can(actorRole, action, target: targetRole)) {
      throw _forbidden();
    }
  }

  LiveEvent _roleChanged(UuidValue userId, LiveShowRole role) => LiveEvent(
    kind: LiveEventKind.roleChanged,
    targetId: userId,
    role: role,
  );

  LiveEvent _sanction(
    UuidValue userId,
    LiveSanctionKind kind,
    DateTime? until,
  ) => LiveEvent(
    kind: LiveEventKind.sanction,
    targetId: userId,
    sanctionKind: kind,
    until: until,
  );

  Future<void> _record(
    Session session,
    UuidValue actor,
    String action,
    int showId,
    UuidValue? target,
    Transaction tx, [
    Map<String, Object?> extra = const {},
  ]) => _audit.record(
    session,
    actorId: actor,
    action: action,
    entityType: 'liveShow',
    entityId: '$showId',
    metadata: {'target': ?target?.uuid, ...extra},
    transaction: tx,
  );

  static NexoException _forbidden() => _error(
    NexoErrorCode.forbidden,
    'Tu rol en la sala no permite esto sobre esa persona.',
  );

  static NexoException _error(NexoErrorCode code, String message) =>
      NexoException(code: code, message: message);
}
