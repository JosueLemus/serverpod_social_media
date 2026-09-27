import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';

sealed class AuthState {
  const AuthState();
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
}

class AuthCubit extends Cubit<AuthState> {
  AuthCubit(this._repository) : super(const AuthLoading());
  final AuthRepository _repository;
  Future<void> restore() async {
    final user = await _repository.currentUser();
    emit(user == null ? const AuthUnauthenticated() : AuthAuthenticated(user));
  }

  Future<void> signIn(String email, String password) async {
    emit(const AuthLoading());
    emit(
      AuthAuthenticated(
        await _repository.signIn(email: email, password: password),
      ),
    );
  }

  Future<void> signUp({
    required String name,
    required String username,
    required String email,
    required String password,
  }) async {
    emit(const AuthLoading());
    emit(
      AuthAuthenticated(
        await _repository.signUp(
          name: name,
          username: username,
          email: email,
          password: password,
        ),
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
}
