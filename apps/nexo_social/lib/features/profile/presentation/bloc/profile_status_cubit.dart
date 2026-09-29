import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/domain/entities/app_user.dart';
import '../../domain/repositories/profile_repository.dart';

class ProfileStatusState extends Equatable {
  const ProfileStatusState({this.status = AccountStatus.active});

  final AccountStatus status;

  bool get isSanctioned => status != AccountStatus.active;

  @override
  List<Object?> get props => [status];
}

/// El estado público de la cuenta que se está mirando. Escucha al servidor:
/// una suspensión aplicada desde la consola se ve en el perfil sin recargar.
class ProfileStatusCubit extends Cubit<ProfileStatusState> {
  ProfileStatusCubit(this._repository, this.username)
    : super(const ProfileStatusState());

  final ProfileRepository _repository;
  final String username;
  StreamSubscription<void>? _changes;

  Future<void> load() async {
    await _read();
    _changes ??= _repository.changes().listen((_) => unawaited(_read()));
  }

  Future<void> _read() async {
    final status = await _repository.statusOf(username);
    if (!isClosed) emit(ProfileStatusState(status: status));
  }

  @override
  Future<void> close() async {
    await _changes?.cancel();
    return super.close();
  }
}
