import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_social/core/mock/demo_accounts.dart';
import 'package:nexo_social/core/mock/mock_platform.dart';
import 'package:nexo_social/features/live/data/repositories/mock_live_repository.dart';
import 'package:nexo_social/features/live/domain/entities/live_permissions.dart';
import 'package:nexo_social/features/live/domain/entities/live_session.dart';
import 'package:nexo_social/features/live/presentation/bloc/live_room_cubit.dart';
import 'package:nexo_social/features/moderation/data/repositories/mock_moderation_repository.dart';

import '../../../support/platform_harness.dart';

/// La sala de un oyente frente al escenario (SDD 0011, Etapa 2). El cubit no
/// aplica nada a mano: lo que ve es lo que vuelve del "servidor".
void main() {
  late MockPlatform platform;
  late LiveRoomCubit cubit;

  /// Deja llegar el snapshot que emite el mock después de cada cambio.
  Future<void> settle() => Future<void>.delayed(Duration.zero);

  setUp(() async {
    platform = await platformAs(DemoAccounts.viewer.id);
    cubit = LiveRoomCubit(
      MockLiveRepository(platform),
      MockModerationRepository(platform),
    );
    await cubit.load('live-1');
  });

  tearDown(() async {
    await cubit.close();
    await platform.dispose();
  });

  test('el oyente ve el escenario y puede pedir la palabra', () async {
    expect(cubit.state.role, LiveRole.audience);
    expect(cubit.state.stage.speakers.single.role, LiveRole.host);
    expect(cubit.state.can(LiveAction.raiseHand), isTrue);
    expect(cubit.state.can(LiveAction.speak), isFalse);

    await cubit.raiseHand();
    await settle();

    expect(cubit.state.handRaised, isTrue);
    expect(cubit.state.isOnStage, isFalse);
  });

  test('cuando el host lo aprueba, sube y su rol cambia', () async {
    await cubit.raiseHand();
    platform
      ..bindSession(DemoAccounts.elena.id)
      ..approveRequest('live-1', DemoAccounts.viewer.id)
      ..bindSession(DemoAccounts.viewer.id);
    // El host aprobó en "otro dispositivo": la sala del oyente se entera
    // por el cambio que emite la plataforma, no por su propia acción.
    await settle();

    expect(cubit.state.role, LiveRole.cohost);
    expect(cubit.state.isOnStage, isTrue);
    expect(cubit.state.can(LiveAction.speak), isTrue);

    await cubit.toggleMyMic();
    await settle();
    expect(cubit.state.stage.me!.micMuted, isTrue);
  });

  test('un rechazo del servidor llega como motivo tipado', () async {
    await cubit.approveRequest(DemoAccounts.troll.id);

    expect(cubit.state.issue, LiveRoomIssue.forbidden);
  });
}
