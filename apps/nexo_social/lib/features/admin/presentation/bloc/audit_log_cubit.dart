import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/audit_entry.dart';
import '../../domain/repositories/admin_repository.dart';
import 'admin_feedback.dart';

export 'admin_feedback.dart';

class AuditLogState extends Equatable {
  const AuditLogState({
    this.filter = const AuditFilter(),
    this.entries = const [],
    this.nextCursor,
    this.isLoading = true,
    this.isLoadingMore = false,
    this.issue,
  });

  final AuditFilter filter;

  /// Más reciente primero.
  final List<AuditEntry> entries;
  final String? nextCursor;
  final bool isLoading;
  final bool isLoadingMore;
  final AdminIssue? issue;

  bool get hasMore => nextCursor != null;

  AuditLogState copyWith({
    AuditFilter? filter,
    List<AuditEntry>? entries,
    String? Function()? nextCursor,
    bool? isLoading,
    bool? isLoadingMore,
    AdminIssue? Function()? issue,
  }) => AuditLogState(
    filter: filter ?? this.filter,
    entries: entries ?? this.entries,
    nextCursor: nextCursor == null ? this.nextCursor : nextCursor(),
    isLoading: isLoading ?? this.isLoading,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    issue: issue == null ? this.issue : issue(),
  );

  @override
  List<Object?> get props => [
    filter,
    entries,
    nextCursor,
    isLoading,
    isLoadingMore,
    issue,
  ];
}

/// La auditoría no se escucha en vivo a propósito: una tabla que se reordena
/// mientras el operador la lee le mueve la fila que estaba mirando. Se
/// refresca al cambiar el filtro o a pedido.
class AuditLogCubit extends Cubit<AuditLogState> {
  AuditLogCubit(this._repository) : super(const AuditLogState());

  final AdminRepository _repository;

  Future<void> load([AuditFilter? filter]) async {
    emit(state.copyWith(filter: filter, isLoading: true));
    try {
      final page = await _repository.audit(state.filter);
      emit(
        state.copyWith(
          entries: page.items,
          nextCursor: () => page.nextCursor,
          isLoading: false,
          issue: () => null,
        ),
      );
    } on Failure catch (failure) {
      emit(
        state.copyWith(
          entries: const [],
          nextCursor: () => null,
          isLoading: false,
          issue: () => adminIssueFor(failure),
        ),
      );
    }
  }

  Future<void> loadMore() async {
    final cursor = state.nextCursor;
    if (cursor == null || state.isLoadingMore) return;
    emit(state.copyWith(isLoadingMore: true));
    try {
      final page = await _repository.audit(state.filter, cursor: cursor);
      emit(
        state.copyWith(
          entries: [...state.entries, ...page.items],
          nextCursor: () => page.nextCursor,
          isLoadingMore: false,
        ),
      );
    } on Failure catch (failure) {
      emit(
        state.copyWith(
          isLoadingMore: false,
          issue: () => adminIssueFor(failure),
        ),
      );
    }
  }
}
