import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../live/domain/entities/live_session.dart';
import '../../../moderation/domain/entities/moderation_action.dart';
import '../../domain/repositories/admin_repository.dart';
import 'admin_feedback.dart';

export 'admin_feedback.dart';

class AdminConsoleState extends Equatable {
  const AdminConsoleState({
    this.query = '',
    this.accounts = const [],
    this.creators = const [],
    this.lives = const [],
    this.isLoading = true,
    this.issue,
    this.notice,
    this.serial = 0,
  });

  final String query;
  final List<AppUser> accounts;
  final List<AppUser> creators;
  final List<LiveSession> lives;
  final bool isLoading;

  /// El rechazo o la confirmación de la última acción. [serial] crece con
  /// cada una, así que la misma dos veces seguidas también se avisa.
  final AdminIssue? issue;
  final AdminNotice? notice;
  final int serial;

  /// La consola se leyó pero el servidor dijo que no: quien llegó a la URL a
  /// mano no es operador.
  bool get isForbidden =>
      issue == AdminIssue.forbidden && accounts.isEmpty && creators.isEmpty;

  AdminConsoleState copyWith({
    String? query,
    List<AppUser>? accounts,
    List<AppUser>? creators,
    List<LiveSession>? lives,
    bool? isLoading,
    AdminIssue? issue,
    AdminNotice? notice,
    bool clearFeedback = false,
    int? serial,
  }) => AdminConsoleState(
    query: query ?? this.query,
    accounts: accounts ?? this.accounts,
    creators: creators ?? this.creators,
    lives: lives ?? this.lives,
    isLoading: isLoading ?? this.isLoading,
    // Lo nuevo gana; [clearFeedback] sólo descarta lo anterior. Al revés,
    // una confirmación recién emitida se borraba en el mismo copyWith.
    issue: issue ?? (clearFeedback ? null : this.issue),
    notice: notice ?? (clearFeedback ? null : this.notice),
    serial: serial ?? this.serial,
  );

  @override
  List<Object?> get props => [
    query,
    accounts,
    creators,
    lives,
    isLoading,
    issue,
    notice,
    serial,
  ];
}

/// Cuentas, creadores y vivos activos. La auditoría tiene su propio cubit
/// porque pagina y filtra por su cuenta.
class AdminConsoleCubit extends Cubit<AdminConsoleState> {
  AdminConsoleCubit(this._repository) : super(const AdminConsoleState());

  final AdminRepository _repository;
  StreamSubscription<void>? _changes;

  Future<void> load() async {
    emit(state.copyWith(isLoading: true));
    await _read();
    _changes ??= _repository.changes().listen((_) => unawaited(_read()));
  }

  Future<void> search(String query) async {
    emit(state.copyWith(query: query));
    await _read();
  }

  Future<void> _read() async {
    try {
      final accounts = await _repository.searchAccounts(state.query);
      final creators = await _repository.creators();
      final lives = await _repository.activeLives();
      if (isClosed) return;
      emit(
        state.copyWith(
          accounts: accounts.items,
          creators: creators,
          lives: lives,
          isLoading: false,
        ),
      );
    } on Failure catch (failure) {
      if (isClosed) return;
      emit(
        AdminConsoleState(
          query: state.query,
          isLoading: false,
          issue: adminIssueFor(failure),
          serial: state.serial + 1,
        ),
      );
    }
  }

  Future<void> setVerification(
    AppUser creator, {
    required bool verified,
    ModerationReason? reason,
  }) => _act(
    () => _repository.setVerification(
      creator.id,
      verified: verified,
      reason: reason,
    ),
    verified ? AdminNotice.verified : AdminNotice.verificationRevoked,
  );

  Future<void> forceEndLive(LiveSession live, ModerationReason reason) => _act(
    () => _repository.forceEndLive(live.id, reason),
    AdminNotice.liveEnded,
  );

  Future<void> _act(Future<void> Function() action, AdminNotice notice) async {
    try {
      await action();
      emit(
        state.copyWith(
          clearFeedback: true,
          notice: notice,
          serial: state.serial + 1,
        ),
      );
      await _read();
    } on Failure catch (failure) {
      emit(
        state.copyWith(
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
