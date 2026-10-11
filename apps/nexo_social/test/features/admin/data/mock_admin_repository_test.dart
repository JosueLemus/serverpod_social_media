import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_social/core/errors/failures.dart';
import 'package:nexo_social/core/mock/demo_accounts.dart';
import 'package:nexo_social/core/mock/mock_platform.dart';
import 'package:nexo_social/features/admin/data/repositories/mock_admin_repository.dart';
import 'package:nexo_social/features/auth/domain/entities/app_user.dart';
import 'package:nexo_social/features/moderation/domain/entities/moderation_action.dart';

import '../../../support/platform_harness.dart';

void main() {
  late MockPlatform platform;
  late MockAdminRepository repository;

  setUp(() async {
    platform = await platformAs(DemoAccounts.operator.id);
    repository = MockAdminRepository(platform);
  });
  tearDown(() => platform.dispose());

  /// Regresión: `MockPlatform.reset()` existía y nadie lo llamaba. Después de
  /// grabar la demo una vez, el troll quedaba suspendido para siempre.
  test('the operator can put the demo back to its seed', () async {
    await repository.suspend(DemoAccounts.troll.id, ModerationReason.spam);
    expect(
      platform.accountById(DemoAccounts.troll.id)!.status,
      AccountStatus.suspended,
    );

    await repository.resetDemo();

    expect(
      platform.accountById(DemoAccounts.troll.id)!.status,
      AccountStatus.active,
    );
    // La sesión de quien reinició sigue en pie.
    expect(platform.sessionAccountId, DemoAccounts.operator.id);
  });

  test('nobody else can', () async {
    platform.bindSession(DemoAccounts.moderator.id);

    await expectLater(repository.resetDemo(), throwsA(isA<ForbiddenFailure>()));
  });
}
