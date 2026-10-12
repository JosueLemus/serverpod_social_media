import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_social/core/errors/failures.dart';
import 'package:nexo_social/core/mock/demo_accounts.dart';
import 'package:nexo_social/core/mock/mock_platform.dart';
import 'package:nexo_social/features/live/data/repositories/mock_live_repository.dart';
import 'package:nexo_social/features/live/domain/entities/live_media_grant.dart';
import 'package:nexo_social/features/live/domain/entities/live_session.dart';

import '../../../support/platform_harness.dart';

/// [accountId] sin vivos al aire: la semilla deja a Elena y a Carlos al
/// aire, y un segundo vivo es justo lo que la regla rechaza.
Future<(MockPlatform, MockLiveRepository)> offAir(String accountId) async {
  final platform = await platformAs(accountId);
  final lives = MockLiveRepository(platform);
  for (final live in await lives.mine()) {
    if (live.status == LiveStatus.live) {
      await lives.transition(live.id, LiveStatus.recorded);
    }
  }
  return (platform, lives);
}

/// El mock aplica las mismas reglas que el servidor para "Transmitir ahora"
/// y para el rol de video: la app se comporta igual con los dos.
void main() {
  test('going live now creates a show already on air', () async {
    final lives = MockLiveRepository(await platformAs(DemoAccounts.carlos.id));
    // Carlos arranca con un vivo al aire en la semilla: se termina primero.
    for (final live in await lives.mine()) {
      if (live.status == LiveStatus.live) {
        await lives.transition(live.id, LiveStatus.recorded);
      }
    }

    final show = await lives.goLive('Probando');

    expect(show.status, LiveStatus.live);
    expect(show.title, 'Probando');
    expect((await lives.mine()).map((live) => live.id), contains(show.id));
  });

  test('going live with another show on air is a conflict', () async {
    final (_, lives) = await offAir(DemoAccounts.elena.id);
    await lives.goLive('Primero');

    await expectLater(lives.goLive('Segundo'), throwsA(isA<ConflictFailure>()));
  });

  test('only the host on air gets to publish', () async {
    final (platform, lives) = await offAir(DemoAccounts.elena.id);
    final show = await lives.goLive('En vivo');

    final host = await lives.mediaToken(show.id);
    platform.bindSession(DemoAccounts.viewer.id);
    final viewer = await lives.mediaToken(show.id);

    expect(host.role, LiveMediaGrantRole.publisher);
    expect(host.channel, startsWith('nexo_live_'));
    expect(viewer.role, LiveMediaGrantRole.subscriber);
  });

  test('an ended show has no video to join', () async {
    final (_, lives) = await offAir(DemoAccounts.elena.id);
    final show = await lives.goLive('Corto');
    await lives.transition(show.id, LiveStatus.recorded);

    await expectLater(
      lives.mediaToken(show.id),
      throwsA(isA<ConflictFailure>()),
    );
  });
}
