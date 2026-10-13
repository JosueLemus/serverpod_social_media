import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_social/core/errors/failures.dart';
import 'package:nexo_social/core/mock/demo_accounts.dart';
import 'package:nexo_social/features/live/data/repositories/mock_live_repository.dart';
import 'package:nexo_social/features/live/domain/entities/live_reaction.dart';
import 'package:nexo_social/features/live/domain/entities/live_session.dart';

import '../../../support/platform_harness.dart';

/// Throttle de reacciones del mock (D7 del SDD 0011): 1 cada 300 ms por
/// cuenta y vivo. El exceso levanta `RateLimitedFailure` para que el cubit la
/// descarte en silencio (no es error del usuario, es nuestra regla).
void main() {
  test('two reactions within the throttle window are rejected', () async {
    var now = DateTime(2026, 10, 12, 20);
    final platform = await platformAs(DemoAccounts.elena.id);
    // Transmitir ahora: el vivo tiene que estar al aire para aceptar
    // reacciones.
    final lives = MockLiveRepository(platform, now: () => now);
    for (final live in await lives.mine()) {
      if (live.status == LiveStatus.live) {
        await lives.transition(live.id, LiveStatus.recorded);
      }
    }
    final show = await lives.goLive('Charlemos');

    await lives.react(show.id, LiveReactionKind.heart);
    now = now.add(const Duration(milliseconds: 100));
    await expectLater(
      lives.react(show.id, LiveReactionKind.heart),
      throwsA(isA<RateLimitedFailure>()),
    );

    // Fuera de la ventana, pasa.
    now = now.add(const Duration(milliseconds: 300));
    await lives.react(show.id, LiveReactionKind.heart);
  });

  test('reacting on a non-live show is a conflict', () async {
    final platform = await platformAs(DemoAccounts.elena.id);
    final lives = MockLiveRepository(platform);
    // Un vivo programado (no al aire) no acepta reacciones.
    final scheduled = (await lives.list()).firstWhere(
      (live) => live.status == LiveStatus.scheduled,
    );
    await expectLater(
      lives.react(scheduled.id, LiveReactionKind.heart),
      throwsA(isA<ConflictFailure>()),
    );
  });
}
