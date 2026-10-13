import 'package:serverpod/serverpod.dart';

import '../../../generated/protocol.dart';
import '../../../shared/auth/auth_context.dart';
import '../services/messages_service.dart';

/// Mensajes directos 1 a 1 (SDD 0010). Desde Flutter: `client.messages`.
/// Todo exige sesión.
class MessagesEndpoint extends Endpoint {
  static const _messages = MessagesService();

  /// La bandeja: la conversación con actividad más reciente primero. No
  /// lista las conversaciones sin mensajes.
  Future<ConversationPage> conversations(
    Session session, {
    PageCursor? after,
    int? limit,
  }) => _messages.conversations(session, after: after, limit: limit);

  /// La conversación con [userId], creándola si no existía.
  Future<ConversationView> open(Session session, UuidValue userId) =>
      _messages.open(session, userId);

  /// Una conversación de la sesión, con el otro miembro y los no leídos.
  Future<ConversationView> conversation(Session session, int conversationId) =>
      _messages.conversation(session, conversationId);

  /// Mensajes anteriores a [beforeId] (o los últimos), del más viejo al más
  /// nuevo.
  Future<DirectMessagePage> history(
    Session session,
    int conversationId, {
    int? beforeId,
    int? limit,
  }) => _messages.history(
    session,
    conversationId,
    beforeId: beforeId,
    limit: limit,
  );

  Future<DirectMessageView> send(
    Session session,
    int conversationId,
    String body,
  ) => _messages.send(session, conversationId, body);

  /// Marca leída la conversación. Devuelve las que quedan sin leer.
  Future<int> markRead(Session session, int conversationId) =>
      _messages.markRead(session, conversationId);

  /// Conversaciones con algo sin leer: el número del badge.
  Future<int> unreadCount(Session session) => _messages.unreadCount(session);

  /// Mensajes nuevos y lecturas de las conversaciones de la sesión, en el
  /// momento.
  Stream<DirectMessageEvent> watch(Session session) {
    // La sesión se valida y el canal se abre antes de cualquier `await`,
    // como `live.watch`: lo que llega mientras tanto no se pierde.
    final userId = session.requireUserId;
    return session.messages.createStream<DirectMessageEvent>(
      MessagesChannels.user(userId),
    );
  }
}
