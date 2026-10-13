import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/direct_message.dart';
import '../../domain/repositories/messages_repository.dart';

enum ChatStatus { loading, ready, notFound, failure }

/// Por qué no se pudo mandar o abrir. La View lo traduce.
///
/// [tooFast] y [unavailable] se pueden reintentar; los demás no.
enum ChatIssue { forbidden, suspended, invalid, tooFast, unavailable }

class ChatState extends Equatable {
  const ChatState({
    this.status = ChatStatus.loading,
    this.conversation,
    this.messages = const [],
    this.hasMore = false,
    this.loadingOlder = false,
    this.reconnecting = false,
    this.issue,
    this.issueSerial = 0,
  });

  final ChatStatus status;
  final Conversation? conversation;

  /// Del más viejo al más nuevo, con los propios pendientes al final.
  final List<DirectMessage> messages;
  final bool hasMore;
  final bool loadingOlder;
  final bool reconnecting;
  final ChatIssue? issue;
  final int issueSerial;

  ChatState copyWith({
    ChatStatus? status,
    Conversation? conversation,
    List<DirectMessage>? messages,
    bool? hasMore,
    bool? loadingOlder,
    bool? reconnecting,
    ChatIssue? issue,
    int? issueSerial,
  }) => ChatState(
    status: status ?? this.status,
    conversation: conversation ?? this.conversation,
    messages: messages ?? this.messages,
    hasMore: hasMore ?? this.hasMore,
    loadingOlder: loadingOlder ?? this.loadingOlder,
    reconnecting: reconnecting ?? this.reconnecting,
    issue: issue ?? this.issue,
    issueSerial: issueSerial ?? this.issueSerial,
  );

  @override
  List<Object?> get props => [
    status,
    conversation,
    messages,
    hasMore,
    loadingOlder,
    reconnecting,
    issue,
    issueSerial,
  ];
}

/// Una conversación abierta: la historia, lo que llega en el momento y lo
/// que la cuenta [me] manda.
///
/// Mandar es optimista: el mensaje aparece al toque como "enviando" y, si el
/// servidor lo rechaza, queda marcado para reintentar. El eco que llega por
/// el stream se reconoce por id y no se duplica.
///
/// Los envíos salen de a uno, en el orden en que se escribieron: el servidor
/// admite un mensaje por segundo por cuenta (SDD 0010, M9), así que un
/// `rateLimited` se reintenta solo una vez, pasada [rateLimitWait], antes de
/// marcar el mensaje como fallido.
class ConversationCubit extends Cubit<ChatState> {
  ConversationCubit(
    this._repository, {
    required this.me,
    DateTime Function()? now,
    this.reconnectDelays = defaultReconnectDelays,
    this.rateLimitWait = defaultRateLimitWait,
    this.onUnreadChanged,
  }) : _now = now ?? DateTime.now,
       super(const ChatState());

  final MessagesRepository _repository;

  /// La cuenta de la sesión: lo propio se dibuja del otro lado.
  final String me;
  final DateTime Function() _now;
  final List<Duration> reconnectDelays;

  /// Cuánto esperar antes de reintentar un envío que salió demasiado rápido.
  final Duration rateLimitWait;

  /// Lo que devolvió `markRead`, para el badge de la barra.
  final void Function(int unreadConversations)? onUnreadChanged;

  static const defaultReconnectDelays = [
    Duration(seconds: 1),
    Duration(seconds: 2),
    Duration(seconds: 5),
  ];

  /// La ventana del servidor (un segundo) y un margen por la latencia.
  static const defaultRateLimitWait = Duration(milliseconds: 1100);

  StreamSubscription<DirectMessageEvent>? _live;
  Timer? _reconnect;
  int _attempt = 0;
  int _localSequence = 0;

  /// La conversación que filtra el stream. Se fija antes de pedir la
  /// historia: en ese momento `state.conversation` todavía es `null`.
  String? _watching;

  /// Lo que llegó por el stream antes de que la historia estuviera. Se une
  /// por id cuando llega.
  final _early = <DirectMessage>[];
  bool _historyApplied = false;

  /// La cola de envíos: cada uno sale cuando terminó el anterior.
  Future<void> _outbox = Future.value();

  String? get _conversationId => state.conversation?.id;

  /// Abre la conversación con [userId] (desde un perfil): la crea si hacía
  /// falta y la carga.
  Future<void> openWith(String userId) async {
    emit(state.copyWith(status: ChatStatus.loading));
    try {
      final conversation = await _repository.open(userId);
      if (isClosed) return;
      await _start(conversation);
    } on Failure catch (failure) {
      _failLoad(failure);
    }
  }

  Future<void> load(String conversationId) async {
    emit(state.copyWith(status: ChatStatus.loading));
    try {
      final conversation = await _repository.conversation(conversationId);
      if (isClosed) return;
      await _start(conversation);
    } on Failure catch (failure) {
      _failLoad(failure);
    }
  }

  Future<void> _start(Conversation conversation) async {
    // El stream antes que la historia: lo que llegue mientras tanto se
    // guarda aparte, y el merge por id evita duplicarlo.
    _watching = conversation.id;
    _historyApplied = false;
    _early.clear();
    _listen();
    final history = await _repository.history(conversation.id);
    if (isClosed) return;
    final messages = _merge(_merge(state.messages, history.items), _early);
    _early.clear();
    _historyApplied = true;
    emit(
      state.copyWith(
        status: ChatStatus.ready,
        conversation: conversation,
        messages: messages,
        hasMore: history.hasMore,
      ),
    );
    unawaited(_markRead());
  }

  void _failLoad(Failure failure) {
    if (isClosed) return;
    emit(
      state.copyWith(
        status: switch (failure) {
          NotFoundFailure() || ForbiddenFailure() => ChatStatus.notFound,
          _ => ChatStatus.failure,
        },
        issue: _issueOf(failure),
        issueSerial: state.issueSerial + 1,
      ),
    );
  }

  Future<void> loadOlder() async {
    final id = _conversationId;
    final oldest = state.messages.where((m) => !_isLocal(m)).firstOrNull;
    if (id == null || oldest == null || !state.hasMore || state.loadingOlder) {
      return;
    }
    emit(state.copyWith(loadingOlder: true));
    try {
      final page = await _repository.history(id, beforeId: oldest.id);
      if (isClosed) return;
      emit(
        state.copyWith(
          messages: _merge(state.messages, page.items),
          hasMore: page.hasMore,
          loadingOlder: false,
        ),
      );
    } on Failure {
      if (!isClosed) emit(state.copyWith(loadingOlder: false));
    }
  }

  /// Optimista: aparece al toque y se confirma o se marca para reintentar.
  Future<void> send(String text) async {
    final id = _conversationId;
    final body = text.trim();
    if (id == null || body.isEmpty) return;
    final local = DirectMessage(
      id: 'local-${++_localSequence}',
      conversationId: id,
      authorId: me,
      body: body,
      createdAt: _now(),
      delivery: MessageDelivery.sending,
    );
    emit(state.copyWith(messages: [...state.messages, local]));
    await _enqueue(local);
  }

  /// Vuelve a mandar un mensaje que quedó en [MessageDelivery.failed].
  Future<void> retry(String localId) async {
    final failed = state.messages.where((m) => m.id == localId).firstOrNull;
    if (failed == null || failed.delivery != MessageDelivery.failed) return;
    final sending = failed.copyWith(delivery: MessageDelivery.sending);
    emit(state.copyWith(messages: _replace(localId, sending)));
    await _enqueue(sending);
  }

  /// Pone [local] al final de la cola. Dos envíos en paralelo chocan con el
  /// límite del servidor y pueden llegar en otro orden.
  Future<void> _enqueue(DirectMessage local) {
    final turn = _outbox.then((_) => _deliver(local));
    _outbox = turn.then<void>((_) {}, onError: (Object _) {});
    return turn;
  }

  Future<void> _deliver(DirectMessage local, {bool retried = false}) async {
    // El eco lo pudo haber confirmado mientras esperaba su turno.
    if (isClosed || !_isPending(local.id)) return;
    try {
      final sent = await _repository.send(local.conversationId, local.body);
      if (isClosed) return;
      // Por id: si el eco ya llegó, el merge no lo duplica.
      emit(
        state.copyWith(
          messages: _merge(
            [
              for (final m in state.messages)
                if (m.id != local.id) m,
            ],
            [sent],
          ),
        ),
      );
    } on RateLimitedFailure catch (failure) {
      if (isClosed) return;
      if (retried) {
        _fail(local, failure);
        return;
      }
      await Future<void>.delayed(rateLimitWait);
      await _deliver(local, retried: true);
    } on Failure catch (failure) {
      if (!isClosed) _fail(local, failure);
    }
  }

  void _fail(DirectMessage local, Failure failure) {
    // Si el eco ya lo confirmó, el servidor lo tiene: no hay nada que avisar.
    if (!_isPending(local.id)) return;
    emit(
      state.copyWith(
        messages: _replace(
          local.id,
          local.copyWith(
            delivery: _isFinal(failure)
                ? MessageDelivery.rejected
                : MessageDelivery.failed,
          ),
        ),
        issue: _issueOf(failure),
        issueSerial: state.issueSerial + 1,
      ),
    );
  }

  bool _isPending(String localId) => state.messages.any((m) => m.id == localId);

  void _listen() {
    unawaited(_live?.cancel());
    _live = _repository.watch().listen(
      (event) {
        if (isClosed) return;
        _attempt = 0;
        if (state.reconnecting) emit(state.copyWith(reconnecting: false));
        if (event case DirectMessageReceived(
          :final message,
        ) when message.conversationId == _watching) {
          // La historia todavía no llegó: se une con ella.
          if (!_historyApplied) {
            _early.add(message);
            return;
          }
          if (state.messages.any((m) => m.id == message.id)) return;
          // El eco de uno propio que sigue "enviando" lo confirma. El más
          // viejo con el mismo texto, porque los envíos salen en orden.
          final pending = message.authorId == me
              ? state.messages
                    .where(
                      (m) =>
                          _isLocal(m) &&
                          m.body == message.body &&
                          m.delivery == MessageDelivery.sending,
                    )
                    .firstOrNull
              : null;
          emit(
            state.copyWith(
              messages: _merge(
                [
                  for (final m in state.messages)
                    if (m.id != pending?.id) m,
                ],
                [message],
              ),
            ),
          );
          if (message.authorId != me) unawaited(_markRead());
        }
      },
      onError: (Object error) {
        // Sin permiso, reintentar no lo arregla.
        if (isClosed || error is ForbiddenFailure) return;
        _scheduleReconnect();
      },
      onDone: () {
        if (!isClosed) _scheduleReconnect();
      },
      cancelOnError: false,
    );
  }

  void _scheduleReconnect() {
    if (isClosed || (_reconnect?.isActive ?? false)) return;
    unawaited(_live?.cancel());
    _live = null;
    emit(state.copyWith(reconnecting: true));
    final delay =
        reconnectDelays[_attempt.clamp(0, reconnectDelays.length - 1)];
    _attempt++;
    _reconnect = Timer(delay, () async {
      if (isClosed) return;
      _listen();
      // Lo que llegó durante el corte no vino por el stream.
      final id = _conversationId;
      if (id == null) return;
      try {
        final latest = await _repository.history(id);
        if (isClosed) return;
        emit(
          state.copyWith(
            messages: _merge(state.messages, latest.items),
            reconnecting: false,
          ),
        );
        unawaited(_markRead());
      } on Failure {
        // Sin la historia del corte el aviso no se puede sacar: otra vuelta.
        if (!isClosed) _scheduleReconnect();
      }
    });
  }

  Future<void> _markRead() async {
    final id = _conversationId;
    if (id == null) return;
    try {
      final remaining = await _repository.markRead(id);
      onUnreadChanged?.call(remaining);
    } on Failure {
      // Marcar leído es de mejor esfuerzo: el badge se corrige solo.
    }
  }

  /// Une por id y ordena: primero los confirmados por id, al final los
  /// locales en el orden en que se escribieron.
  List<DirectMessage> _merge(
    List<DirectMessage> current,
    List<DirectMessage> incoming,
  ) {
    final byId = {for (final m in current) m.id: m};
    for (final m in incoming) {
      byId[m.id] = m;
    }
    final confirmed = byId.values.where((m) => !_isLocal(m)).toList()
      ..sort((a, b) => _numeric(a.id).compareTo(_numeric(b.id)));
    final local = byId.values.where(_isLocal);
    return [...confirmed, ...local];
  }

  List<DirectMessage> _replace(String id, DirectMessage next) => [
    for (final m in state.messages) m.id == id ? next : m,
  ];

  static bool _isLocal(DirectMessage m) => m.id.startsWith('local-');

  static int _numeric(String id) => int.tryParse(id) ?? 0;

  static ChatIssue _issueOf(Failure failure) => switch (failure) {
    ForbiddenFailure() || NotFoundFailure() => ChatIssue.forbidden,
    AccountSuspendedFailure() => ChatIssue.suspended,
    ConflictFailure() => ChatIssue.invalid,
    RateLimitedFailure() => ChatIssue.tooFast,
    _ => ChatIssue.unavailable,
  };

  /// Un rechazo que reintentar no cambia: el mensaje queda sin reintento.
  static bool _isFinal(Failure failure) => switch (failure) {
    ForbiddenFailure() ||
    NotFoundFailure() ||
    AccountSuspendedFailure() ||
    ConflictFailure() => true,
    _ => false,
  };

  @override
  Future<void> close() async {
    _reconnect?.cancel();
    await _live?.cancel();
    return super.close();
  }
}
