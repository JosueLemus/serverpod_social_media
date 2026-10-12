import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/repositories/follow_repository.dart';
import '../../domain/repositories/profile_repository.dart';
import 'public_profile_cubit.dart';

export 'public_profile_cubit.dart' show ProfileNotice;

/// Seguir a una sola cuenta desde una pantalla que no es su perfil (la sala
/// de un vivo). Necesita leer el perfil para saber si ya se la sigue: el
/// vivo trae el username del host, no la relación con quien mira.
class FollowButtonState extends Equatable {
  const FollowButtonState({
    this.userId,
    this.following = false,
    this.isReady = false,
    this.notice,
    this.noticeSerial = 0,
  });

  final String? userId;
  final bool following;

  /// Hasta saber si ya se sigue, el botón no se ofrece: un "Seguir" que
  /// después resulta "Siguiendo" se lee como que el tap no anduvo.
  final bool isReady;
  final ProfileNotice? notice;
  final int noticeSerial;

  FollowButtonState copyWith({
    String? userId,
    bool? following,
    bool? isReady,
    ProfileNotice? notice,
    int? noticeSerial,
  }) => FollowButtonState(
    userId: userId ?? this.userId,
    following: following ?? this.following,
    isReady: isReady ?? this.isReady,
    notice: notice ?? this.notice,
    noticeSerial: noticeSerial ?? this.noticeSerial,
  );

  @override
  List<Object?> get props => [userId, following, isReady, notice, noticeSerial];
}

class FollowCubit extends Cubit<FollowButtonState> {
  FollowCubit(this._follows, this._profiles, this.username)
    : super(const FollowButtonState());

  final FollowRepository _follows;
  final ProfileRepository _profiles;
  final String username;

  Future<void> load() async {
    if (username.isEmpty) return;
    try {
      final profile = await _profiles.byUsername(username);
      if (isClosed) return;
      emit(
        state.copyWith(
          userId: profile.id,
          following: profile.viewerFollows,
          isReady: true,
        ),
      );
    } on Failure {
      // Sin perfil no hay a quién seguir: el botón no aparece.
    }
  }

  /// Optimista, con vuelta atrás si el servidor lo rechaza.
  Future<void> toggle() async {
    final userId = state.userId;
    if (userId == null) return;
    final following = !state.following;
    emit(state.copyWith(following: following));
    try {
      final result = following
          ? await _follows.follow(userId)
          : await _follows.unfollow(userId);
      if (!isClosed) emit(state.copyWith(following: result.viewerFollows));
    } on Failure catch (failure) {
      if (isClosed) return;
      emit(
        state.copyWith(
          following: !following,
          notice: switch (failure) {
            AccountSuspendedFailure() => ProfileNotice.suspended,
            ForbiddenFailure() => ProfileNotice.signInToFollow,
            _ => ProfileNotice.followFailed,
          },
          noticeSerial: state.noticeSerial + 1,
        ),
      );
    }
  }
}
