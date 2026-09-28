import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/moderation_action.dart';
import '../../domain/repositories/moderation_repository.dart';

class ModerationState extends Equatable {
  const ModerationState({
    this.reports = const [],
    this.actions = const [],
    this.isLoading = true,
  });

  final List<ModerationReport> reports;
  final List<ModerationAction> actions;
  final bool isLoading;

  ModerationState copyWith({
    List<ModerationReport>? reports,
    List<ModerationAction>? actions,
    bool? isLoading,
  }) => ModerationState(
    reports: reports ?? this.reports,
    actions: actions ?? this.actions,
    isLoading: isLoading ?? this.isLoading,
  );

  @override
  List<Object?> get props => [reports, actions, isLoading];
}

class ModerationCubit extends Cubit<ModerationState> {
  ModerationCubit(this._repository) : super(const ModerationState());

  final ModerationRepository _repository;

  Future<void> load() async {
    emit(state.copyWith(isLoading: true));
    emit(
      state.copyWith(
        reports: await _repository.reports(),
        actions: await _repository.list(),
        isLoading: false,
      ),
    );
  }

  /// Applies an action and clears the report in one step. Two separate calls
  /// let a moderator hide a comment and leave its report open, so the next
  /// moderator reviews something already handled.
  Future<void> resolve(
    ModerationReport report,
    ModerationType type, {
    String? reason,
  }) async {
    await _repository.create(type, report.author, reason ?? report.reason);
    await _repository.resolve(report.id);
    await load();
  }
}
