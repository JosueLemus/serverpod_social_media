import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_social/app/app.dart';
import 'package:nexo_social/app/di/injection.dart';
import 'package:nexo_social/app/theme/app_tokens.dart';
import 'package:nexo_social/app/theme/nexo_themes.dart';
import 'package:nexo_social/features/appearance/presentation/bloc/theme_cubit.dart';
import 'package:nexo_social/features/appearance/presentation/pages/themes_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/app_harness.dart';

/// Un widget que lee [AppColors] directo, sin `Theme.of`: como casi toda la
/// app. Es el caso que un `ThemeData` nuevo, por sí solo, no redibuja.
class _ReadsPalette extends StatelessWidget {
  const _ReadsPalette();

  @override
  Widget build(BuildContext context) => ColoredBox(
    key: const Key('reads-palette'),
    color: AppColors.background,
    child: const SizedBox(width: 10, height: 10),
  );
}

void main() {
  setUp(AppHarness.bootstrap);
  tearDown(() => NexoThemes.activate(NexoThemes.byId(NexoThemes.defaultId)));

  testWidgets('tocar un tema lo elige y lo guarda', (tester) async {
    tester.view.physicalSize = const Size(1200, 4000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final cubit = sl<ThemeCubit>();

    await tester.pumpWidget(
      BlocProvider.value(
        value: cubit,
        child: AppHarness.wrap(const ThemesPage()),
      ),
    );
    await AppHarness.settle(tester);
    expect(find.text('Aurora'), findsWidgets);

    await tester.tap(find.byKey(const Key('theme-editorial')));
    await AppHarness.settle(tester);

    expect(cubit.state.themeId, 'editorial');
    expect(
      sl<SharedPreferences>().getString('appearance.theme_id'),
      'editorial',
    );
  });

  testWidgets(
    'cambiar de tema redibuja hasta lo que lee AppColors sin Theme.of',
    (tester) async {
      await tester.pumpWidget(const NexoApp());
      await AppHarness.settle(tester);
      // Montado debajo de la raíz, como cualquier pantalla.
      final root = tester.element(find.byType(Navigator).first);
      final overlay = OverlayEntry(builder: (_) => const _ReadsPalette());
      Navigator.of(root).overlay!.insert(overlay);
      await tester.pump();

      Color painted() => tester
          .widget<ColoredBox>(find.byKey(const Key('reads-palette')))
          .color;
      expect(painted(), NexoThemes.byId('aurora').palette.liner);

      sl<ThemeCubit>().select('editorial');
      await tester.pump();

      expect(painted(), NexoThemes.byId('editorial').palette.liner);
      overlay.remove();
      // Las entradas de animate_do agendan su retardo al reconstruirse.
      await AppHarness.settle(tester);
    },
  );
}
