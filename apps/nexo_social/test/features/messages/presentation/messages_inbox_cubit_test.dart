import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_social/core/errors/failures.dart';
import 'package:nexo_social/features/messages/domain/entities/direct_message.dart';
import 'package:nexo_social/features/messages/domain/repositories/messages_repository.dart';
import 'package:nexo_social/features/messages/presentation/bloc/messages_inbox_cubit.dart';

/// La bandeja del servidor de mentira: el test cambia lo que devuelve y
/// empuja eventos o cortes por el stream.
class _FakeRepository implements MessagesRepository {
  final events = StreamController<DirectMessageEvent>.broadcast();
  var items = <Conversation>[];
  var conversationsCalls = 0;
  var watchCalls = 0;

  @override
  Future<ConversationPage> conversations({String? cursor}) async {
    conversationsCalls++;
    return ConversationPage(List.of(items));
  }

  @override
  Stream<DirectMessageEvent> watch() {
    watchCalls++;
    return events.stream;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Conversation _conversation(String id, String body) => Conversation(
  id: id,
  peer: ChatPeer(id: 'p$id', username: 'p$id', name: 'Persona $id'),
  lastMessage: DirectMessage(
    id: '1$id',
    conversationId: id,
    authorId: 'p$id',
    body: body,
    createdAt: DateTime(2026),
  ),
  lastActivityAt: DateTime(2026),
);

DirectMessageReceived _received(String conversationId) => DirectMessageReceived(
  DirectMessage(
    id: '99',
    conversationId: conversationId,
    authorId: 'p$conversationId',
    body: 'nuevo',
    createdAt: DateTime(2026),
  ),
  unreadConversations: 1,
);

void main() {
  late _FakeRepository repository;

  MessagesInboxCubit build() => MessagesInboxCubit(
    repository,
    reconnectDelays: const [Duration(milliseconds: 10)],
  );

  setUp(() {
    repository = _FakeRepository()..items = [_conversation('1', 'hola')];
  });

  tearDown(() => repository.events.close());

  blocTest<MessagesInboxCubit, InboxState>(
    'a new message anywhere reloads the inbox',
    build: build,
    act: (cubit) async {
      await cubit.load();
      repository.items = [_conversation('2', 'otra'), ...repository.items];
      repository.events.add(_received('2'));
      await pumpEventQueue();
    },
    verify: (cubit) =>
        expect([for (final c in cubit.state.conversations) c.id], ['2', '1']),
  );

  blocTest<MessagesInboxCubit, InboxState>(
    'after a network cut it reconnects, catches up and keeps updating',
    build: build,
    act: (cubit) async {
      await cubit.load();
      repository.events.addError(const NetworkFailure('drop'));
      // Lo que llegó durante el corte vuelve con la recarga.
      repository.items = [_conversation('2', 'durante el corte')];
      await Future<void>.delayed(const Duration(milliseconds: 30));
      await pumpEventQueue();
      expect(repository.watchCalls, 2);
      expect(cubit.state.conversations.single.id, '2');

      // Y el stream nuevo sigue moviendo la bandeja.
      repository.items = [_conversation('3', 'después')];
      repository.events.add(_received('3'));
      await pumpEventQueue();
    },
    verify: (cubit) =>
        expect(cubit.state.conversations.single.lastMessage?.body, 'después'),
  );

  blocTest<MessagesInboxCubit, InboxState>(
    'when the stream closes it subscribes again',
    build: build,
    act: (cubit) async {
      await cubit.load();
      await repository.events.close();
      await Future<void>.delayed(const Duration(milliseconds: 30));
      await pumpEventQueue();
    },
    verify: (_) => expect(repository.watchCalls, greaterThan(1)),
  );

  blocTest<MessagesInboxCubit, InboxState>(
    'a forbidden stream is not retried',
    build: build,
    act: (cubit) async {
      await cubit.load();
      repository.events.addError(const ForbiddenFailure('session'));
      await Future<void>.delayed(const Duration(milliseconds: 30));
    },
    verify: (_) => expect(repository.watchCalls, 1),
  );

  test('closing cancels a pending reconnect', () async {
    final cubit = build();
    await cubit.load();
    repository.events.addError(const NetworkFailure('drop'));
    await pumpEventQueue();
    await cubit.close();
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(repository.watchCalls, 1);
  });
}
