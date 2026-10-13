import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_social/features/appearance/data/repositories/local_theme_preference_repository.dart';
import 'package:nexo_social/features/appearance/presentation/bloc/theme_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferences preferences;

  Future<LocalThemePreferenceRepository> repository([
    Map<String, Object> seed = const {},
  ]) async {
    SharedPreferences.setMockInitialValues(seed);
    preferences = await SharedPreferences.getInstance();
    return LocalThemePreferenceRepository(preferences);
  }

  test('sin elección guardada, arranca en el tema por defecto', () async {
    final cubit = ThemeCubit(await repository(), defaultId: 'aurora');
    expect(cubit.state.themeId, 'aurora');
  });

  test('arranca en el tema guardado, antes del primer frame', () async {
    final cubit = ThemeCubit(
      await repository({'appearance.theme_id': 'editorial'}),
      defaultId: 'aurora',
    );
    expect(cubit.state.themeId, 'editorial');
  });

  group('select', () {
    late LocalThemePreferenceRepository repo;
    setUp(() async => repo = await repository());

    blocTest<ThemeCubit, ThemeState>(
      'emite el tema elegido y lo guarda',
      build: () => ThemeCubit(repo, defaultId: 'aurora'),
      act: (cubit) => cubit.select('neon'),
      expect: () => const [ThemeState('neon')],
      verify: (_) =>
          expect(preferences.getString('appearance.theme_id'), 'neon'),
    );

    blocTest<ThemeCubit, ThemeState>(
      'elegir el tema en uso no emite ni escribe',
      build: () => ThemeCubit(repo, defaultId: 'aurora'),
      act: (cubit) => cubit.select('aurora'),
      expect: () => const <ThemeState>[],
      verify: (_) => expect(preferences.getString('appearance.theme_id'), null),
    );
  });
}
