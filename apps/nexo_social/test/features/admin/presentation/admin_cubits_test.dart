import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_social/core/mock/demo_accounts.dart';
import 'package:nexo_social/core/mock/mock_platform.dart';
import 'package:nexo_social/features/admin/data/repositories/mock_admin_repository.dart';
import 'package:nexo_social/features/admin/domain/entities/account_detail.dart';
import 'package:nexo_social/features/admin/domain/entities/audit_entry.dart';
import 'package:nexo_social/features/admin/presentation/bloc/account_detail_cubit.dart';
import 'package:nexo_social/features/admin/presentation/bloc/admin_console_cubit.dart';
import 'package:nexo_social/features/admin/presentation/bloc/audit_log_cubit.dart';
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

  group('AdminConsoleCubit', () {
    test('an operator reads accounts, creators and active lives', () async {
      final cubit = AdminConsoleCubit(repository);
      addTearDown(cubit.close);

      await cubit.load();

      expect(cubit.state.isLoading, isFalse);
      expect(cubit.state.accounts, isNotEmpty);
      expect(cubit.state.creators.map((user) => user.username), [
        DemoAccounts.carlos.username,
        DemoAccounts.elena.username,
      ]);
      expect(cubit.state.lives.map((live) => live.id), ['live-1', 'live-4']);
    });

    test('searching by email narrows the list', () async {
      final cubit = AdminConsoleCubit(repository);
      addTearDown(cubit.close);
      await cubit.load();

      await cubit.search(DemoAccounts.troll.email);

      expect(cubit.state.accounts.single.id, DemoAccounts.troll.id);
    });

    /// Llegar a `/admin` escribiendo la URL no alcanza: el servidor dice que
    /// no, y la consola lo muestra en vez de una lista vacía.
    test('a non-operator is refused by the server', () async {
      platform.bindSession(DemoAccounts.elena.id);
      final cubit = AdminConsoleCubit(repository);
      addTearDown(cubit.close);

      await cubit.load();

      expect(cubit.state.isForbidden, isTrue);
    });

    test('revoking a verification is confirmed and reflected', () async {
      final cubit = AdminConsoleCubit(repository);
      addTearDown(cubit.close);
      await cubit.load();
      final elena = cubit.state.creators.firstWhere(
        (user) => user.id == DemoAccounts.elena.id,
      );

      await cubit.setVerification(
        elena,
        verified: false,
        reason: ModerationReason.impersonation,
      );

      expect(cubit.state.notice, AdminNotice.verificationRevoked);
      expect(
        cubit.state.creators
            .firstWhere((user) => user.id == elena.id)
            .verification,
        VerificationStatus.revoked,
      );
    });

    test('force-ending a live takes it off the active list', () async {
      final cubit = AdminConsoleCubit(repository);
      addTearDown(cubit.close);
      await cubit.load();

      await cubit.forceEndLive(
        cubit.state.lives.first,
        ModerationReason.violence,
      );

      expect(cubit.state.notice, AdminNotice.liveEnded);
      expect(cubit.state.lives, hasLength(1));
    });
  });

  group('AccountDetailCubit', () {
    test('suspending records the sanction in the history', () async {
      final cubit = AccountDetailCubit(repository, DemoAccounts.troll.id);
      addTearDown(cubit.close);
      await cubit.load();

      await cubit.suspend(ModerationReason.harassment);

      final detail = cubit.state.detail!;
      expect(detail.user.status, AccountStatus.suspended);
      expect(detail.sanctions.single.kind, SanctionKind.suspension);
      expect(cubit.state.notice, AdminNotice.suspended);
    });

    test('restoring a ban is refused with a typed reason', () async {
      final cubit = AccountDetailCubit(repository, DemoAccounts.troll.id);
      addTearDown(cubit.close);
      await cubit.load();

      await cubit.ban(ModerationReason.harassment);
      await cubit.restore();

      expect(cubit.state.issue, AdminIssue.conflict);
      expect(cubit.state.detail!.user.status, AccountStatus.banned);
    });

    test('an operator account cannot be sanctioned', () async {
      final cubit = AccountDetailCubit(repository, DemoAccounts.operator.id);
      addTearDown(cubit.close);
      await cubit.load();

      await cubit.suspend(ModerationReason.other);

      expect(cubit.state.issue, AdminIssue.forbidden);
    });
  });

  group('AuditLogCubit', () {
    test('lists newest first and filters by entity', () async {
      platform
        ..suspend(DemoAccounts.troll.id, ModerationReason.harassment)
        ..forceEndLive('live-4', ModerationReason.violence);
      final cubit = AuditLogCubit(repository);
      addTearDown(cubit.close);

      await cubit.load();
      expect(cubit.state.entries.first.action, AuditAction.liveForceEnded);

      await cubit.load(const AuditFilter(entity: AuditEntity.account));
      expect(cubit.state.entries.single.action, AuditAction.accountSuspended);
    });

    test('paginates by cursor', () async {
      for (var i = 0; i < 25; i++) {
        platform
          ..setVerification(
            DemoAccounts.carlos.id,
            verified: false,
            reason: ModerationReason.other,
          )
          ..setVerification(DemoAccounts.carlos.id, verified: true);
      }
      final cubit = AuditLogCubit(repository);
      addTearDown(cubit.close);

      await cubit.load();
      expect(cubit.state.entries, hasLength(20));
      expect(cubit.state.hasMore, isTrue);

      await cubit.loadMore();
      expect(cubit.state.entries, hasLength(40));
    });
  });
}
