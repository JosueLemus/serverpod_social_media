import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/live_session.dart';
import '../../domain/repositories/live_repository.dart';

sealed class LiveListState {
  const LiveListState();
}

class LiveListLoading extends LiveListState {
  const LiveListLoading();
}

class LiveListLoaded extends LiveListState {
  const LiveListLoaded(this.sessions);
  final List<LiveSession> sessions;
}

class LiveListCubit extends Cubit<LiveListState> {
  LiveListCubit(this._repository) : super(const LiveListLoading());
  final LiveRepository _repository;
  Future<void> load() async => emit(LiveListLoaded(await _repository.list()));
}
