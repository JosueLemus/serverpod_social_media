import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_social/core/errors/failures.dart';
import 'package:nexo_social/features/messages/domain/entities/direct_message.dart';
import 'package:nexo_social/features/messages/domain/repositories/messages_repository.dart';
import 'package:nexo_social/features/messages/presentation/bloc/conversation_cubit.dart';

/// Un servidor de mentira controlado por el test: los eventos se empujan a
/// mano, `send` puede fallar a pedido y `send`/`history` se pueden frenar
/// hasta que el test los suelte.
class _FakeRepository implements MessagesRepository {
  final events = StreamController<DirectMessageEvent>.broadcast();
  final stored = <DirectMessage>[];
  var markReadCalls = 0;
  var sendCalls = 0;
  var inFlight = 0;
  var maxInFlight = 0;
  final sentBodies = <String>[];

  /// Falla siempre mientras no sea `null`.
  Failure? sendFailure;

  /// Fallos de una sola vez, en orden, antes de [sendFailure].
  final sendFailures = <Failure>[];

  /// Si no es `null`, cada `send` espera a que el test lo complete.
  Completer<void>? sendGate;

  /// Si no es `null`, `history` espera a que el test lo complete.
  Completer<void>? historyGate;
  Failure? historyFailure;
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
  Future<MessageHistory> history(String id, {String? beforeId}) async {
    await historyGate?.future;
    final failure = historyFailure;
    if (failure != null) throw failure;
    return MessageHistory(List.of(stored), hasMore: false);
  }

  @override
  Future<DirectMessage> send(String id, String body) async {
    sendCalls++;
    inFlight++;
    if (inFlight > maxInFlight) maxInFlight = inFlight;
    try {
      await sendGate?.future;
      if (sendFailures.isNotEmpty) throw sendFailures.removeAt(0);
      final failure = sendFailure;
      if (failure != null) throw failure;
      sentBodies.add(body);
      return DirectMessage(
        id: '${_next++}',
        conversationId: id,
        authorId: 'me',
        body: body,
        createdAt: DateTime(2026),
      );
    } finally {
      inFlight--;
    }
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

  ConversationCubit build() => ConversationCubit(
    repository,
    me: 'me',
    reconnectDelays: const [Duration(milliseconds: 10)],
    rateLimitWait: const Duration(milliseconds: 10),
  );

  setUp(() {
    repository = _FakeRepository()
      ..stored.addAll([
        _message('1', 'elena', 'hola'),
        _message('2', 'me', '¿qué tal?'),
      ]);
    cubit = build();
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

  group('a message that arrives while the history loads', () {
    blocTest<ConversationCubit, ChatState>(
      'is kept and merged after the history',
      build: build,
      act: (cubit) async {
        repository.historyGate = Completer();
        final loading = cubit.load(_FakeRepository.conversationId);
        await pumpEventQueue();
        repository.events.add(
          DirectMessageReceived(
            _message('3', 'elena', 'mientras cargaba'),
            unreadConversations: 1,
          ),
        );
        await pumpEventQueue();
        repository.historyGate!.complete();
        await loading;
      },
      verify: (cubit) {
        expect(cubit.state.status, ChatStatus.ready);
        expect(
          [for (final m in cubit.state.messages) m.body],
          ['hola', '¿qué tal?', 'mientras cargaba'],
        );
      },
    );

    blocTest<ConversationCubit, ChatState>(
      'is not duplicated when the history already has it',
      build: build,
      act: (cubit) async {
        repository.historyGate = Completer();
        final loading = cubit.load(_FakeRepository.conversationId);
        await pumpEventQueue();
        final both = _message('3', 'elena', 'en los dos');
        repository.events.add(
          DirectMessageReceived(both, unreadConversations: 1),
        );
        await pumpEventQueue();
        repository.stored.add(both);
        repository.historyGate!.complete();
        await loading;
      },
      verify: (cubit) => expect(
        cubit.state.messages.where((m) => m.body == 'en los dos'),
        hasLength(1),
      ),
    );
  });

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

  test('the echo that arrives while sending confirms the bubble', () async {
    await cubit.load(_FakeRepository.conversationId);
    repository.sendGate = Completer();

    final sending = cubit.send('rápido');
    await pumpEventQueue();
    repository.events.add(
      DirectMessageReceived(
        _message('100', 'me', 'rápido'),
        unreadConversations: 0,
      ),
    );
    await pumpEventQueue();

    expect(cubit.state.messages.last.id, '100');
    expect(cubit.state.messages.last.delivery, MessageDelivery.sent);

    repository.sendGate!.complete();
    await sending;
    expect(cubit.state.messages.where((m) => m.body == 'rápido'), hasLength(1));
  });

  group('two messages in a row', () {
    blocTest<ConversationCubit, ChatState>(
      'go out one at a time and in order',
      build: build,
      act: (cubit) async {
        await cubit.load(_FakeRepository.conversationId);
        repository.sendGate = Completer();
        final first = cubit.send('uno');
        final second = cubit.send('dos');
        await pumpEventQueue();
        // El segundo espera a que termine el primero.
        expect(repository.sendCalls, 1);
        repository.sendGate!.complete();
        await Future.wait([first, second]);
      },
      verify: (cubit) {
        expect(repository.maxInFlight, 1);
        expect(repository.sentBodies, ['uno', 'dos']);
        expect(
          [for (final m in cubit.state.messages.skip(2)) m.body],
          ['uno', 'dos'],
        );
        expect(
          cubit.state.messages.every((m) => m.delivery == MessageDelivery.sent),
          isTrue,
        );
      },
    );

    blocTest<ConversationCubit, ChatState>(
      'a rateLimited send is retried once on its own and goes through',
      build: build,
      act: (cubit) async {
        await cubit.load(_FakeRepository.conversationId);
        await cubit.send('uno');
        repository.sendFailures.add(const RateLimitedFailure('dm'));
        await cubit.send('dos');
      },
      verify: (cubit) {
        expect(repository.sendCalls, 3);
        expect(cubit.state.messages.last.body, 'dos');
        expect(cubit.state.messages.last.delivery, MessageDelivery.sent);
        expect(cubit.state.issue, isNull);
      },
    );
  });

  test('a failed send stays marked and retry delivers it', () async {
    await cubit.load(_FakeRepository.conversationId);
    repository.sendFailure = const RateLimitedFailure('dm');

    await cubit.send('reintento');
    final failed = cubit.state.messages.last;
    expect(failed.delivery, MessageDelivery.failed);
    expect(cubit.state.issue, ChatIssue.tooFast);
    // El primero y el reintento automático.
    expect(repository.sendCalls, 2);

    repository.sendFailure = null;
    await cubit.retry(failed.id);
    final last = cubit.state.messages.last;
    expect(last.delivery, MessageDelivery.sent);
    expect(last.body, 'reintento');
    expect(
      cubit.state.messages.where((m) => m.body == 'reintento'),
      hasLength(1),
    );
    expect(repository.sendCalls, 3);
  });

  test('a send the server will never accept is not offered to retry', () async {
    await cubit.load(_FakeRepository.conversationId);
    repository.sendFailure = const ForbiddenFailure('dm');

    await cubit.send('no va');
    final rejected = cubit.state.messages.last;
    expect(rejected.delivery, MessageDelivery.rejected);
    expect(cubit.state.issue, ChatIssue.forbidden);

    await cubit.retry(rejected.id);
    expect(repository.sendCalls, 1);
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

  test('if catching up fails it tries again instead of sticking', () async {
    await cubit.load(_FakeRepository.conversationId);
    repository.historyFailure = const NetworkFailure('still down');
    repository.events.addError(const NetworkFailure('drop'));
    await Future<void>.delayed(const Duration(milliseconds: 30));
    await pumpEventQueue();
    expect(cubit.state.reconnecting, isTrue);

    repository.historyFailure = null;
    await Future<void>.delayed(const Duration(milliseconds: 30));
    await pumpEventQueue();
    expect(cubit.state.reconnecting, isFalse);
  });

  test('a forbidden stream is not retried', () async {
    await cubit.load(_FakeRepository.conversationId);
    repository.events.addError(const ForbiddenFailure('session'));
    await pumpEventQueue();
    expect(cubit.state.reconnecting, isFalse);
  });

  test('openWith resolves the conversation with that account', () async {
    await cubit.openWith('elena');
    expect(cubit.state.status, ChatStatus.ready);
    expect(cubit.state.conversation?.id, _FakeRepository.conversationId);
  });
}
