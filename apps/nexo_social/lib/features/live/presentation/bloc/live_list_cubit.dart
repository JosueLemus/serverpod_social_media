import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/live_session.dart';
import '../../domain/repositories/live_repository.dart';

sealed class LiveListState extends Equatable {
  const LiveListState();

  @override
  List<Object?> get props => const [];
}

class LiveListLoading extends LiveListState {
  const LiveListLoading();
}

class LiveListLoaded extends LiveListState {
  const LiveListLoaded(this.sessions);

  final List<LiveSession> sessions;

  @override
  List<Object?> get props => [sessions];
}

/// A failed read is its own state. Without it the screen can only show a
/// spinner forever, which is how a dead endpoint looks identical to a slow one.
class LiveListFailure extends LiveListState {
  const LiveListFailure();
}

class LiveListCubit extends Cubit<LiveListState> {
  LiveListCubit(this._repository) : super(const LiveListLoading());

  final LiveRepository _repository;

  Future<void> load() async {
    emit(const LiveListLoading());
    try {
      emit(LiveListLoaded(await _repository.list()));
    } catch (_) {
      emit(const LiveListFailure());
    }
  }
}
