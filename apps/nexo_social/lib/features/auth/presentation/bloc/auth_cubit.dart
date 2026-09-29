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

/// Only the initial credential restoration uses the splash state. Form work
/// stays in [AuthUnauthenticated], preserving the visible form and its input.
class AuthLoading extends AuthState {
  const AuthLoading();
}

enum AuthOperation {
  idle,
  signingIn,
  requestingRegistration,
  awaitingRegistrationCode,
  completingRegistration,
  requestingReset,
  awaitingResetCode,
  completingReset,
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated({
    this.operation = AuthOperation.idle,
    this.failure,
  });

  final AuthOperation operation;
  final AuthFailureReason? failure;

  bool get isBusy => switch (operation) {
    AuthOperation.idle ||
    AuthOperation.awaitingRegistrationCode ||
    AuthOperation.awaitingResetCode => false,
    _ => true,
  };

  @override
  List<Object?> get props => [operation, failure];
}

class AuthAuthenticated extends AuthState {
  const AuthAuthenticated(this.user);

  final AppUser user;

  @override
  List<Object?> get props => [user];
}

/// La sesión se revocó porque la cuenta fue sancionada.
class AuthSuspended extends AuthState {
  const AuthSuspended({required this.status, this.reason});

  final AccountStatus status;
  final ModerationReason? reason;

  @override
  List<Object?> get props => [status, reason];
}

class AuthCubit extends Cubit<AuthState> {
  AuthCubit(this._repository) : super(const AuthLoading()) {
    _subscription = _repository.watchSession().listen(_onSessionChanged);
  }

  final AuthRepository _repository;
  late final StreamSubscription<AppUser?> _subscription;
  EmailVerificationRequest? _registration;
  EmailVerificationRequest? _passwordReset;
  int _operationVersion = 0;

  static const _guest = AppUser(
    id: 'guest',
    username: 'invitado',
    name: 'Invitado',
    role: UserRole.visitor,
  );

  Future<void> restore() async {
    final version = ++_operationVersion;
    try {
      final user = await _repository.currentUser();
      if (!_isCurrent(version)) return;
      _emit(
        user == null ? const AuthUnauthenticated() : AuthAuthenticated(user),
      );
    } on AccountSuspendedFailure {
      if (_isCurrent(version)) await _toSuspended();
    } on AuthenticationFailure catch (failure) {
      if (_isCurrent(version)) {
        _emit(AuthUnauthenticated(failure: failure.reason));
      }
    } on Failure {
      if (_isCurrent(version)) _emit(const AuthUnauthenticated());
    }
  }

  Future<void> signIn(String email, String password) async {
    final version = ++_operationVersion;
    _emit(const AuthUnauthenticated(operation: AuthOperation.signingIn));
    try {
      final user = await _repository.signIn(email: email, password: password);
      if (_isCurrent(version)) _emit(AuthAuthenticated(user));
    } on AccountSuspendedFailure {
      if (_isCurrent(version)) await _toSuspended();
    } on AuthenticationFailure catch (failure) {
      if (_isCurrent(version)) _formFailure(failure.reason);
    } on Failure {
      if (_isCurrent(version)) _formFailure(AuthFailureReason.unavailable);
    }
  }

  Future<void> startRegistration(String email) async {
    final version = ++_operationVersion;
    _registration = null;
    _emit(
      const AuthUnauthenticated(
        operation: AuthOperation.requestingRegistration,
      ),
    );
    try {
      final request = await _repository.startRegistration(email: email);
      if (!_isCurrent(version)) return;
      _registration = request;
      _emit(
        const AuthUnauthenticated(
          operation: AuthOperation.awaitingRegistrationCode,
        ),
      );
    } on AuthenticationFailure catch (failure) {
      if (_isCurrent(version)) _formFailure(failure.reason);
    } on Failure {
      if (_isCurrent(version)) _formFailure(AuthFailureReason.unavailable);
    }
  }

  Future<void> finishRegistration({
    required String verificationCode,
    required String password,
  }) async {
    final request = _registration;
    if (request == null) {
      _formFailure(AuthFailureReason.invalidCode);
      return;
    }
    final version = ++_operationVersion;
    _emit(
      const AuthUnauthenticated(
        operation: AuthOperation.completingRegistration,
      ),
    );
    try {
      final user = await _repository.finishRegistration(
        request: request,
        verificationCode: verificationCode,
        password: password,
      );
      if (!_isCurrent(version)) return;
      _registration = null;
      _emit(AuthAuthenticated(user));
    } on AccountSuspendedFailure {
      if (_isCurrent(version)) await _toSuspended();
    } on AuthenticationFailure catch (failure) {
      if (_isCurrent(version)) {
        // A token may have been consumed before finalisation. Never preserve it
        // as a retry credential; request another code instead.
        if (failure.reason != AuthFailureReason.invalidCode) {
          _registration = null;
        }
        _formFailure(failure.reason);
      }
    } on Failure {
      if (_isCurrent(version)) {
        _registration = null;
        _formFailure(AuthFailureReason.unavailable);
      }
    }
  }

  Future<void> startPasswordReset(String email) async {
    final version = ++_operationVersion;
    _passwordReset = null;
    _emit(const AuthUnauthenticated(operation: AuthOperation.requestingReset));
    try {
      final request = await _repository.startPasswordReset(email: email);
      if (!_isCurrent(version)) return;
      _passwordReset = request;
      _emit(
        const AuthUnauthenticated(operation: AuthOperation.awaitingResetCode),
      );
    } on AuthenticationFailure catch (failure) {
      if (_isCurrent(version)) _formFailure(failure.reason);
    } on Failure {
      if (_isCurrent(version)) _formFailure(AuthFailureReason.unavailable);
    }
  }

  Future<void> finishPasswordReset({
    required String verificationCode,
    required String newPassword,
  }) async {
    final request = _passwordReset;
    if (request == null) {
      _formFailure(AuthFailureReason.invalidCode);
      return;
    }
    final version = ++_operationVersion;
    _emit(const AuthUnauthenticated(operation: AuthOperation.completingReset));
    try {
      await _repository.finishPasswordReset(
        request: request,
        verificationCode: verificationCode,
        newPassword: newPassword,
      );
      if (!_isCurrent(version)) return;
      _passwordReset = null;
      _emit(const AuthUnauthenticated());
    } on AuthenticationFailure catch (failure) {
      if (_isCurrent(version)) {
        if (failure.reason != AuthFailureReason.invalidCode) {
          _passwordReset = null;
        }
        _formFailure(failure.reason);
      }
    } on Failure {
      if (_isCurrent(version)) {
        _passwordReset = null;
        _formFailure(AuthFailureReason.unavailable);
      }
    }
  }

  Future<void> guest() async {
    ++_operationVersion;
    // Both implementations clear their own persisted session before returning
    // this ephemeral visitor. No visitor is ever issued a credential.
    await _repository.exploreAsGuest();
    _emit(const AuthAuthenticated(_guest));
  }

  Future<void> signOut() async {
    ++_operationVersion;
    _registration = null;
    _passwordReset = null;
    try {
      await _repository.signOut();
    } on AuthenticationFailure {
      // Serverpod already removed local credentials when revocation could not
      // reach the server. The UI is still de-authorised locally.
    } finally {
      _emit(const AuthUnauthenticated());
    }
  }

  Future<void> acknowledgeSuspension() => signOut();

  void _formFailure(AuthFailureReason reason) =>
      _emit(AuthUnauthenticated(failure: reason));

  Future<void> _onSessionChanged(AppUser? user) async {
    final current = state;
    if (current is! AuthAuthenticated ||
        current.user.role == UserRole.visitor) {
      return;
    }
    if (user == null) {
      ++_operationVersion;
      _emit(const AuthUnauthenticated());
      return;
    }
    if (user.id != current.user.id) return;
    if (!user.isActive) {
      ++_operationVersion;
      await _toSuspended(user);
      return;
    }
    if (user != current.user) _emit(AuthAuthenticated(user));
  }

  Future<void> _toSuspended([AppUser? user]) async {
    final reason = user == null
        ? null
        : await _repository.sanctionReason(user.id);
    try {
      await _repository.signOut();
    } on Failure {
      // The client must still stop authorising the private interface.
    }
    _emit(
      AuthSuspended(
        status: user?.status ?? AccountStatus.suspended,
        reason: reason,
      ),
    );
  }

  bool _isCurrent(int version) => !isClosed && version == _operationVersion;
  void _emit(AuthState next) {
    if (!isClosed) emit(next);
  }

  @override
  Future<void> close() async {
    ++_operationVersion;
    await _subscription.cancel();
    return super.close();
  }
}
