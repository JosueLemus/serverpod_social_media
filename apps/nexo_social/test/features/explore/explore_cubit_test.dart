import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nexo_social/core/errors/failures.dart';
import 'package:nexo_social/features/explore/domain/entities/discovery.dart';
import 'package:nexo_social/features/explore/domain/repositories/discovery_repository.dart';
import 'package:nexo_social/features/explore/presentation/bloc/explore_cubit.dart';
import 'package:nexo_social/features/live/domain/repositories/live_repository.dart';

class _MockLives extends Mock implements LiveRepository {}

class _MockDiscovery extends Mock implements DiscoveryRepository {}

const _carlos = SuggestedCreator(
  userId: 'uuid-carlos',
  username: 'carlos_mendez',
  name: 'Carlos Méndez',
  headline: 'Creador verificado',
  isVerified: true,
);

void main() {
  late _MockLives lives;
  late _MockDiscovery discovery;

  setUp(() {
    lives = _MockLives();
    discovery = _MockDiscovery();
    when(() => lives.list()).thenAnswer((_) async => const []);
    when(() => lives.changes()).thenAnswer((_) => const Stream.empty());
    when(() => discovery.trending()).thenAnswer((_) async => const []);
    when(
      () => discovery.suggestedCreators(),
    ).thenAnswer((_) async => const [_carlos]);
  });

  test('following a creator sticks when the server accepts', () async {
    when(
      () => discovery.setFollowingCreator('carlos_mendez', following: true),
    ).thenAnswer((_) async {});
    final cubit = ExploreCubit(lives, discovery);
    await cubit.load();

    await cubit.toggleCreator(_carlos);

    expect(cubit.state.creators.single.isFollowed, isTrue);
    await cubit.close();
  });

  /// Un "Siguiendo" que el servidor no registró es una mentira que se
  /// descubre al recargar: si falla, vuelve como estaba.
  test('following a creator rolls back when the server refuses', () async {
    when(
      () => discovery.setFollowingCreator('carlos_mendez', following: true),
    ).thenThrow(const NetworkFailure('offline'));
    final cubit = ExploreCubit(lives, discovery);
    await cubit.load();

    await cubit.toggleCreator(_carlos);

    expect(cubit.state.creators.single.isFollowed, isFalse);
    await cubit.close();
  });
}
