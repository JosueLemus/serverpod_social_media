import 'package:nexo_server/src/modules/messages/services/messages_rules.dart';
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';

void main() {
  final x = UuidValue.fromString('01a12c4d-0000-7000-8000-000000000001');
  final y = UuidValue.fromString('01a12c4d-0000-7000-8000-000000000002');

  group('Given the pair of a conversation', () {
    test('then the same two accounts give the same pair in any order', () {
      expect(MessagesRules.pair(x, y), MessagesRules.pair(y, x));
      expect(MessagesRules.pair(y, x), (x, y));
    });
  });

  group('Given a message body', () {
    test('then it is trimmed', () {
      expect(MessagesRules.body('  hola  '), 'hola');
    });

    test('then empty or blank bodies are rejected', () {
      expect(MessagesRules.body(''), isNull);
      expect(MessagesRules.body('   \n '), isNull);
    });

    test('then up to the limit is accepted and one more is rejected', () {
      expect(MessagesRules.body('a' * MessagesRules.maxBodyLength), isNotNull);
      expect(
        MessagesRules.body('a' * (MessagesRules.maxBodyLength + 1)),
        isNull,
      );
    });
  });

  group('Given unread state', () {
    test('then a conversation without messages has nothing unread', () {
      expect(
        MessagesRules.hasUnread(lastMessageId: null, lastRead: null),
        isFalse,
      );
    });

    test('then a message after the read pointer is unread', () {
      expect(MessagesRules.hasUnread(lastMessageId: 5, lastRead: null), isTrue);
      expect(MessagesRules.hasUnread(lastMessageId: 5, lastRead: 4), isTrue);
      expect(MessagesRules.hasUnread(lastMessageId: 5, lastRead: 5), isFalse);
    });
  });

  group('Given the send throttle', () {
    setUp(MessagesThrottle.instance.reset);

    test('then a second message within a second is refused', () {
      final now = DateTime.utc(2026, 10, 12, 12);
      expect(MessagesThrottle.instance.tryAcquire(x, now), isTrue);
      expect(
        MessagesThrottle.instance.tryAcquire(
          x,
          now.add(const Duration(milliseconds: 500)),
        ),
        isFalse,
      );
      expect(
        MessagesThrottle.instance.tryAcquire(
          x,
          now.add(MessagesRules.cooldown),
        ),
        isTrue,
      );
    });

    test('then each account has its own limit', () {
      final now = DateTime.utc(2026, 10, 12, 12);
      expect(MessagesThrottle.instance.tryAcquire(x, now), isTrue);
      expect(MessagesThrottle.instance.tryAcquire(y, now), isTrue);
    });
  });

  test('then page sizes are clamped', () {
    expect(MessagesRules.pageSize(null), MessagesRules.defaultPageSize);
    expect(MessagesRules.pageSize(0), 1);
    expect(MessagesRules.pageSize(500), MessagesRules.maxPageSize);
  });
}
