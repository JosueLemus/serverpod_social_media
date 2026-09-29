import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../../moderation/domain/entities/moderation_action.dart';
import '../../domain/entities/account_detail.dart';
import '../../domain/repositories/admin_repository.dart';
import 'admin_feedback.dart';

export 'admin_feedback.dart';

class AccountDetailState extends Equatable {
  const AccountDetailState({
    this.detail,
    this.isLoading = true,
    this.isWorking = false,
    this.issue,
    this.notice,
    this.serial = 0,
  });

  /// Null mientras carga o si no se pudo leer ([issue] dice por qué).
  final AccountDetail? detail;
  final bool isLoading;

  /// Una sanción en curso. Deshabilita los botones: un doble tap sobre
  /// "Suspender" no puede ser dos sanciones.
  final bool isWorking;
  final AdminIssue? issue;
  final AdminNotice? notice;
  final int serial;

  AccountDetailState copyWith({
    AccountDetail? detail,
    bool? isLoading,
    bool? isWorking,
    AdminIssue? issue,
    AdminNotice? notice,
    bool clearFeedback = false,
    int? serial,
  }) => AccountDetailState(
    detail: detail ?? this.detail,
    isLoading: isLoading ?? this.isLoading,
    isWorking: isWorking ?? this.isWorking,
    // Lo nuevo gana; [clearFeedback] sólo descarta lo anterior. Al revés,
    // una confirmación recién emitida se borraba en el mismo copyWith.
    issue: issue ?? (clearFeedback ? null : this.issue),
    notice: notice ?? (clearFeedback ? null : this.notice),
    serial: serial ?? this.serial,
  );

  @override
  List<Object?> get props => [
    detail,
    isLoading,
    isWorking,
    issue,
    notice,
    serial,
  ];
}

class AccountDetailCubit extends Cubit<AccountDetailState> {
  AccountDetailCubit(this._repository, this.accountId)
    : super(const AccountDetailState());

  final AdminRepository _repository;
  final String accountId;
  StreamSubscription<void>? _changes;

  Future<void> load() async {
    emit(state.copyWith(isLoading: true));
    await _read();
    _changes ??= _repository.changes().listen((_) => unawaited(_read()));
  }

  Future<void> _read() async {
    try {
      final detail = await _repository.account(accountId);
      if (isClosed) return;
      emit(state.copyWith(detail: detail, isLoading: false));
    } on Failure catch (failure) {
      if (isClosed) return;
      emit(
        AccountDetailState(
          isLoading: false,
          issue: adminIssueFor(failure),
          serial: state.serial + 1,
        ),
      );
    }
  }

  Future<void> suspend(ModerationReason reason) =>
      _act(() => _repository.suspend(accountId, reason), AdminNotice.suspended);

  Future<void> ban(ModerationReason reason) =>
      _act(() => _repository.ban(accountId, reason), AdminNotice.banned);

  Future<void> restore() =>
      _act(() => _repository.restore(accountId), AdminNotice.restored);

  Future<void> setVerification({
    required bool verified,
    ModerationReason? reason,
  }) => _act(
    () => _repository.setVerification(
      accountId,
      verified: verified,
      reason: reason,
    ),
    verified ? AdminNotice.verified : AdminNotice.verificationRevoked,
  );

  Future<void> _act(Future<void> Function() action, AdminNotice notice) async {
    if (state.isWorking) return;
    emit(state.copyWith(isWorking: true));
    try {
      await action();
      await _read();
      emit(
        state.copyWith(
          isWorking: false,
          clearFeedback: true,
          notice: notice,
          serial: state.serial + 1,
        ),
      );
    } on Failure catch (failure) {
      emit(
        state.copyWith(
          isWorking: false,
          clearFeedback: true,
          issue: adminIssueFor(failure),
          serial: state.serial + 1,
        ),
      );
    }
  }

  @override
  Future<void> close() async {
    await _changes?.cancel();
    return super.close();
  }
}
