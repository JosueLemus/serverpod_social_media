import 'package:serverpod/serverpod.dart';

import '../../../generated/protocol.dart';
import '../../../shared/auth/auth_context.dart';
import '../../identity/services/identity_service.dart';
import 'messages_rules.dart';

/// El canal de tiempo real de cada cuenta. Un canal tipa sus mensajes con una
/// sola clase, así que no se comparte con `notifications:<id>`.
abstract final class MessagesChannels {
  static String user(UuidValue userId) => 'dm:$userId';
}

/// Conversaciones 1 a 1: abrirlas, leerlas, escribir y avisar en el momento.
class MessagesService {
  const MessagesService({this._identity = const IdentityService()});

  final IdentityService _identity;

  // --- Bandeja ---------------------------------------------------------------

  Future<ConversationPage> conversations(
    Session session, {
    PageCursor? after,
    int? limit,
  }) async {
    final userId = session.requireUserId;
    final size = MessagesRules.pageSize(limit);
    final rows = await DmConversation.db.find(
      session,
      where: (t) {
        var where =
            (t.userA.equals(userId) | t.userB.equals(userId)) &
            t.lastMessageId.notEquals(null);
        if (after != null) {
          where =
              where &
              ((t.lastActivityAt < after.createdAt) |
                  (t.lastActivityAt.equals(after.createdAt) &
                      (t.id < after.id)));
        }
        return where;
      },
      orderByList: (t) => [t.lastActivityAt.desc(), t.id.desc()],
      limit: size + 1,
    );
    final hasMore = rows.length > size;
    final items = hasMore ? rows.sublist(0, size) : rows;
    return ConversationPage(
      items: await _views(session, userId, items),
      nextCursor: hasMore
          ? PageCursor(createdAt: items.last.lastActivityAt, id: items.last.id!)
          : null,
    );
  }

  /// La conversación de la sesión con [otherId]. Si no existía, la crea; si
  /// dos pedidos llegan a la vez, el lock por par hace que el segundo vea la
  /// del primero (M3).
  Future<ConversationView> open(Session session, UuidValue otherId) async {
    final userId = session.requireUserId;
    if (otherId == userId) {
      throw _error(NexoErrorCode.invalidInput, 'No podés escribirte a vos.');
    }
    await _identity.requireActive(session, userId);
    await _requireReachable(session, otherId);

    final (a, b) = MessagesRules.pair(userId, otherId);
    final conversation = await session.db.transaction((tx) async {
      await session.db.unsafeExecute(
        'SELECT pg_advisory_xact_lock(hashtext(@key))',
        parameters: QueryParameters.named({'key': 'dm:$a:$b'}),
        transaction: tx,
      );
      final existing = await DmConversation.db.findFirstRow(
        session,
        where: (t) => t.userA.equals(a) & t.userB.equals(b),
        transaction: tx,
      );
      return existing ??
          await DmConversation.db.insertRow(
            session,
            DmConversation(userA: a, userB: b),
            transaction: tx,
          );
    });
    return (await _views(session, userId, [conversation])).single;
  }

  /// Una conversación de la sesión, para dibujar el chat cuando se abre
  /// directo (un enlace, una notificación) y no desde la bandeja.
  Future<ConversationView> conversation(
    Session session,
    int conversationId,
  ) async {
    final userId = session.requireUserId;
    final row = await _requireMember(session, conversationId, userId);
    return (await _views(session, userId, [row])).single;
  }

  // --- Historia y envío ------------------------------------------------------

  Future<DirectMessagePage> history(
    Session session,
    int conversationId, {
    int? beforeId,
    int? limit,
  }) async {
    final userId = session.requireUserId;
    await _requireMember(session, conversationId, userId);
    final size = MessagesRules.pageSize(limit);
    final rows = await DmMessage.db.find(
      session,
      where: (t) {
        var where = t.conversationId.equals(conversationId);
        if (beforeId != null) where = where & (t.id < beforeId);
        return where;
      },
      orderByList: (t) => [t.id.desc()],
      limit: size + 1,
    );
    final hasMore = rows.length > size;
    final page = hasMore ? rows.sublist(0, size) : rows;
    return DirectMessagePage(
      items: [for (final row in page.reversed) _messageView(row)],
      hasMore: hasMore,
    );
  }

  Future<DirectMessageView> send(
    Session session,
    int conversationId,
    String body,
  ) async {
    final userId = session.requireUserId;
    final text = MessagesRules.body(body);
    if (text == null) {
      throw _error(
        NexoErrorCode.invalidInput,
        'El mensaje tiene que tener entre 1 y '
        '${MessagesRules.maxBodyLength} caracteres.',
      );
    }
    await _identity.requireActive(session, userId);
    final conversation = await _requireMember(session, conversationId, userId);
    await _requireReachable(session, _otherOf(conversation, userId));
    if (!MessagesThrottle.instance.tryAcquire(
      userId,
      DateTime.now().toUtc(),
    )) {
      throw _error(NexoErrorCode.rateLimited, 'Vas muy rápido.');
    }

    final message = await session.db.transaction((tx) async {
      // El lock de la fila mantiene `lastMessageId` creciente aunque los dos
      // escriban a la vez.
      final current = (await DmConversation.db.findById(
        session,
        conversationId,
        transaction: tx,
        lockMode: LockMode.forUpdate,
      ))!;
      final row = await DmMessage.db.insertRow(
        session,
        DmMessage(conversationId: conversationId, authorId: userId, body: text),
        transaction: tx,
      );
      final isA = current.userA == userId;
      await DmConversation.db.updateRow(
        session,
        current.copyWith(
          lastMessageId: row.id,
          lastActivityAt: row.createdAt,
          // Quien escribe vio lo anterior (M5).
          lastReadA: isA ? row.id : current.lastReadA,
          lastReadB: isA ? current.lastReadB : row.id,
        ),
        transaction: tx,
      );
      return row;
    });

    final view = _messageView(message);
    // Después del commit: si la transacción se revertía, nadie lo vio (M7).
    for (final member in [conversation.userA, conversation.userB]) {
      await _publish(
        session,
        member,
        DirectMessageEvent(
          kind: DirectMessageEventKind.message,
          conversationId: conversationId,
          message: view,
          unreadConversations: await _unreadConversations(session, member),
        ),
      );
    }
    return view;
  }

  // --- Leídos ----------------------------------------------------------------

  Future<int> markRead(Session session, int conversationId) async {
    final userId = session.requireUserId;
    final conversation = await _requireMember(session, conversationId, userId);
    final lastMessageId = conversation.lastMessageId;
    final isA = conversation.userA == userId;
    final lastRead = isA ? conversation.lastReadA : conversation.lastReadB;

    if (lastMessageId != null && lastMessageId != lastRead) {
      await DmConversation.db.updateRow(
        session,
        isA
            ? conversation.copyWith(lastReadA: lastMessageId)
            : conversation.copyWith(lastReadB: lastMessageId),
        columns: (t) => [isA ? t.lastReadA : t.lastReadB],
      );
    }

    final remaining = await _unreadConversations(session, userId);
    if (lastMessageId != null && lastMessageId != lastRead) {
      for (final member in [conversation.userA, conversation.userB]) {
        await _publish(
          session,
          member,
          DirectMessageEvent(
            kind: DirectMessageEventKind.read,
            conversationId: conversationId,
            readerId: userId,
            lastReadMessageId: lastMessageId,
            unreadConversations: member == userId
                ? remaining
                : await _unreadConversations(session, member),
          ),
        );
      }
    }
    return remaining;
  }

  Future<int> unreadCount(Session session) =>
      _unreadConversations(session, session.requireUserId);

  // --- Internos --------------------------------------------------------------

  /// Conversaciones de [userId] con algo sin leer (M6). Una sola consulta:
  /// comparar dos columnas de la misma fila no entra en el ORM.
  Future<int> _unreadConversations(Session session, UuidValue userId) async {
    final result = await session.db.unsafeQuery(
      'SELECT count(*) FROM "dm_conversation" '
      'WHERE "lastMessageId" IS NOT NULL AND ('
      '("userA" = @user::uuid AND '
      '("lastReadA" IS NULL OR "lastReadA" < "lastMessageId")) OR '
      '("userB" = @user::uuid AND '
      '("lastReadB" IS NULL OR "lastReadB" < "lastMessageId")))',
      parameters: QueryParameters.named({'user': '$userId'}),
    );
    return (result.first.first as num).toInt();
  }

  Future<DmConversation> _requireMember(
    Session session,
    int conversationId,
    UuidValue userId,
  ) async {
    final conversation = await DmConversation.db.findById(
      session,
      conversationId,
    );
    if (conversation == null) {
      throw _error(NexoErrorCode.notFound, 'Esa conversación no existe.');
    }
    if (conversation.userA != userId && conversation.userB != userId) {
      throw _error(NexoErrorCode.forbidden, 'Esa conversación no es tuya.');
    }
    return conversation;
  }

  /// [userId] existe y puede recibir mensajes. A una cuenta suspendida no se
  /// le escribe: es `forbidden` y no `accountSuspended`, que en la app quiere
  /// decir "tu cuenta".
  Future<void> _requireReachable(Session session, UuidValue userId) async {
    final account = await AccountProfile.db.findFirstRow(
      session,
      where: (t) => t.authUserId.equals(userId),
    );
    if (account == null) {
      throw _error(NexoErrorCode.notFound, 'Esa cuenta no existe.');
    }
    if (account.status != AccountStatus.active) {
      throw _error(
        NexoErrorCode.forbidden,
        'Esa cuenta no puede recibir mensajes.',
      );
    }
  }

  static UuidValue _otherOf(DmConversation conversation, UuidValue userId) =>
      conversation.userA == userId ? conversation.userB : conversation.userA;

  Future<List<ConversationView>> _views(
    Session session,
    UuidValue userId,
    List<DmConversation> conversations,
  ) async {
    if (conversations.isEmpty) return const [];
    final otherIds = {for (final c in conversations) _otherOf(c, userId)};
    final accounts = [
      for (final id in otherIds) await _identity.ensure(session, id),
    ];
    final profiles = {
      for (final view in await _identity.viewsOf(session, accounts))
        view.userId: view,
    };
    final lastIds = {
      for (final c in conversations)
        if (c.lastMessageId != null) c.lastMessageId!,
    };
    final lastMessages = lastIds.isEmpty
        ? const <int, DmMessage>{}
        : {
            for (final m in await DmMessage.db.find(
              session,
              where: (t) => t.id.inSet(lastIds),
            ))
              m.id!: m,
          };

    final views = <ConversationView>[];
    for (final c in conversations) {
      final lastRead = c.userA == userId ? c.lastReadA : c.lastReadB;
      final unread =
          MessagesRules.hasUnread(
            lastMessageId: c.lastMessageId,
            lastRead: lastRead,
          )
          ? await DmMessage.db.count(
              session,
              where: (t) =>
                  t.conversationId.equals(c.id!) &
                  (t.id > (lastRead ?? 0)) &
                  t.authorId.notEquals(userId),
            )
          : 0;
      final last = c.lastMessageId == null
          ? null
          : lastMessages[c.lastMessageId];
      views.add(
        ConversationView(
          id: c.id!,
          other: profiles[_otherOf(c, userId)]!,
          lastMessage: last == null ? null : _messageView(last),
          unreadCount: unread,
          lastActivityAt: c.lastActivityAt,
        ),
      );
    }
    return views;
  }

  static DirectMessageView _messageView(DmMessage row) => DirectMessageView(
    id: row.id!,
    conversationId: row.conversationId,
    authorId: row.authorId,
    body: row.body,
    createdAt: row.createdAt,
  );

  static Future<void> _publish(
    Session session,
    UuidValue userId,
    DirectMessageEvent event,
  ) => session.messages.postMessage(MessagesChannels.user(userId), event);

  static NexoException _error(NexoErrorCode code, String message) =>
      NexoException(code: code, message: message);
}
