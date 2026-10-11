import 'dart:async';

import '../../../../core/errors/failures.dart';
import '../../../../core/mock/mock_platform.dart';
import '../../../moderation/domain/entities/moderation_action.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';

/// Lleva la sesión real a los módulos que todavía son mock (SDD 0007, F1).
///
/// Con `AUTH_SOURCE=serverpod`, las cuentas son del servidor pero vivos,
/// programar show, moderación de chat y consola siguen leyendo
/// `MockPlatform`, que no sabía quién había iniciado sesión: toda acción
/// respondía "sin permiso". Este decorador asocia la cuenta real a la cuenta
/// mock con **el mismo correo** —las del seed de `demo_seed.dart` y las de
/// `DemoAccounts` coinciden a propósito— y nada más.
///
/// Es un decorador y no una línea dentro de `ServerpodAuthRepository` para
/// que el repositorio real no sepa que existe un mock. En M7 se borra este
/// archivo y su registro en `injection.dart`.
class BridgedAuthRepository implements AuthRepository {
  BridgedAuthRepository(this._inner, this._platform);

  final AuthRepository _inner;
  final MockPlatform _platform;

  /// La cuenta real de la sesión y su pareja en el mock, si tiene.
  AppUser? _user;
  String? _twinId;

  @override
  Future<AppUser?> currentUser() async {
    final user = await _inner.currentUser();
    if (user == null) {
      _unbind();
      return null;
    }
    return _admit(user);
  }

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async => _admit(await _inner.signIn(email: email, password: password));

  @override
  Future<EmailVerificationRequest> startRegistration({required String email}) =>
      _inner.startRegistration(email: email);

  @override
  Future<AppUser> finishRegistration({
    required EmailVerificationRequest request,
    required String verificationCode,
    required String password,
  }) async => _admit(
    await _inner.finishRegistration(
      request: request,
      verificationCode: verificationCode,
      password: password,
    ),
  );

  @override
  Future<EmailVerificationRequest> startPasswordReset({
    required String email,
  }) => _inner.startPasswordReset(email: email);

  @override
  Future<void> finishPasswordReset({
    required EmailVerificationRequest request,
    required String verificationCode,
    required String newPassword,
  }) => _inner.finishPasswordReset(
    request: request,
    verificationCode: verificationCode,
    newPassword: newPassword,
  );

  @override
  Future<AppUser> exploreAsGuest() async {
    _unbind();
    return _inner.exploreAsGuest();
  }

  @override
  Future<void> signOut() async {
    _unbind();
    await _inner.signOut();
  }

  /// La sesión del servidor, más las sanciones que la consola mock aplica
  /// sobre la pareja. Sin lo segundo, suspender a una cuenta real desde la
  /// consola no la sacaba de la app, y esa es la demo de la consola.
  @override
  Stream<AppUser?> watchSession() {
    StreamSubscription<AppUser?>? server;
    StreamSubscription<void>? platform;
    late final StreamController<AppUser?> controller;
    controller = StreamController<AppUser?>(
      onListen: () {
        server = _inner.watchSession().listen((user) {
          if (user == null) {
            _unbind();
          } else {
            _bind(user);
          }
          controller.add(_withTwinStatus(user));
        }, onError: controller.addError);
        platform = _platform.changes.listen((_) {
          final user = _user;
          if (user == null) return;
          final current = _withTwinStatus(user);
          if (current != null && !current.isActive) controller.add(current);
        });
      },
      onCancel: () async {
        await server?.cancel();
        await platform?.cancel();
      },
    );
    return controller.stream;
  }

  @override
  Future<ModerationReason?> sanctionReason(String accountId) async {
    final twin = _twinId;
    if (twin != null && _user?.id == accountId) {
      final reason = _platform.statusReason(twin);
      if (reason != null) return reason;
    }
    return _inner.sanctionReason(accountId);
  }

  /// Una pareja sancionada en el mock no entra, igual que en el modo mock:
  /// la sanción de la consola tiene que sostenerse al volver a iniciar
  /// sesión, o la demo de suspensión se deshace sola.
  Future<AppUser> _admit(AppUser user) async {
    final twin = _twinOf(user);
    if (twin != null && !twin.isActive) {
      _unbind();
      try {
        await _inner.signOut();
      } on Failure {
        // La credencial local ya no autoriza nada.
      }
      throw const AccountSuspendedFailure('bridge');
    }
    _bind(user);
    return user;
  }

  void _bind(AppUser user) {
    _user = user;
    _twinId = _twinOf(user)?.id;
    _platform.bindSession(_twinId);
  }

  void _unbind() {
    _user = null;
    _twinId = null;
    _platform.bindSession(null);
  }

  AppUser? _twinOf(AppUser user) =>
      user.email.isEmpty ? null : _platform.accountByEmail(user.email);

  /// La cuenta real con el estado de su pareja, si la pareja está
  /// sancionada.
  AppUser? _withTwinStatus(AppUser? user) {
    final twin = _twinId == null ? null : _platform.accountById(_twinId!);
    if (user == null || twin == null || twin.isActive) return user;
    return AppUser(
      id: user.id,
      username: user.username,
      name: user.name,
      role: user.role,
      email: user.email,
      isCreator: user.isCreator,
      verification: user.verification,
      status: twin.status,
    );
  }
}
