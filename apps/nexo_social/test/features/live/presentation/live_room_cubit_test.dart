import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_social/core/mock/demo_accounts.dart';
import 'package:nexo_social/core/mock/mock_platform.dart';
import 'package:nexo_social/features/live/data/repositories/mock_live_repository.dart';
import 'package:nexo_social/features/live/domain/entities/live_session.dart';
import 'package:nexo_social/features/live/presentation/bloc/live_room_cubit.dart';
import 'package:nexo_social/features/moderation/data/repositories/mock_moderation_repository.dart';
import 'package:nexo_social/features/moderation/domain/entities/moderation_action.dart';

import '../../../support/platform_harness.dart';

void main() {
  late MockPlatform platform;
  late LiveRoomCubit cubit;

  setUp(() async {
    platform = await platformAs(DemoAccounts.elena.id);
    cubit = LiveRoomCubit(
      MockLiveRepository(platform),
      MockModerationRepository(platform),
    );
  });

  tearDown(() async {
    await cubit.close();
    await platform.dispose();
  });

  test('a verified host starts the live', () async {
    await cubit.load('live-2');
    await cubit.transition(LiveStatus.live);

    expect(cubit.state.session!.status, LiveStatus.live);
    expect(cubit.state.issue, isNull);
  });

  /// Paso 7 del guion: el botón sigue ahí, y lo que rechaza es el servidor.
  test('an unverified host is rejected with a typed reason', () async {
    platform
      ..bindSession(DemoAccounts.operator.id)
      ..setVerification(
        DemoAccounts.elena.id,
        verified: false,
        reason: ModerationReason.impersonation,
      )
      ..bindSession(DemoAccounts.elena.id);

    await cubit.load('live-2');
    await cubit.transition(LiveStatus.live);

    expect(cubit.state.issue, LiveRoomIssue.notVerified);
    expect(cubit.state.session!.status, LiveStatus.scheduled);
  });

  test('the same rejection twice is reported twice', () async {
    platform
      ..bindSession(DemoAccounts.operator.id)
      ..setVerification(
        DemoAccounts.elena.id,
        verified: false,
        reason: ModerationReason.impersonation,
      )
      ..bindSession(DemoAccounts.elena.id);
    await cubit.load('live-2');

    await cubit.transition(LiveStatus.live);
    final first = cubit.state.issueSerial;
    await cubit.transition(LiveStatus.live);

    expect(cubit.state.issueSerial, first + 1);
  });

  test('a comment hidden from the console leaves the room', () async {
    await cubit.load('live-1');
    expect(cubit.state.comments.map((c) => c.id), contains('c-troll'));

    platform
      ..bindSession(DemoAccounts.operator.id)
      ..resolveReport(
        'report-1',
        const ModerationDecision(type: ModerationType.hideComment),
      );
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.comments.map((c) => c.id), isNot(contains('c-troll')));
  });

  test('a live ended by an operator says so', () async {
    await cubit.load('live-1');

    platform
      ..bindSession(DemoAccounts.operator.id)
      ..forceEndLive('live-1', ModerationReason.violence);
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.session!.endedByModeration, isTrue);
  });

  test('a viewer can only report, and the report reaches the queue', () async {
    platform.bindSession(DemoAccounts.viewer.id);
    await cubit.load('live-1');
    expect(cubit.state.canModerate, isFalse);

    await cubit.reportComment(cubit.state.comments.first);

    platform.bindSession(DemoAccounts.moderator.id);
    expect(platform.openReports(), hasLength(3));
  });
}
