import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_social/core/mock/demo_accounts.dart';
import 'package:nexo_social/features/messages/data/repositories/mock_messages_repository.dart';
import 'package:nexo_social/features/messages/domain/entities/direct_message.dart';

void main() {
  test('marking read announces it, like the server does', () async {
    final repository = MockMessagesRepository(() => DemoAccounts.viewer.id);
    final inbox = await repository.conversations();
    final conversation = inbox.items.single;
    expect(conversation.unreadCount, 1);

    final read = expectLater(
      repository.watch(),
      emits(
        isA<ConversationRead>()
            .having((e) => e.conversationId, 'conversation', conversation.id)
            .having((e) => e.readerId, 'reader', DemoAccounts.viewer.id)
            .having(
              (e) => e.lastReadMessageId,
              'last read',
              conversation.lastMessage!.id,
            )
            .having((e) => e.unreadConversations, 'unread', 0),
      ),
    );
    expect(await repository.markRead(conversation.id), 0);
    await read;
  });
}
