import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_social/core/errors/failures.dart';
import 'package:nexo_social/features/messages/domain/entities/direct_message.dart';
import 'package:nexo_social/features/messages/domain/repositories/messages_repository.dart';
import 'package:nexo_social/features/messages/presentation/bloc/conversation_cubit.dart';

/// Un servidor de mentira controlado por el test: los eventos se empujan a
/// mano y `send` puede fallar a pedido.
class _FakeRepository implements MessagesRepository {
  final events = StreamController<DirectMessageEvent>.broadcast();
  final stored = <DirectMessage>[];
  var markReadCalls = 0;
  var sendCalls = 0;
  Failure? sendFailure;
  var _next = 100;

  static const conversationId = '7';
  static final peer = const ChatPeer(
    id: 'elena',
    username: 'elena',
    name: 'Elena',
  );

  Conversation get conversationView => Conversation(
    id: conversationId,
    peer: peer,
    lastActivityAt: DateTime(2026),
  );

  @override
  Future<Conversation> conversation(String id) async {
    if (id != conversationId) throw const NotFoundFailure('conversation');
    return conversationView;
  }

  @override
  Future<Conversation> open(String userId) async => conversationView;

  @override
  Future<MessageHistory> history(String id, {String? beforeId}) async =>
      MessageHistory(List.of(stored), hasMore: false);

  @override
  Future<DirectMessage> send(String id, String body) async {
    sendCalls++;
    final failure = sendFailure;
    if (failure != null) throw failure;
    return DirectMessage(
      id: '${_next++}',
      conversationId: id,
      authorId: 'me',
      body: body,
      createdAt: DateTime(2026),
    );
  }

  @override
  Future<int> markRead(String id) async {
    markReadCalls++;
    return 0;
  }

  @override
  Stream<DirectMessageEvent> watch() => events.stream;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

DirectMessage _message(String id, String author, String body) => DirectMessage(
  id: id,
  conversationId: _FakeRepository.conversationId,
  authorId: author,
  body: body,
  createdAt: DateTime(2026),
);

void main() {
  late _FakeRepository repository;
  late ConversationCubit cubit;

  setUp(() {
    repository = _FakeRepository()
      ..stored.addAll([
        _message('1', 'elena', 'hola'),
        _message('2', 'me', '¿qué tal?'),
      ]);
    cubit = ConversationCubit(
      repository,
      me: 'me',
      reconnectDelays: const [Duration(milliseconds: 10)],
    );
  });

  tearDown(() async {
    await cubit.close();
    await repository.events.close();
  });

  test('loads the history, oldest first, and marks it read', () async {
    await cubit.load(_FakeRepository.conversationId);
    await pumpEventQueue();

    expect(cubit.state.status, ChatStatus.ready);
    expect(cubit.state.conversation?.peer.name, 'Elena');
    expect(
      [for (final m in cubit.state.messages) m.body],
      ['hola', '¿qué tal?'],
    );
    expect(repository.markReadCalls, 1);
  });

  test('an unknown conversation is not found', () async {
    await cubit.load('999');
    expect(cubit.state.status, ChatStatus.notFound);
  });

  test(
    'a message from the other side arrives in real time and is read',
    () async {
      await cubit.load(_FakeRepository.conversationId);
      repository.events.add(
        DirectMessageReceived(
          _message('3', 'elena', 'llegó'),
          unreadConversations: 1,
        ),
      );
      await pumpEventQueue();

      expect(cubit.state.messages.last.body, 'llegó');
      expect(repository.markReadCalls, 2);
    },
  );

  test('a message from another conversation is ignored', () async {
    await cubit.load(_FakeRepository.conversationId);
    repository.events.add(
      DirectMessageReceived(
        DirectMessage(
          id: '50',
          conversationId: '8',
          authorId: 'elena',
          body: 'otro chat',
          createdAt: DateTime(2026),
        ),
        unreadConversations: 1,
      ),
    );
    await pumpEventQueue();
    expect(
      cubit.state.messages.map((m) => m.body),
      isNot(contains('otro chat')),
    );
  });

  test('sending is optimistic and the echo is not duplicated', () async {
    await cubit.load(_FakeRepository.conversationId);

    final sending = cubit.send('nuevo');
    expect(cubit.state.messages.last.body, 'nuevo');
    expect(cubit.state.messages.last.delivery, MessageDelivery.sending);
    await sending;

    final sent = cubit.state.messages.last;
    expect(sent.delivery, MessageDelivery.sent);
    expect(sent.id, '100');

    // El eco del servidor llega después: no se agrega otra vez.
    repository.events.add(DirectMessageReceived(sent, unreadConversations: 0));
    await pumpEventQueue();
    expect(cubit.state.messages.where((m) => m.body == 'nuevo'), hasLength(1));
  });

  test('a failed send stays marked and retry delivers it', () async {
    await cubit.load(_FakeRepository.conversationId);
    repository.sendFailure = const RateLimitedFailure('dm');

    await cubit.send('reintento');
    final failed = cubit.state.messages.last;
    expect(failed.delivery, MessageDelivery.failed);
    expect(cubit.state.issue, ChatIssue.tooFast);

    repository.sendFailure = null;
    await cubit.retry(failed.id);
    final last = cubit.state.messages.last;
    expect(last.delivery, MessageDelivery.sent);
    expect(last.body, 'reintento');
    expect(
      cubit.state.messages.where((m) => m.body == 'reintento'),
      hasLength(1),
    );
    expect(repository.sendCalls, 2);
  });

  test('when the stream drops it reconnects and catches up', () async {
    await cubit.load(_FakeRepository.conversationId);
    repository.events.addError(const NetworkFailure('drop'));
    await pumpEventQueue();
    expect(cubit.state.reconnecting, isTrue);

    // Lo que llegó durante el corte vuelve con la historia.
    repository.stored.add(_message('4', 'elena', 'durante el corte'));
    await Future<void>.delayed(const Duration(milliseconds: 30));
    await pumpEventQueue();

    expect(cubit.state.reconnecting, isFalse);
    expect(cubit.state.messages.last.body, 'durante el corte');
  });

  test('openWith resolves the conversation with that account', () async {
    await cubit.openWith('elena');
    expect(cubit.state.status, ChatStatus.ready);
    expect(cubit.state.conversation?.id, _FakeRepository.conversationId);
  });
}
