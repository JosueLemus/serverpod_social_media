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

  /// [AccountStatus.suspended] o [AccountStatus.banned]. Null cuando el
  /// servidor no dijo cuál: la pantalla no promete que la sanción termina.
  final AccountStatus? status;
  final ModerationReason? reason;

  @override
  List<Object?> get props => [status, reason];
}

/// Lo que el formulario detecta antes de molestar al servidor. La View lo
/// traduce, como a [AuthFailureReason].
enum AuthInputIssue {
  invalidEmail,
  emptyPassword,
  passwordMismatch,
  invalidCode,
}

/// Las reglas del formulario de acceso, en un solo lugar. Un campo vacío
/// llegaba al servidor y volvía como "no pudimos completar la operación",
/// que no dice qué corregir.
abstract final class AuthInput {
  static final _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static final _code = RegExp(r'^\d{8}$');

  /// Cada argumento nulo es un campo que ese paso no pide.
  static AuthInputIssue? check({
    required String email,
    String? password,
    String? confirmation,
    String? code,
  }) {
    if (!_email.hasMatch(email.trim())) return AuthInputIssue.invalidEmail;
    if (code != null && !_code.hasMatch(code)) {
      return AuthInputIssue.invalidCode;
    }
    if (password != null && password.isEmpty) {
      return AuthInputIssue.emptyPassword;
    }
    if (confirmation != null && confirmation != password) {
      return AuthInputIssue.passwordMismatch;
    }
    return null;
  }
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
    } on AccountSuspendedFailure catch (failure) {
      if (_isCurrent(version)) await _toSuspended(failure: failure);
    } on AuthenticationFailure catch (failure) {
      if (_isCurrent(version)) {
        _emit(AuthUnauthenticated(failure: failure.reason));
      }
    } on Failure {
      if (_isCurrent(version)) _emit(const AuthUnauthenticated());
    }
  }

  /// Vuelve a leer la cuenta de la sesión. Lo llama quien cambió algo de
  /// ella (editar el perfil, el avatar, volverse creador) para que la barra,
  /// el perfil y la guarda vean lo nuevo sin cerrar sesión.
  Future<void> reload() async {
    final current = state;
    if (current is! AuthAuthenticated ||
        current.user.role == UserRole.visitor) {
      return;
    }
    try {
      final user = await _repository.currentUser();
      if (user != null && user.id == current.user.id && state == current) {
        _emit(AuthAuthenticated(user));
      }
    } on Failure {
      // Lo que se mostraba sigue valiendo; la próxima lectura lo corrige.
    }
  }

  /// Deja el formulario limpio: sin el error ni el paso de otra pantalla.
  ///
  /// [AuthUnauthenticated] es uno solo para todas las pantallas de acceso, así
  /// que sin esto un error del login aparecía en "Recupera tu acceso" y el
  /// registro abría en "Confirma tu correo" con el correo vacío y bloqueado.
  ///
  /// No hace nada con una sesión activa ni con una operación en vuelo: la
  /// primera no es un formulario, y descartar la segunda perdería su
  /// resultado (un inicio de sesión que el servidor sí aceptó).
  void resetForm() {
    final current = state;
    if (current is! AuthUnauthenticated || current.isBusy) return;
    _registration = null;
    _passwordReset = null;
    _emit(const AuthUnauthenticated());
  }

  Future<void> signIn(String email, String password) async {
    final version = ++_operationVersion;
    _emit(const AuthUnauthenticated(operation: AuthOperation.signingIn));
    try {
      final user = await _repository.signIn(email: email, password: password);
      if (_isCurrent(version)) _emit(AuthAuthenticated(user));
    } on AccountSuspendedFailure catch (failure) {
      if (_isCurrent(version)) await _toSuspended(failure: failure);
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
    } on AccountSuspendedFailure catch (failure) {
      if (_isCurrent(version)) await _toSuspended(failure: failure);
    } on AuthenticationFailure catch (failure) {
      if (_isCurrent(version)) {
        // A token may have been consumed before finalisation. Never preserve it
        // as a retry credential; request another code instead.
        if (failure.reason != AuthFailureReason.invalidCode) {
          _registration = null;
          _formFailure(failure.reason);
        } else {
          // Un dígito mal tipeado no invalida el pedido: el servidor permite
          // reintentar hasta su tope. Volver al formulario inicial obligaba a
          // pedir otro código y descartaba el que la persona ya tenía.
          _formFailure(
            failure.reason,
            operation: AuthOperation.awaitingRegistrationCode,
          );
        }
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
          _formFailure(failure.reason);
        } else {
          _formFailure(
            failure.reason,
            operation: AuthOperation.awaitingResetCode,
          );
        }
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

  void _formFailure(
    AuthFailureReason reason, {
    AuthOperation operation = AuthOperation.idle,
  }) => _emit(AuthUnauthenticated(operation: operation, failure: reason));

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
      await _toSuspended(user: user);
      return;
    }
    if (user != current.user) _emit(AuthAuthenticated(user));
  }

  /// La sanción sale de la cuenta leída o del fallo que la rechazó. Antes
  /// caía en "suspendida" siempre que no hubiera cuenta, así que una cuenta
  /// dada de baja leía que su sanción iba a terminar.
  Future<void> _toSuspended({
    AppUser? user,
    AccountSuspendedFailure? failure,
  }) async {
    final status =
        user?.status ??
        switch (failure?.sanction) {
          AccountSanction.banned => AccountStatus.banned,
          AccountSanction.suspended => AccountStatus.suspended,
          null => null,
        };
    final accountId = user?.id ?? failure?.accountId;
    ModerationReason? reason;
    if (accountId != null) {
      try {
        reason = await _repository.sanctionReason(accountId);
      } on Failure {
        // Sin motivo se explica igual la sanción; no vale frenar la salida.
      }
    }
    try {
      await _repository.signOut();
    } on Failure {
      // The client must still stop authorising the private interface.
    }
    _emit(AuthSuspended(status: status, reason: reason));
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
