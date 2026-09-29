import 'dart:async';

import 'package:nexo_client/nexo_client.dart' as api;
import 'package:serverpod_auth_core_client/serverpod_auth_core_client.dart';

import '../../../../core/errors/failures.dart';
import '../../../moderation/domain/entities/moderation_action.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';

/// Thin adapter around the generated Serverpod client. It owns no JWT parsing
/// or crypto: Serverpod's [ClientAuthSessionManager] persists, refreshes and
/// attaches credentials to this one shared client.
class ServerpodAuthRepository implements AuthRepository {
  ServerpodAuthRepository(this._client, this._session, this._authEvents);

  final api.Client _client;
  final ClientAuthSessionManager _session;
  final Stream<AuthSuccess?> _authEvents;

  @override
  Future<AppUser?> currentUser() async {
    try {
      // With no saved auth info initialize performs no HTTP call. With one it
      // asks the official manager to refresh/validate it; a transient network
      // failure deliberately leaves the encrypted credential available.
      final validated = await _session.initialize();
      final auth = _session.authInfo;
      if (auth == null) return null;
      if (!validated) {
        throw const AuthenticationFailure(AuthFailureReason.network);
      }
      return toAppUser(auth);
    } on AuthenticationFailure {
      rethrow;
    } catch (error) {
      throw _failureFor(error);
    }
  }

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final success = await _client.emailIdp.login(
        email: _normalizeEmail(email),
        // Passwords are intentionally passed verbatim.
        password: password,
      );
      await _session.updateSignedInUser(success);
      return toAppUser(success, email: _normalizeEmail(email));
    } catch (error) {
      throw _failureFor(error);
    }
  }

  @override
  Future<EmailVerificationRequest> startRegistration({
    required String email,
  }) async {
    try {
      final id = await _client.emailIdp.startRegistration(
        email: _normalizeEmail(email),
      );
      return EmailVerificationRequest(id.toString());
    } catch (error) {
      throw _failureFor(error);
    }
  }

  @override
  Future<AppUser> finishRegistration({
    required EmailVerificationRequest request,
    required String verificationCode,
    required String password,
  }) async {
    try {
      // The registration token only exists in this call stack. A code can be
      // consumed by verification, therefore a failed finalisation requires a
      // fresh request rather than retrying a stale token indefinitely.
      final token = await _client.emailIdp.verifyRegistrationCode(
        accountRequestId: api.UuidValue.fromString(request.id),
        verificationCode: verificationCode.trim(),
      );
      final success = await _client.emailIdp.finishRegistration(
        registrationToken: token,
        password: password,
      );
      await _session.updateSignedInUser(success);
      return toAppUser(success);
    } catch (error) {
      throw _failureFor(error);
    }
  }

  @override
  Future<EmailVerificationRequest> startPasswordReset({
    required String email,
  }) async {
    try {
      final id = await _client.emailIdp.startPasswordReset(
        email: _normalizeEmail(email),
      );
      // This endpoint intentionally gives the same shape for known and
      // unknown emails, avoiding account enumeration.
      return EmailVerificationRequest(id.toString());
    } catch (error) {
      throw _failureFor(error);
    }
  }

  @override
  Future<void> finishPasswordReset({
    required EmailVerificationRequest request,
    required String verificationCode,
    required String newPassword,
  }) async {
    try {
      final token = await _client.emailIdp.verifyPasswordResetCode(
        passwordResetRequestId: api.UuidValue.fromString(request.id),
        verificationCode: verificationCode.trim(),
      );
      await _client.emailIdp.finishPasswordReset(
        finishPasswordResetToken: token,
        newPassword: newPassword,
      );
    } catch (error) {
      throw _failureFor(error);
    }
  }

  @override
  Future<AppUser> exploreAsGuest() async {
    // A visitor must not retain an authenticated header from a previous user.
    // The official manager clears local auth even if the remote revocation is
    // offline; guest browsing therefore never emits or persists a token.
    await _session.signOutDevice();
    return const AppUser(
      id: 'guest',
      username: 'invitado',
      name: 'Invitado',
      role: UserRole.visitor,
    );
  }

  @override
  Future<void> signOut() async {
    // Serverpod always clears local credentials, even when device revocation
    // cannot reach the server. The bool lets us preserve that truth without
    // falsely reporting remote success to the UI.
    final revoked = await _session.signOutDevice();
    if (!revoked) throw const AuthenticationFailure(AuthFailureReason.network);
  }

  @override
  Stream<AppUser?> watchSession() =>
      _authEvents.map((auth) => auth == null ? null : toAppUser(auth));

  @override
  Future<ModerationReason?> sanctionReason(String accountId) async => null;

  static String _normalizeEmail(String value) => value.trim().toLowerCase();

  /// Serverpod scopes are server-signed. `admin` is intentionally translated
  /// to Nexo's `operator`; creator remains a separate profile capability and
  /// is false until a dedicated, authorised Nexo profile endpoint exists.
  static AppUser toAppUser(AuthSuccess auth, {String email = ''}) {
    final id = auth.authUserId.toString();
    final role = auth.scopeNames.contains('admin')
        ? UserRole.operator
        : auth.scopeNames.contains('moderator')
        ? UserRole.moderator
        : UserRole.user;
    // Full UUID-derived value avoids a client-only collision guarantee. A
    // future editable username needs its own normalised, database-unique
    // Nexo profile field rather than truncating this stable fallback.
    final alias = id.replaceAll('-', '');
    return AppUser(
      id: id,
      username: 'nexo_$alias',
      name: 'Miembro Nexo',
      email: email,
      role: role,
      isCreator: false,
      // Email ownership is not the product's creator verification badge.
      verification: VerificationStatus.none,
      status: AccountStatus.active,
    );
  }

  static Failure _failureFor(Object error) {
    final type = error.runtimeType.toString().toLowerCase();
    if (type.contains('blocked')) {
      return const AccountSuspendedFailure('blocked');
    }
    if (type.contains('invalidcredentials')) {
      return const AuthenticationFailure(AuthFailureReason.invalidCredentials);
    }
    if (type.contains('toomanyattempts')) {
      return const AuthenticationFailure(AuthFailureReason.tooManyAttempts);
    }
    if (type.contains('expired')) {
      return const AuthenticationFailure(AuthFailureReason.expiredCode);
    }
    if (type.contains('policyviolation')) {
      return const AuthenticationFailure(AuthFailureReason.passwordPolicy);
    }
    if (type.contains('invalid')) {
      return const AuthenticationFailure(AuthFailureReason.invalidCode);
    }
    if (error is api.ServerpodClientException || type.contains('socket')) {
      return const AuthenticationFailure(AuthFailureReason.network);
    }
    return const AuthenticationFailure(AuthFailureReason.unavailable);
  }
}
