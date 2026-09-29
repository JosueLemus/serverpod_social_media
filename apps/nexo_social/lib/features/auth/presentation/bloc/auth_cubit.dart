import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../../moderation/domain/entities/moderation_action.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';

sealed class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => const [];
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthAuthenticated extends AuthState {
  const AuthAuthenticated(this.user);

  final AppUser user;

  // Without this, two identical sessions compare unequal and every emit looks
  // like a real change — which makes the router's refreshListenable re-run the
  // guard for nothing.
  @override
  List<Object?> get props => [user];
}

/// La sesión se revocó porque la cuenta fue sancionada.
///
/// Un estado propio y no un [AuthUnauthenticated]: quien queda afuera tiene
/// que saber por qué. Mandarlo al login sin explicación se lee como un fallo
/// de la app, y lo primero que hace es volver a intentar entrar.
class AuthSuspended extends AuthState {
  const AuthSuspended({required this.status, this.reason});

  final AccountStatus status;
  final ModerationReason? reason;

  @override
  List<Object?> get props => [status, reason];
}

class AuthCubit extends Cubit<AuthState> {
  AuthCubit(this._repository) : super(const AuthLoading()) {
    // La sesión escucha al servidor, no a la pantalla. Así es como una
    // suspensión aplicada desde la consola —en otra pestaña, por otra
    // persona— saca a esta cuenta en el acto, sin que toque nada.
    _subscription = _repository.watchSession().listen(_onSessionChanged);
  }

  final AuthRepository _repository;
  late final StreamSubscription<AppUser?> _subscription;

  Future<void> restore() => _guard(_repository.currentUser);

  Future<void> signIn(String email, String password) {
    emit(const AuthLoading());
    return _guard(() => _repository.signIn(email: email, password: password));
  }

  Future<void> signUp({
    required String name,
    required String username,
    required String email,
    required String password,
  }) {
    emit(const AuthLoading());
    return _guard(
      () => _repository.signUp(
        name: name,
        username: username,
        email: email,
        password: password,
      ),
    );
  }

  Future<void> guest() async {
    emit(const AuthLoading());
    emit(AuthAuthenticated(await _repository.exploreAsGuest()));
  }

  Future<void> signOut() async {
    await _repository.signOut();
    emit(const AuthUnauthenticated());
  }

  /// Sale de la pantalla de cuenta suspendida hacia el login.
  Future<void> acknowledgeSuspension() => signOut();

  /// Un intento que falla no puede dejar la app en [AuthLoading]: el guard
  /// la retiene en el splash y la app no sale nunca del logo.
  Future<void> _guard(Future<AppUser?> Function() attempt) async {
    try {
      final user = await attempt();
      emit(
        user == null ? const AuthUnauthenticated() : AuthAuthenticated(user),
      );
    } on AccountSuspendedFailure {
      await _toSuspended();
    } on Failure {
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> _onSessionChanged(AppUser? user) async {
    final current = state;
    // Sólo interesa una sesión real: un invitado no tiene cuenta que cambie.
    if (current is! AuthAuthenticated ||
        current.user.role == UserRole.visitor) {
      return;
    }
    if (user == null || user.id != current.user.id) return;
    if (!user.isActive) {
      await _toSuspended(user);
      return;
    }
    // Un cambio de rol o de verificación también llega: el Studio y el rail
    // leen al usuario de acá.
    if (user != current.user) emit(AuthAuthenticated(user));
  }

  Future<void> _toSuspended([AppUser? user]) async {
    final reason = user == null
        ? null
        : await _repository.sanctionReason(user.id);
    await _repository.signOut();
    emit(
      AuthSuspended(
        status: user?.status ?? AccountStatus.suspended,
        reason: reason,
      ),
    );
  }

  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }
}
