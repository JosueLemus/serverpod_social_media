import '../entities/direct_message.dart';

/// Mensajes directos 1 a 1 (SDD 0010). El servidor decide quién ve y escribe
/// qué; la app sólo lo dibuja.
abstract interface class MessagesRepository {
  /// La bandeja, con actividad más reciente primero.
  Future<ConversationPage> conversations({String? cursor});

  /// Una conversación de la sesión.
  Future<Conversation> conversation(String conversationId);

  /// La conversación con [userId], creándola si no existía.
  Future<Conversation> open(String userId);

  /// Los últimos mensajes o, con [beforeId], los anteriores a ese.
  Future<MessageHistory> history(String conversationId, {String? beforeId});

  Future<DirectMessage> send(String conversationId, String body);

  /// Marca leída la conversación. Devuelve las que quedan sin leer.
  Future<int> markRead(String conversationId);

  /// Conversaciones con algo sin leer.
  Future<int> unreadCount();

  /// Mensajes nuevos y lecturas, en el momento.
  Stream<DirectMessageEvent> watch();
}
