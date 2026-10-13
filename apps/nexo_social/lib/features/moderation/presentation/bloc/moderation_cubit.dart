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
    this.isWorking = false,
    this.loadIssue,
    this.actionIssue,
  });

  final List<ModerationReport> reports;
  final List<ModerationAction> actions;
  final bool isLoading;

  /// Una acción en curso. Deshabilita los botones de la cola: un doble tap
  /// sobre "Expulsar" no puede ser dos sanciones.
  final bool isWorking;

  /// Por qué no se pudo leer la cola. Un estado propio: sin él, un rechazo
  /// del servidor se ve igual que una cola vacía.
  final ModerationIssue? loadIssue;

  /// Por qué se rechazó la última acción. Aparte de [loadIssue] porque dicen
  /// cosas distintas: "no pudimos leer" pide reintentar la lectura; "no
  /// pudimos aplicar" deja la cola como estaba.
  final ModerationIssue? actionIssue;

  /// La cola no se pudo leer y no hay nada anterior que mostrar.
  bool get failedToLoad => loadIssue != null && reports.isEmpty;

  ModerationState copyWith({
    List<ModerationReport>? reports,
    List<ModerationAction>? actions,
    bool? isLoading,
    bool? isWorking,
    ModerationIssue? Function()? loadIssue,
    ModerationIssue? Function()? actionIssue,
  }) => ModerationState(
    reports: reports ?? this.reports,
    actions: actions ?? this.actions,
    isLoading: isLoading ?? this.isLoading,
    isWorking: isWorking ?? this.isWorking,
    loadIssue: loadIssue == null ? this.loadIssue : loadIssue(),
    actionIssue: actionIssue == null ? this.actionIssue : actionIssue(),
  );

  @override
  List<Object?> get props => [
    reports,
    actions,
    isLoading,
    isWorking,
    loadIssue,
    actionIssue,
  ];
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
          loadIssue: () => null,
        ),
      );
    } on Failure catch (failure) {
      if (isClosed) return;
      // Lo que ya se mostraba se queda: una relectura fallida (desde otra
      // pestaña, un tirón para refrescar) no vacía la cola en pantalla.
      emit(
        state.copyWith(
          isLoading: false,
          loadIssue: () => _issueFor(failure),
        ),
      );
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
    if (state.isWorking) return;
    emit(state.copyWith(isWorking: true, actionIssue: () => null));
    try {
      await action();
      await _read();
      if (isClosed) return;
      emit(state.copyWith(isWorking: false));
    } on Failure catch (failure) {
      if (isClosed) return;
      emit(
        state.copyWith(
          isWorking: false,
          actionIssue: () => _issueFor(failure),
        ),
      );
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
