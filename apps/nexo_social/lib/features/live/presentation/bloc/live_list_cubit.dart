import 'dart:async';

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
  StreamSubscription<void>? _changes;

  Future<void> load() async {
    emit(const LiveListLoading());
    try {
      emit(LiveListLoaded(await _repository.list()));
    } catch (_) {
      emit(const LiveListFailure());
    }
    // Un vivo que empieza en otro dispositivo aparece acá sin recargar.
    _changes ??= _repository.changes().listen((_) => unawaited(_refresh()));
  }

  /// Sin pasar por `Loading`: la fila de vivos no parpadea cada vez que
  /// alguien entra o sale del aire. Si falla, queda lo que había.
  Future<void> _refresh() async {
    try {
      final sessions = await _repository.list();
      if (!isClosed) emit(LiveListLoaded(sessions));
    } catch (_) {}
  }

  @override
  Future<void> close() async {
    await _changes?.cancel();
    return super.close();
  }
}
