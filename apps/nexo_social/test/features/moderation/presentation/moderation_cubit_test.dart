import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_social/core/mock/demo_accounts.dart';
import 'package:nexo_social/core/mock/mock_platform.dart';
import 'package:nexo_social/features/moderation/data/repositories/mock_moderation_repository.dart';
import 'package:nexo_social/features/moderation/domain/entities/moderation_action.dart';
import 'package:nexo_social/features/moderation/presentation/bloc/moderation_cubit.dart';

import '../../../support/platform_harness.dart';

void main() {
  late MockPlatform platform;
  late ModerationCubit cubit;

  setUp(() async {
    platform = await platformAs(DemoAccounts.moderator.id);
    cubit = ModerationCubit(MockModerationRepository(platform));
  });

  tearDown(() async {
    await cubit.close();
    await platform.dispose();
  });

  test('the queue is ordered by severity, worst first', () async {
    await cubit.load();

    final severities = cubit.state.reports.map((report) => report.severity);
    expect(severities.first, ReportSeverity.high);
  });

  /// Two separate calls let a moderator hide a comment and leave its report
  /// open, so the next moderator reviews something already handled.
  test(
    'resolving applies the action and clears the report in one step',
    () async {
      await cubit.load();
      final report = cubit.state.reports.first;
      final before = cubit.state.reports.length;

      await cubit.resolve(report, ModerationType.hideComment);

      expect(cubit.state.reports, hasLength(before - 1));
      expect(
        cubit.state.reports.any((item) => item.id == report.id),
        isFalse,
        reason: 'El reporte resuelto sigue en la cola',
      );
      expect(cubit.state.actions, hasLength(1));
      expect(cubit.state.actions.first.type, ModerationType.hideComment);
    },
  );

  /// The audit trail is the point of the feature: an action that can be
  /// edited or deleted is not evidence.
  test('every action records who did it and why', () async {
    await cubit.load();
    await cubit.resolve(cubit.state.reports.first, ModerationType.banUser);

    final action = cubit.state.actions.single;
    expect(action.actor, '@${DemoAccounts.moderator.username}');
    expect(action.target, isNotEmpty);
  });

  test('resolving every report empties the queue but not the trail', () async {
    await cubit.load();
    for (final report in List.of(cubit.state.reports)) {
      await cubit.resolve(report, ModerationType.muteUser);
    }

    expect(cubit.state.reports, isEmpty);
    expect(cubit.state.actions, hasLength(2));
  });

  /// El permiso vive en la capa de datos. Una cuenta común que llega a la
  /// cola —escribiendo la URL a mano— recibe un rechazo, no una cola vacía.
  test('an account without the moderator scope is rejected', () async {
    platform.bindSession(DemoAccounts.viewer.id);
    await cubit.load();

    expect(cubit.state.issue, ModerationIssue.forbidden);
    expect(cubit.state.reports, isEmpty);
  });

  test('hiding from the queue hides the comment in the room', () async {
    await cubit.load();
    final report = cubit.state.reports.firstWhere(
      (item) => item.commentId == 'c-troll',
    );

    await cubit.resolve(report, ModerationType.hideComment);

    expect(
      platform.comments('live-1').map((comment) => comment.id),
      isNot(contains('c-troll')),
    );
  });

  test('dismissing closes the report and is audited too', () async {
    await cubit.load();
    await cubit.dismiss(cubit.state.reports.first);

    expect(cubit.state.reports, hasLength(1));
    expect(cubit.state.actions.single.type, ModerationType.dismissReport);
  });
}
