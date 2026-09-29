import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/moderation_action.dart';
import '../../domain/repositories/moderation_repository.dart';

/// Por qué no se pudo leer o aplicar. La View lo traduce.
enum ModerationIssue { forbidden, conflict, other }

class ModerationState extends Equatable {
  const ModerationState({
    this.reports = const [],
    this.actions = const [],
    this.isLoading = true,
    this.issue,
  });

  final List<ModerationReport> reports;
  final List<ModerationAction> actions;
  final bool isLoading;

  /// Si la cola no se pudo leer (sin permiso, por ejemplo) o la última acción
  /// se rechazó. Un estado propio: sin él, un rechazo del servidor se ve
  /// igual que una cola vacía.
  final ModerationIssue? issue;

  ModerationState copyWith({
    List<ModerationReport>? reports,
    List<ModerationAction>? actions,
    bool? isLoading,
    ModerationIssue? Function()? issue,
  }) => ModerationState(
    reports: reports ?? this.reports,
    actions: actions ?? this.actions,
    isLoading: isLoading ?? this.isLoading,
    issue: issue == null ? this.issue : issue(),
  );

  @override
  List<Object?> get props => [reports, actions, isLoading, issue];
}

class ModerationCubit extends Cubit<ModerationState> {
  ModerationCubit(this._repository) : super(const ModerationState());

  final ModerationRepository _repository;
  StreamSubscription<void>? _changes;

  Future<void> load() async {
    emit(state.copyWith(isLoading: true));
    await _read();
    // Un reporte nuevo —desde la sala, desde otra pestaña— entra solo a la
    // cola. Una cola que hay que refrescar a mano esconde lo más urgente.
    _changes ??= _repository.changes().listen((_) => unawaited(_read()));
  }

  Future<void> _read() async {
    try {
      final reports = await _repository.reports();
      final actions = await _repository.list();
      if (isClosed) return;
      emit(
        state.copyWith(
          reports: reports,
          actions: actions,
          isLoading: false,
          issue: () => null,
        ),
      );
    } on Failure catch (failure) {
      if (isClosed) return;
      emit(ModerationState(isLoading: false, issue: _issueFor(failure)));
    }
  }

  /// Applies an action and clears the report in one step. Two separate calls
  /// let a moderator hide a comment and leave its report open, so the next
  /// moderator reviews something already handled.
  Future<void> resolve(
    ModerationReport report,
    ModerationType type, {
    MuteDuration? muteFor,
  }) => _act(
    () => _repository.resolve(
      report.id,
      ModerationDecision(
        type: type,
        muteFor: type == ModerationType.muteUser
            ? (muteFor ?? MuteDuration.oneDay)
            : null,
      ),
    ),
  );

  Future<void> dismiss(ModerationReport report) =>
      _act(() => _repository.dismiss(report.id));

  Future<void> _act(Future<void> Function() action) async {
    try {
      await action();
      await _read();
    } on Failure catch (failure) {
      emit(state.copyWith(issue: () => _issueFor(failure)));
    }
  }

  static ModerationIssue _issueFor(Failure failure) => switch (failure) {
    ForbiddenFailure() ||
    AccountSuspendedFailure() => ModerationIssue.forbidden,
    ConflictFailure() || NotFoundFailure() => ModerationIssue.conflict,
    _ => ModerationIssue.other,
  };

  @override
  Future<void> close() async {
    await _changes?.cancel();
    return super.close();
  }
}
