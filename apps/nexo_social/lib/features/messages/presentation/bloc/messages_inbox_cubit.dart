import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/direct_message.dart';
import '../../domain/repositories/messages_repository.dart';

enum InboxStatus { loading, ready, failure }

class InboxState extends Equatable {
  const InboxState({
    this.status = InboxStatus.loading,
    this.conversations = const [],
    this.nextCursor,
    this.loadingMore = false,
  });

  final InboxStatus status;
  final List<Conversation> conversations;
  final String? nextCursor;
  final bool loadingMore;

  bool get isEmpty => status == InboxStatus.ready && conversations.isEmpty;

  InboxState copyWith({
    InboxStatus? status,
    List<Conversation>? conversations,
    String? Function()? nextCursor,
    bool? loadingMore,
  }) => InboxState(
    status: status ?? this.status,
    conversations: conversations ?? this.conversations,
    nextCursor: nextCursor == null ? this.nextCursor : nextCursor(),
    loadingMore: loadingMore ?? this.loadingMore,
  );

  @override
  List<Object?> get props => [status, conversations, nextCursor, loadingMore];
}

/// La bandeja. Un mensaje nuevo en cualquier conversación la vuelve a pedir:
/// el servidor ordena y cuenta, y la bandeja no duplica esas reglas.
///
/// Si el stream se corta, se vuelve a suscribir con espera creciente y pide
/// la bandeja otra vez: lo que llegó durante el corte no vino por el stream.
class MessagesInboxCubit extends Cubit<InboxState> {
  MessagesInboxCubit(
    this._repository, {
    this.reconnectDelays = defaultReconnectDelays,
  }) : super(const InboxState());

  final MessagesRepository _repository;
  final List<Duration> reconnectDelays;

  static const defaultReconnectDelays = [
    Duration(seconds: 1),
    Duration(seconds: 2),
    Duration(seconds: 5),
  ];

  StreamSubscription<DirectMessageEvent>? _live;
  Timer? _reconnect;
  int _attempt = 0;

  Future<void> load() async {
    if (_live == null && !(_reconnect?.isActive ?? false)) _listen();
    await _reload(showLoading: state.status != InboxStatus.ready);
  }

  Future<void> refresh() => _reload();

  Future<void> loadMore() async {
    final cursor = state.nextCursor;
    if (cursor == null || state.loadingMore) return;
    emit(state.copyWith(loadingMore: true));
    try {
      final page = await _repository.conversations(cursor: cursor);
      if (isClosed) return;
      emit(
        state.copyWith(
          conversations: [...state.conversations, ...page.items],
          nextCursor: () => page.nextCursor,
          loadingMore: false,
        ),
      );
    } on Failure {
      if (!isClosed) emit(state.copyWith(loadingMore: false));
    }
  }

  Future<void> _reload({bool showLoading = false}) async {
    if (showLoading) emit(state.copyWith(status: InboxStatus.loading));
    try {
      final page = await _repository.conversations();
      if (isClosed) return;
      emit(
        state.copyWith(
          status: InboxStatus.ready,
          conversations: page.items,
          nextCursor: () => page.nextCursor,
        ),
      );
    } on Failure {
      if (isClosed) return;
      // Con la lista ya dibujada, un refresco que falla no la borra.
      if (state.status != InboxStatus.ready) {
        emit(state.copyWith(status: InboxStatus.failure));
      }
    }
  }

  void _listen() {
    unawaited(_live?.cancel());
    _live = _repository.watch().listen(
      (_) {
        if (isClosed) return;
        _attempt = 0;
        unawaited(_reload());
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
    final delay =
        reconnectDelays[_attempt.clamp(0, reconnectDelays.length - 1)];
    _attempt++;
    _reconnect = Timer(delay, () {
      if (isClosed) return;
      _listen();
      unawaited(_reload());
    });
  }

  @override
  Future<void> close() async {
    _reconnect?.cancel();
    await _live?.cancel();
    return super.close();
  }
}
