import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_client/nexo_client.dart' as api;
import 'package:nexo_social/features/messages/data/repositories/serverpod_messages_repository.dart';
import 'package:nexo_social/features/messages/domain/entities/direct_message.dart';

void main() {
  final elena = api.UuidValue.fromString(
    '01a12c4d-0000-7000-8000-000000000001',
  );
  final tomas = api.UuidValue.fromString(
    '01a12c4d-0000-7000-8000-000000000002',
  );
  final at = DateTime.utc(2026, 10, 12, 12);

  api.DirectMessageView message(int id) => api.DirectMessageView(
    id: id,
    conversationId: 7,
    authorId: tomas,
    body: 'hola',
    createdAt: at,
  );

  test('a conversation maps the other member, the last message and unread', () {
    final view = api.ConversationView(
      id: 7,
      other: api.ProfileView(
        userId: elena,
        username: 'elena_ux',
        displayName: 'Elena Vega',
        avatarUrl: 'https://cdn/elena.png',
        isCreator: true,
        verification: api.VerificationStatus.verified,
        status: api.AccountStatus.active,
        createdAt: at,
      ),
      lastMessage: message(3),
      unreadCount: 2,
      lastActivityAt: at,
    );

    final conversation = ServerpodMessagesRepository.toConversation(view);
    expect(conversation.id, '7');
    expect(conversation.peer.id, elena.toString());
    expect(conversation.peer.username, 'elena_ux');
    expect(conversation.peer.avatarUrl, 'https://cdn/elena.png');
    expect(conversation.lastMessage?.id, '3');
    expect(conversation.lastMessage?.authorId, tomas.toString());
    expect(conversation.unreadCount, 2);
  });

  test('events map to received and read, and unknown ones are dropped', () {
    final received = ServerpodMessagesRepository.toEvent(
      api.DirectMessageEvent(
        kind: api.DirectMessageEventKind.message,
        conversationId: 7,
        message: message(4),
        unreadConversations: 1,
      ),
    );
    expect(received, isA<DirectMessageReceived>());
    expect((received! as DirectMessageReceived).message.id, '4');
    expect(received.unreadConversations, 1);

    final read = ServerpodMessagesRepository.toEvent(
      api.DirectMessageEvent(
        kind: api.DirectMessageEventKind.read,
        conversationId: 7,
        readerId: elena,
        lastReadMessageId: 4,
        unreadConversations: 0,
      ),
    );
    expect(read, isA<ConversationRead>());
    expect((read! as ConversationRead).readerId, elena.toString());

    // Un `message` sin mensaje no se puede dibujar.
    expect(
      ServerpodMessagesRepository.toEvent(
        api.DirectMessageEvent(
          kind: api.DirectMessageEventKind.message,
          conversationId: 7,
          unreadConversations: 0,
        ),
      ),
      isNull,
    );
  });
}
