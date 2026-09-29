import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_social/core/mock/demo_accounts.dart';
import 'package:nexo_social/core/mock/mock_platform.dart';
import 'package:nexo_social/core/storage/session_storage.dart';
import 'package:nexo_social/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:nexo_social/features/auth/data/repositories/mock_auth_repository.dart';
import 'package:nexo_social/features/auth/domain/entities/app_user.dart';
import 'package:nexo_social/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:nexo_social/features/moderation/domain/entities/moderation_action.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late MockPlatform platform;
  late AuthCubit cubit;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    platform = MockPlatform(preferences);
    cubit = AuthCubit(
      MockAuthRepository(
        AuthLocalDataSource(SessionStorage(preferences)),
        platform,
      ),
    );
  });

  tearDown(() async {
    await cubit.close();
    await platform.dispose();
  });

  test('the demo email picks the seeded account and its role', () async {
    await cubit.signIn(DemoAccounts.operator.email, 'demo');

    final state = cubit.state as AuthAuthenticated;
    expect(state.user.role, UserRole.operator);
  });

  test('an unknown email still signs in as Elena, the demo account', () async {
    await cubit.signIn('alguien@otro.com', 'x');

    final state = cubit.state as AuthAuthenticated;
    expect(state.user.username, DemoAccounts.elena.username);
  });

  /// El momento de la demo: el operador suspende desde otra sesión y esta
  /// queda afuera sola, sin tocar nada.
  test('a suspension applied elsewhere revokes this session at once', () async {
    await cubit.signIn(DemoAccounts.troll.email, 'demo');

    // Otra sesión —la del operador— actúa sobre el mismo servidor.
    platform
      ..bindSession(DemoAccounts.operator.id)
      ..suspend(DemoAccounts.troll.id, ModerationReason.harassment)
      ..bindSession(DemoAccounts.troll.id);
    await Future<void>.delayed(Duration.zero);

    expect(
      cubit.state,
      const AuthSuspended(
        status: AccountStatus.suspended,
        reason: ModerationReason.harassment,
      ),
    );
  });

  test('a suspended account cannot sign in again', () async {
    platform
      ..bindSession(DemoAccounts.operator.id)
      ..ban(DemoAccounts.troll.id, ModerationReason.spam);

    await cubit.signIn(DemoAccounts.troll.email, 'demo');

    expect(cubit.state, isA<AuthSuspended>());
  });

  test('a revoked verification reaches the session', () async {
    await cubit.signIn(DemoAccounts.elena.email, 'demo');

    platform
      ..bindSession(DemoAccounts.operator.id)
      ..setVerification(
        DemoAccounts.elena.id,
        verified: false,
        reason: ModerationReason.impersonation,
      )
      ..bindSession(DemoAccounts.elena.id);
    await Future<void>.delayed(Duration.zero);

    final state = cubit.state as AuthAuthenticated;
    expect(state.user.verification, VerificationStatus.revoked);
  });
}
