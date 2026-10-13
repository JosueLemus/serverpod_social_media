import 'dart:async';

import 'package:nexo_client/nexo_client.dart' as api;

import '../../../../core/errors/failures.dart';
import '../../../../core/network/serverpod_failures.dart';
import '../../../feed/data/repositories/serverpod_post_repository.dart';
import '../../domain/entities/direct_message.dart';
import '../../domain/repositories/messages_repository.dart';

/// Mensajes directos sobre `client.messages`.
class ServerpodMessagesRepository implements MessagesRepository {
  ServerpodMessagesRepository(this._client);

  final api.Client _client;

  @override
  Future<ConversationPage> conversations({String? cursor}) => _guard(() async {
    final page = await _client.messages.conversations(
      after: ServerpodPostRepository.decodeCursor(cursor),
    );
    return ConversationPage([
      for (final view in page.items) toConversation(view),
    ], nextCursor: ServerpodPostRepository.encodeCursor(page.nextCursor));
  });

  @override
  Future<Conversation> conversation(String conversationId) => _guard(
    () async => toConversation(
      await _client.messages.conversation(_id(conversationId)),
    ),
  );

  @override
  Future<Conversation> open(String userId) => _guard(
    () async => toConversation(await _client.messages.open(_uuid(userId))),
  );

  @override
  Future<MessageHistory> history(String conversationId, {String? beforeId}) =>
      _guard(() async {
        final page = await _client.messages.history(
          _id(conversationId),
          beforeId: beforeId == null ? null : int.tryParse(beforeId),
        );
        return MessageHistory([
          for (final view in page.items) toMessage(view),
        ], hasMore: page.hasMore);
      });

  @override
  Future<DirectMessage> send(String conversationId, String body) =>
      _guard(() async {
        try {
          return toMessage(
            await _client.messages.send(_id(conversationId), body),
          );
        } on api.NexoException catch (error) {
          // El mapeo común deja `invalidInput` en `ServerFailure`, que también
          // es un 500. En un envío es el cuerpo, y reintentarlo igual no sirve:
          // como en el mock, es un `ConflictFailure`.
          if (error.code != api.NexoErrorCode.invalidInput) rethrow;
          throw ConflictFailure(error.message);
        }
      });

  @override
  Future<int> markRead(String conversationId) =>
      _guard(() => _client.messages.markRead(_id(conversationId)));

  @override
  Future<int> unreadCount() => _guard(_client.messages.unreadCount);

  @override
  Stream<DirectMessageEvent> watch() => _client.messages.watch().transform(
    StreamTransformer.fromHandlers(
      handleData: (event, sink) {
        final mapped = toEvent(event);
        if (mapped != null) sink.add(mapped);
      },
      handleError: (error, stackTrace, sink) =>
          sink.addError(failureFromServer(error), stackTrace),
    ),
  );

  // Públicos para los tests.

  static DirectMessage toMessage(api.DirectMessageView view) => DirectMessage(
    id: '${view.id}',
    conversationId: '${view.conversationId}',
    authorId: view.authorId.toString(),
    body: view.body,
    createdAt: view.createdAt,
  );

  static Conversation toConversation(api.ConversationView view) => Conversation(
    id: '${view.id}',
    peer: ChatPeer(
      id: view.other.userId.toString(),
      username: view.other.username,
      name: view.other.displayName,
      avatarUrl: view.other.avatarUrl,
    ),
    lastMessage: view.lastMessage == null ? null : toMessage(view.lastMessage!),
    unreadCount: view.unreadCount,
    lastActivityAt: view.lastActivityAt,
  );

  /// `null` para un evento que esta versión de la app no entiende.
  static DirectMessageEvent? toEvent(api.DirectMessageEvent event) =>
      switch (event.kind) {
        api.DirectMessageEventKind.message when event.message != null =>
          DirectMessageReceived(
            toMessage(event.message!),
            unreadConversations: event.unreadConversations,
          ),
        api.DirectMessageEventKind.read
            when event.readerId != null && event.lastReadMessageId != null =>
          ConversationRead(
            conversationId: '${event.conversationId}',
            readerId: event.readerId.toString(),
            lastReadMessageId: '${event.lastReadMessageId}',
            unreadConversations: event.unreadConversations,
          ),
        _ => null,
      };

  static int _id(String id) =>
      int.tryParse(id) ?? (throw const NotFoundFailure('conversation'));

  static api.UuidValue _uuid(String id) {
    try {
      return api.UuidValue.fromString(id);
    } on FormatException {
      throw const NotFoundFailure('account');
    }
  }

  static Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on Failure {
      rethrow;
    } catch (error) {
      throw failureFromServer(error);
    }
  }
}
