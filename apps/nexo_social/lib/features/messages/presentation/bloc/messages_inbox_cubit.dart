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
class MessagesInboxCubit extends Cubit<InboxState> {
  MessagesInboxCubit(this._repository) : super(const InboxState());

  final MessagesRepository _repository;
  StreamSubscription<DirectMessageEvent>? _live;

  Future<void> load() async {
    _live ??= _repository.watch().listen(
      (_) => unawaited(_reload()),
      onError: (Object _) {},
      cancelOnError: false,
    );
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

  @override
  Future<void> close() async {
    await _live?.cancel();
    return super.close();
  }
}
