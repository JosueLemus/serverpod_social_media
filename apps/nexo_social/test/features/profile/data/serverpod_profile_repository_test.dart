import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_client/nexo_client.dart' as api;
import 'package:nexo_social/features/auth/domain/entities/app_user.dart';
import 'package:nexo_social/features/profile/data/repositories/serverpod_profile_repository.dart';

void main() {
  api.ProfileView view({
    String? bio,
    bool isCreator = true,
    api.VerificationStatus verification = api.VerificationStatus.verified,
    api.AccountStatus status = api.AccountStatus.active,
  }) => api.ProfileView(
    userId: api.UuidValue.fromString('550e8400-e29b-41d4-a716-446655440000'),
    username: 'carlos_mendez',
    displayName: 'Carlos Méndez',
    bio: bio,
    isCreator: isCreator,
    verification: verification,
    status: status,
    createdAt: DateTime.utc(2026, 9, 1),
  );

  /// Regresión: el perfil tenía a Elena escrita a mano, así que Carlos —o
  /// cualquiera— se veía como "Elena Vega, @elena_ux, 48.5K seguidores".
  test('the profile is the server account, not a hardcoded one', () {
    final profile = ServerpodProfileRepository.toProfile(
      view(bio: 'Flutter todos los días'),
    );

    expect(profile.id, '550e8400-e29b-41d4-a716-446655440000');
    expect(profile.username, 'carlos_mendez');
    expect(profile.name, 'Carlos Méndez');
    expect(profile.bio, 'Flutter todos los días');
    expect(profile.isCreator, isTrue);
    expect(profile.isVerified, isTrue);
  });

  test('the server does not count followers yet, so nothing is invented', () {
    final profile = ServerpodProfileRepository.toProfile(view());

    expect(profile.followers, isNull);
    expect(profile.following, isNull);
    expect(profile.likes, isNull);
  });

  test('a blank bio is no bio', () {
    expect(ServerpodProfileRepository.toProfile(view(bio: '  ')).bio, isNull);
  });

  test('a sanction is public', () {
    expect(
      ServerpodProfileRepository.toProfile(
        view(status: api.AccountStatus.suspended),
      ).status,
      AccountStatus.suspended,
    );
  });
}
