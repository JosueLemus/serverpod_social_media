import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/follow.dart';
import '../../domain/repositories/follow_repository.dart';

sealed class FollowListState extends Equatable {
  const FollowListState();

  @override
  List<Object?> get props => const [];
}

class FollowListLoading extends FollowListState {
  const FollowListLoading();
}

class FollowListFailure extends FollowListState {
  const FollowListFailure({this.offline = false});

  final bool offline;

  @override
  List<Object?> get props => [offline];
}

class FollowListLoaded extends FollowListState {
  const FollowListLoaded(
    this.items, {
    this.nextCursor,
    this.isLoadingMore = false,
  });

  final List<ProfileSummary> items;
  final String? nextCursor;
  final bool isLoadingMore;

  bool get hasMore => nextCursor != null;

  FollowListLoaded copyWith({
    List<ProfileSummary>? items,
    String? Function()? nextCursor,
    bool? isLoadingMore,
  }) => FollowListLoaded(
    items ?? this.items,
    nextCursor: nextCursor == null ? this.nextCursor : nextCursor(),
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
  );

  @override
  List<Object?> get props => [items, nextCursor, isLoadingMore];
}

/// Los seguidores o los seguidos de una cuenta, paginados.
class FollowListCubit extends Cubit<FollowListState> {
  FollowListCubit(this._follows, this.userId, this.kind)
    : super(const FollowListLoading());

  final FollowRepository _follows;
  final String userId;
  final FollowListKind kind;

  Future<void> load() async {
    emit(const FollowListLoading());
    try {
      final page = await _follows.list(userId, kind);
      if (!isClosed) {
        emit(FollowListLoaded(page.items, nextCursor: page.nextCursor));
      }
    } on Failure catch (failure) {
      if (!isClosed) {
        emit(FollowListFailure(offline: failure is NetworkFailure));
      }
    }
  }

  Future<void> loadMore() async {
    final current = state;
    if (current is! FollowListLoaded ||
        !current.hasMore ||
        current.isLoadingMore) {
      return;
    }
    emit(current.copyWith(isLoadingMore: true));
    try {
      final page = await _follows.list(
        userId,
        kind,
        cursor: current.nextCursor,
      );
      final latest = state;
      if (isClosed || latest is! FollowListLoaded) return;
      final known = {for (final item in latest.items) item.id};
      emit(
        latest.copyWith(
          items: [
            ...latest.items,
            ...page.items.where((item) => !known.contains(item.id)),
          ],
          nextCursor: () => page.nextCursor,
          isLoadingMore: false,
        ),
      );
    } on Failure {
      final latest = state;
      if (!isClosed && latest is FollowListLoaded) {
        emit(latest.copyWith(isLoadingMore: false));
      }
    }
  }
}
