import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_social/core/errors/failures.dart';
import 'package:nexo_social/core/mock/demo_accounts.dart';
import 'package:nexo_social/core/mock/mock_platform.dart';
import 'package:nexo_social/features/live/domain/entities/live_session.dart';

import 'package:shared_preferences/shared_preferences.dart';

import '../../support/platform_harness.dart';

/// El escenario del mock aplica las mismas reglas que `LiveStageService` del
/// servidor (SDD 0011). `live-1` es de Elena y arranca al aire.
void main() {
  const live = 'live-1';
  late MockPlatform platform;

  setUp(() async => platform = await platformAs(DemoAccounts.elena.id));
  tearDown(() => platform.dispose());

  void as(DemoAccount account) => platform.bindSession(account.id);

  test('un vivo al aire arranca con el host en el escenario', () {
    final stage = platform.stage(live);
    expect(stage.speakers.single.userId, DemoAccounts.elena.id);
    expect(stage.speakers.single.role, LiveRole.host);
    expect(stage.speakers.single.isMe, isTrue);
  });

  test('pedir la palabra y que el host apruebe sube al oyente', () {
    as(DemoAccounts.viewer);
    platform.raiseHand(live);
    expect(platform.stage(live).myHandRaised, isTrue);

    as(DemoAccounts.elena);
    platform.approveRequest(live, DemoAccounts.viewer.id);

    as(DemoAccounts.viewer);
    expect(platform.stage(live).meOnStage, isTrue);
    expect(platform.roleIn(live), LiveRole.cohost);
    expect(platform.stage(live).hands, isEmpty);
  });

  test('aprobar a quien no pidió la palabra es un conflicto', () {
    expect(
      () => platform.approveRequest(live, DemoAccounts.viewer.id),
      throwsA(isA<ConflictFailure>()),
    );
  });

  test('el moderador aprueba pero no invita directo', () {
    as(DemoAccounts.viewer);
    platform.raiseHand(live);
    as(DemoAccounts.moderator);
    platform.approveRequest(live, DemoAccounts.viewer.id);

    expect(
      () => platform.inviteToStage(live, DemoAccounts.troll.id),
      throwsA(isA<ForbiddenFailure>()),
    );
  });

  test('un invitado no modera el escenario', () {
    platform.inviteToStage(live, DemoAccounts.viewer.id);
    as(DemoAccounts.troll);
    platform.raiseHand(live);

    as(DemoAccounts.viewer);
    expect(
      () => platform.approveRequest(live, DemoAccounts.troll.id),
      throwsA(isA<ForbiddenFailure>()),
    );
  });

  test('silenciar a otro es suave y sólo en un sentido', () {
    platform
      ..inviteToStage(live, DemoAccounts.viewer.id)
      ..setMicMuted(live, DemoAccounts.viewer.id, muted: true);
    expect(platform.stage(live).speakers.last.micMuted, isTrue);
    expect(
      () => platform.setMicMuted(live, DemoAccounts.viewer.id, muted: false),
      throwsA(isA<ForbiddenFailure>()),
    );

    as(DemoAccounts.viewer);
    platform.setMicMuted(live, DemoAccounts.viewer.id, muted: false);
    expect(platform.stage(live).speakers.last.micMuted, isFalse);
  });

  test('nadie silencia al host', () {
    as(DemoAccounts.moderator);
    expect(
      () => platform.setMicMuted(live, DemoAccounts.elena.id, muted: true),
      throwsA(isA<ForbiddenFailure>()),
    );
  });

  test('bajarse devuelve al invitado a oyente', () {
    platform.inviteToStage(live, DemoAccounts.viewer.id);
    as(DemoAccounts.viewer);
    platform.leaveStage(live);

    expect(platform.roleIn(live), LiveRole.audience);
    expect(platform.stage(live).meOnStage, isFalse);
  });

  test('fuera del aire no hay escenario que tocar', () {
    expect(() => platform.raiseHand('live-2'), throwsA(isA<ConflictFailure>()));
  });

  test('el escenario sobrevive a recargar el estado guardado', () async {
    platform.inviteToStage(live, DemoAccounts.viewer.id);
    await Future<void>.delayed(Duration.zero);

    final reloaded = MockPlatform(await SharedPreferences.getInstance())
      ..bindSession(DemoAccounts.viewer.id);
    addTearDown(reloaded.dispose);
    expect(reloaded.stage(live).meOnStage, isTrue);
  });
}
