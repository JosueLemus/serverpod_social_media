import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_social/core/errors/failures.dart';
import 'package:nexo_social/core/mock/demo_accounts.dart';
import 'package:nexo_social/core/mock/mock_platform.dart';
import 'package:nexo_social/features/auth/data/repositories/bridged_auth_repository.dart';
import 'package:nexo_social/features/auth/domain/entities/app_user.dart';
import 'package:nexo_social/features/auth/domain/repositories/auth_repository.dart';
import 'package:nexo_social/features/live/domain/entities/live_session.dart';
import 'package:nexo_social/features/moderation/domain/entities/moderation_action.dart';

import '../../../support/platform_harness.dart';

/// El servidor de verdad, reducido a lo que el puente necesita: devuelve la
/// cuenta que le pidan y avisa los cambios de sesión.
class _FakeServerAuth implements AuthRepository {
  _FakeServerAuth(this.user);

  AppUser? user;
  var signedOut = false;
  final sessions = StreamController<AppUser?>.broadcast();

  @override
  Future<AppUser?> currentUser() async => user;

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async => user!;

  @override
  Future<void> signOut() async {
    signedOut = true;
    user = null;
  }

  @override
  Stream<AppUser?> watchSession() => sessions.stream;

  @override
  Future<ModerationReason?> sanctionReason(String accountId) async => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

AppUser _real(String email, {String id = 'uuid-1'}) => AppUser(
  id: id,
  username: 'real',
  name: 'Cuenta real',
  email: email,
  role: UserRole.user,
  isCreator: true,
  verification: VerificationStatus.verified,
);

void main() {
  late MockPlatform platform;

  setUp(() async => platform = await platformAs(null));
  tearDown(() => platform.dispose());

  test('a real account acts as its mock twin, matched by email', () async {
    final bridge = BridgedAuthRepository(
      _FakeServerAuth(_real(DemoAccounts.elena.email)),
      platform,
    );

    await bridge.signIn(email: DemoAccounts.elena.email, password: 'x');

    expect(platform.sessionAccountId, DemoAccounts.elena.id);
    // Lo que antes respondía "sin permiso": el host inicia su vivo.
    expect(
      platform.transitionLive('live-2', LiveStatus.live).status,
      LiveStatus.live,
    );
  });

  test('restoring the session binds it too', () async {
    final bridge = BridgedAuthRepository(
      _FakeServerAuth(_real(DemoAccounts.moderator.email)),
      platform,
    );

    await bridge.currentUser();

    expect(platform.sessionAccountId, DemoAccounts.moderator.id);
  });

  test('an account without a twin stays without an actor', () async {
    final bridge = BridgedAuthRepository(
      _FakeServerAuth(_real('nueva@example.com')),
      platform,
    );

    await bridge.signIn(email: 'nueva@example.com', password: 'x');

    expect(platform.sessionAccountId, isNull);
  });

  test('signing out unbinds', () async {
    final bridge = BridgedAuthRepository(
      _FakeServerAuth(_real(DemoAccounts.elena.email)),
      platform,
    );
    await bridge.signIn(email: DemoAccounts.elena.email, password: 'x');

    await bridge.signOut();

    expect(platform.sessionAccountId, isNull);
  });

  test('a twin sanctioned in the console cannot sign in again', () async {
    platform
      ..bindSession(DemoAccounts.operator.id)
      ..suspend(DemoAccounts.troll.id, ModerationReason.harassment);
    final server = _FakeServerAuth(_real(DemoAccounts.troll.email));
    final bridge = BridgedAuthRepository(server, platform);

    await expectLater(
      bridge.signIn(email: DemoAccounts.troll.email, password: 'x'),
      throwsA(isA<AccountSuspendedFailure>()),
    );
    expect(server.signedOut, isTrue);
    expect(platform.sessionAccountId, isNull);
  });

  test('a suspension in the console reaches the real session', () async {
    final bridge = BridgedAuthRepository(
      _FakeServerAuth(_real(DemoAccounts.troll.email)),
      platform,
    );
    final sessions = <AppUser?>[];
    final subscription = bridge.watchSession().listen(sessions.add);
    await bridge.signIn(email: DemoAccounts.troll.email, password: 'x');

    // Otra pestaña, la del operador, suspende a la pareja.
    platform
      ..bindSession(DemoAccounts.operator.id)
      ..suspend(DemoAccounts.troll.id, ModerationReason.harassment);
    await pumpEventQueue();

    expect(sessions.last?.status, AccountStatus.suspended);
    expect(await bridge.sanctionReason('uuid-1'), ModerationReason.harassment);
    await subscription.cancel();
  });
}
