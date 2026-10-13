import 'dart:async';

import '../../../../core/errors/failures.dart';
import '../../../../core/mock/demo_accounts.dart';
import '../../domain/entities/direct_message.dart';
import '../../domain/repositories/messages_repository.dart';

/// Mensajes en memoria para el modo mock y los tests de widgets. Aplica las
/// mismas reglas que el servidor: una conversación por par, sólo miembros,
/// nada vacío ni a uno mismo.
class MockMessagesRepository implements MessagesRepository {
  MockMessagesRepository(this._currentUserId, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  /// La cuenta de la sesión en el mock (`MockPlatform.sessionAccountId`).
  final String? Function() _currentUserId;
  final DateTime Function() _now;

  final _conversations = <String, _Thread>{};
  final _events = StreamController<DirectMessageEvent>.broadcast();
  var _sequence = 0;
  String? _seededFor;

  static const maxBodyLength = 1000;

  @override
  Future<ConversationPage> conversations({String? cursor}) async {
    final me = _me();
    _seed(me);
    final mine =
        _conversations.values
            .where((t) => t.has(me) && t.messages.isNotEmpty)
            .toList()
          ..sort((a, b) => b.lastActivityAt.compareTo(a.lastActivityAt));
    return ConversationPage([for (final t in mine) _view(t, me)]);
  }

  @override
  Future<Conversation> conversation(String conversationId) async {
    final me = _me();
    _seed(me);
    return _view(_member(conversationId, me), me);
  }

  @override
  Future<Conversation> open(String userId) async {
    final me = _me();
    if (userId == me) throw const ConflictFailure('dm: yourself');
    if (_account(userId) == null) throw const NotFoundFailure('account');
    _seed(me);
    final existing = _conversations.values.where(
      (t) => t.has(me) && t.has(userId),
    );
    final thread = existing.isNotEmpty
        ? existing.first
        : (_conversations['${++_sequence}'] = _Thread(
            id: '$_sequence',
            a: me,
            b: userId,
            lastActivityAt: _now(),
          ));
    return _view(thread, me);
  }

  @override
  Future<MessageHistory> history(
    String conversationId, {
    String? beforeId,
  }) async {
    final thread = _member(conversationId, _me());
    final all = thread.messages;
    final end = beforeId == null
        ? all.length
        : all.indexWhere((m) => m.id == beforeId).clamp(0, all.length);
    const page = 30;
    final start = (end - page).clamp(0, end);
    return MessageHistory(all.sublist(start, end), hasMore: start > 0);
  }

  @override
  Future<DirectMessage> send(String conversationId, String body) async {
    final me = _me();
    final thread = _member(conversationId, me);
    final text = body.trim();
    if (text.isEmpty || text.length > maxBodyLength) {
      throw const ConflictFailure('dm: invalid body');
    }
    final message = _append(thread, me, text);
    thread.readBy[me] = message.id;
    _events.add(
      DirectMessageReceived(message, unreadConversations: _unread(me)),
    );
    return message;
  }

  @override
  Future<int> markRead(String conversationId) async {
    final me = _me();
    final thread = _member(conversationId, me);
    final last = thread.messages.lastOrNull;
    // Como el servidor: el evento sale sólo si el puntero se movió.
    if (last != null && thread.readBy[me] != last.id) {
      thread.readBy[me] = last.id;
      _events.add(
        ConversationRead(
          conversationId: thread.id,
          readerId: me,
          lastReadMessageId: last.id,
          unreadConversations: _unread(me),
        ),
      );
    }
    return _unread(me);
  }

  @override
  Future<int> unreadCount() async {
    final me = _currentUserId();
    if (me == null) return 0;
    _seed(me);
    return _unread(me);
  }

  @override
  Stream<DirectMessageEvent> watch() => _events.stream;

  /// Para los tests: un mensaje que llega de [authorId], como si lo hubiera
  /// mandado desde otro dispositivo.
  void deliver(String conversationId, String authorId, String body) {
    final thread = _conversations[conversationId]!;
    final message = _append(thread, authorId, body);
    final me = _currentUserId();
    _events.add(
      DirectMessageReceived(
        message,
        unreadConversations: me == null ? 0 : _unread(me),
      ),
    );
  }

  // --- Internos ----------------------------------------------------------

  String _me() =>
      _currentUserId() ?? (throw const ForbiddenFailure('unauthenticated'));

  _Thread _member(String conversationId, String me) {
    final thread = _conversations[conversationId];
    if (thread == null) throw const NotFoundFailure('conversation');
    if (!thread.has(me)) throw const ForbiddenFailure('dm: not a member');
    return thread;
  }

  DirectMessage _append(_Thread thread, String authorId, String body) {
    final message = DirectMessage(
      id: '${++_sequence}',
      conversationId: thread.id,
      authorId: authorId,
      body: body,
      createdAt: _now(),
    );
    thread.messages.add(message);
    thread.lastActivityAt = message.createdAt;
    return message;
  }

  int _unread(String me) => _conversations.values
      .where((t) => t.has(me) && t.unreadFor(me) > 0)
      .length;

  /// Una conversación de ejemplo con la otra cuenta de demo, con el último
  /// mensaje sin leer: la bandeja del mock no arranca vacía.
  void _seed(String me) {
    if (_seededFor == me) return;
    _seededFor = me;
    final peer = me == DemoAccounts.elena.id
        ? DemoAccounts.viewer
        : DemoAccounts.elena;
    if (_conversations.values.any((t) => t.has(me) && t.has(peer.id))) return;
    final thread = _Thread(
      id: '${++_sequence}',
      a: me,
      b: peer.id,
      lastActivityAt: _now(),
    );
    _conversations[thread.id] = thread;
    _append(thread, me, '¡Hola! ¿Cómo va todo?');
    thread.readBy[me] = thread.messages.last.id;
    _append(thread, peer.id, '¡Todo bien! ¿Viste el vivo de anoche?');
  }

  DemoAccount? _account(String id) {
    for (final account in DemoAccounts.all) {
      if (account.id == id) return account;
    }
    return null;
  }

  Conversation _view(_Thread thread, String me) {
    final peerId = thread.a == me ? thread.b : thread.a;
    final peer = _account(peerId);
    return Conversation(
      id: thread.id,
      peer: ChatPeer(
        id: peerId,
        username: peer?.username ?? peerId,
        name: peer?.name ?? peerId,
      ),
      lastMessage: thread.messages.isEmpty ? null : thread.messages.last,
      unreadCount: thread.unreadFor(me),
      lastActivityAt: thread.lastActivityAt,
    );
  }
}

class _Thread {
  _Thread({
    required this.id,
    required this.a,
    required this.b,
    required this.lastActivityAt,
  });

  final String id;
  final String a;
  final String b;
  DateTime lastActivityAt;
  final messages = <DirectMessage>[];

  /// El id del último mensaje que leyó cada miembro.
  final readBy = <String, String>{};

  bool has(String userId) => a == userId || b == userId;

  int unreadFor(String me) {
    final read = readBy[me];
    final from = read == null
        ? 0
        : messages.indexWhere((m) => m.id == read) + 1;
    return messages.skip(from).where((m) => m.authorId != me).length;
  }
}
