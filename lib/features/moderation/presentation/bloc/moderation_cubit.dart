import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/moderation_action.dart';
import '../../domain/repositories/moderation_repository.dart';

sealed class ModerationState {
  const ModerationState();
}

class ModerationLoading extends ModerationState {
  const ModerationLoading();
}

class ModerationLoaded extends ModerationState {
  const ModerationLoaded(this.actions);
  final List<ModerationAction> actions;
}

class ModerationCubit extends Cubit<ModerationState> {
  ModerationCubit(this._repository) : super(const ModerationLoading());
  final ModerationRepository _repository;
  Future<void> load() async => emit(ModerationLoaded(await _repository.list()));
  Future<void> act(
    ModerationType type,
    String target, {
    String reason = 'Incumple las normas de la comunidad',
  }) async {
    await _repository.create(type, target, reason);
    await load();
  }
}
