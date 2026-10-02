import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_client/nexo_client.dart' as api;
import 'package:nexo_social/features/auth/data/repositories/serverpod_auth_repository.dart';
import 'package:nexo_social/features/auth/domain/entities/app_user.dart';

void main() {
  api.AccountView account({
    String id = '550e8400-e29b-41d4-a716-446655440000',
    String username = 'elena_ux',
    String displayName = 'Elena Vega',
    bool isCreator = false,
    api.VerificationStatus verification = api.VerificationStatus.none,
    api.AccountStatus status = api.AccountStatus.active,
    bool isModerator = false,
    bool isAdmin = false,
  }) => api.AccountView(
    profile: api.ProfileView(
      userId: api.UuidValue.fromString(id),
      username: username,
      displayName: displayName,
      isCreator: isCreator,
      verification: verification,
      status: status,
      createdAt: DateTime.utc(2026, 9, 1),
    ),
    email: 'elena@example.com',
    isModerator: isModerator,
    isAdmin: isAdmin,
  );

  /// Regresión: el usuario real se mapeaba desde el token, así que toda
  /// cuenta se llamaba "Miembro Nexo", tenía un usuario inventado y nunca era
  /// creadora — nadie podía transmitir.
  test('the user comes from the server profile, not from the token', () {
    final user = ServerpodAuthRepository.fromAccount(
      account(isCreator: true, verification: api.VerificationStatus.verified),
    );

    expect(user.id, '550e8400-e29b-41d4-a716-446655440000');
    expect(user.username, 'elena_ux');
    expect(user.name, 'Elena Vega');
    expect(user.email, 'elena@example.com');
    expect(user.isCreator, isTrue);
    expect(user.verification, VerificationStatus.verified);
    expect(user.role, UserRole.user);
  });

  test('admin maps to operator and wins over moderator', () {
    expect(
      ServerpodAuthRepository.fromAccount(
        account(isAdmin: true, isModerator: true),
      ).role,
      UserRole.operator,
    );
    expect(
      ServerpodAuthRepository.fromAccount(account(isModerator: true)).role,
      UserRole.moderator,
    );
  });

  test('a sanction on the server reaches the session', () {
    final user = ServerpodAuthRepository.fromAccount(
      account(status: api.AccountStatus.suspended),
    );

    expect(user.status, AccountStatus.suspended);
    expect(user.isActive, isFalse);
  });
}
