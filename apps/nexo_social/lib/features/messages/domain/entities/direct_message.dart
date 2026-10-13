import 'package:equatable/equatable.dart';

/// Si un mensaje propio ya llegó al servidor. Los ajenos siempre son [sent].
///
/// [failed] se puede reintentar (red, ritmo); [rejected] no: el servidor no
/// lo va a aceptar nunca (sin permiso, cuenta suspendida, cuerpo inválido).
enum MessageDelivery { sent, sending, failed, rejected }

/// Un mensaje directo (SDD 0010). Quién es "yo" lo decide quien lo dibuja,
/// comparando [authorId] con la sesión.
class DirectMessage extends Equatable {
  const DirectMessage({
    required this.id,
    required this.conversationId,
    required this.authorId,
    required this.body,
    required this.createdAt,
    this.delivery = MessageDelivery.sent,
  });

  /// El del servidor, o uno local (`local-…`) mientras se envía.
  final String id;
  final String conversationId;
  final String authorId;
  final String body;
  final DateTime createdAt;
  final MessageDelivery delivery;

  DirectMessage copyWith({MessageDelivery? delivery}) => DirectMessage(
    id: id,
    conversationId: conversationId,
    authorId: authorId,
    body: body,
    createdAt: createdAt,
    delivery: delivery ?? this.delivery,
  );

  @override
  List<Object?> get props => [
    id,
    conversationId,
    authorId,
    body,
    createdAt,
    delivery,
  ];
}

/// El otro miembro de una conversación, lo justo para dibujarlo.
class ChatPeer extends Equatable {
  const ChatPeer({
    required this.id,
    required this.username,
    required this.name,
    this.avatarUrl,
  });

  final String id;
  final String username;
  final String name;
  final String? avatarUrl;

  @override
  List<Object?> get props => [id, username, name, avatarUrl];
}

/// Una conversación vista por la cuenta de la sesión.
class Conversation extends Equatable {
  const Conversation({
    required this.id,
    required this.peer,
    required this.lastActivityAt,
    this.lastMessage,
    this.unreadCount = 0,
  });

  final String id;
  final ChatPeer peer;
  final DirectMessage? lastMessage;
  final int unreadCount;
  final DateTime lastActivityAt;

  Conversation copyWith({
    DirectMessage? lastMessage,
    int? unreadCount,
    DateTime? lastActivityAt,
  }) => Conversation(
    id: id,
    peer: peer,
    lastMessage: lastMessage ?? this.lastMessage,
    unreadCount: unreadCount ?? this.unreadCount,
    lastActivityAt: lastActivityAt ?? this.lastActivityAt,
  );

  @override
  List<Object?> get props => [
    id,
    peer,
    lastMessage,
    unreadCount,
    lastActivityAt,
  ];
}

class ConversationPage extends Equatable {
  const ConversationPage(this.items, {this.nextCursor});

  final List<Conversation> items;

  /// Opaco: se devuelve tal cual para la página siguiente.
  final String? nextCursor;

  @override
  List<Object?> get props => [items, nextCursor];
}

/// Un tramo de la historia, del mensaje más viejo al más nuevo.
class MessageHistory extends Equatable {
  const MessageHistory(this.items, {required this.hasMore});

  final List<DirectMessage> items;
  final bool hasMore;

  @override
  List<Object?> get props => [items, hasMore];
}

/// Lo que llega en tiempo real. [unreadConversations] es el total de la
/// sesión: el número del badge.
sealed class DirectMessageEvent extends Equatable {
  const DirectMessageEvent({required this.unreadConversations});

  final int unreadConversations;
}

class DirectMessageReceived extends DirectMessageEvent {
  const DirectMessageReceived(
    this.message, {
    required super.unreadConversations,
  });

  final DirectMessage message;

  @override
  List<Object?> get props => [message, unreadConversations];
}

class ConversationRead extends DirectMessageEvent {
  const ConversationRead({
    required this.conversationId,
    required this.readerId,
    required this.lastReadMessageId,
    required super.unreadConversations,
  });

  final String conversationId;
  final String readerId;
  final String lastReadMessageId;

  @override
  List<Object?> get props => [
    conversationId,
    readerId,
    lastReadMessageId,
    unreadConversations,
  ];
}
