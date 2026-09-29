import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_social/features/auth/data/repositories/serverpod_auth_repository.dart';
import 'package:nexo_social/features/auth/domain/entities/app_user.dart';
import 'package:serverpod_auth_core_client/serverpod_auth_core_client.dart';

void main() {
  AuthSuccess auth(String id, Set<String> scopes) => AuthSuccess(
    authStrategy: 'jwt',
    token: 'not-a-real-token',
    refreshToken: 'not-a-real-refresh-token',
    authUserId: UuidValue.fromString(id),
    scopeNames: scopes,
  );

  test(
    'preserves the Serverpod UUID and maps admin only from signed scopes',
    () {
      final user = ServerpodAuthRepository.toAppUser(
        auth('550e8400-e29b-41d4-a716-446655440000', {'admin'}),
      );

      expect(user.id, '550e8400-e29b-41d4-a716-446655440000');
      expect(user.role, UserRole.operator);
      expect(user.isCreator, isFalse);
      expect(user.verification, VerificationStatus.none);
    },
  );

  test('two authenticated accounts keep distinct stable identities', () {
    final first = ServerpodAuthRepository.toAppUser(
      auth('550e8400-e29b-41d4-a716-446655440000', const {}),
    );
    final second = ServerpodAuthRepository.toAppUser(
      auth('550e8400-e29b-41d4-a716-446655440001', {'moderator'}),
    );

    expect(first.id, isNot(second.id));
    expect(first.username, isNot(second.username));
    expect(second.role, UserRole.moderator);
  });
}
