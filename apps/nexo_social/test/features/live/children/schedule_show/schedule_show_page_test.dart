import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_social/app/di/injection.dart';
import 'package:nexo_social/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:nexo_social/features/live/presentation/children/schedule_show/presentation/pages/schedule_show_page.dart';

import '../../../../support/app_harness.dart';

void main() {
  setUp(() async {
    await AppHarness.bootstrap(
      initialPreferences: {
        'mock_session':
            '{"id":"creator-1","username":"elena_ux","name":"Elena Vega","role":"creator"}',
      },
    );
    await sl<AuthCubit>().restore();
  });

  Future<void> pumpPage(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(AppHarness.wrap(const ScheduleShowPage()));
    await AppHarness.settle(tester);
  }

  FilledButton submit(WidgetTester tester) =>
      tester.widget<FilledButton>(find.byKey(const Key('schedule-submit')));

  /// `animate_do` agenda un `Future.delayed` con el stagger en cada `build`,
  /// aunque la animación ya haya terminado. Cada emisión del cubit
  /// reconstruye las secciones, así que sin esto el test termina con un timer
  /// pendiente.
  Future<void> drainStagger(WidgetTester tester) =>
      tester.pump(const Duration(seconds: 1));

  testWidgets('the CTA stays off until the show has a title', (tester) async {
    await pumpPage(tester);

    expect(submit(tester).onPressed, isNull);
    expect(
      find.text('Ponle un título a tu show para agendarlo.'),
      findsOneWidget,
    );

    await tester.enterText(
      find.byKey(const Key('schedule-title-field')),
      'Masterclass de Flutter',
    );
    await AppHarness.settle(tester);

    expect(submit(tester).onPressed, isNotNull);
    // La vista previa sale del mismo borrador que se va a agendar.
    expect(find.text('Masterclass de Flutter'), findsWidgets);
    await drainStagger(tester);
  });

  testWidgets('the formatting bar inserts Markdown', (tester) async {
    await pumpPage(tester);

    await tester.tap(find.byKey(const Key('schedule-format-list')));
    await AppHarness.settle(tester);

    final field = tester.widget<TextField>(
      find.byKey(const Key('schedule-description-field')),
    );
    expect(field.controller!.text, '- ');
    await drainStagger(tester);
  });

  testWidgets('the draft status only claims "saved" once it is', (
    tester,
  ) async {
    await pumpPage(tester);
    expect(find.text('Nuevo borrador'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('schedule-title-field')),
      'Show',
    );
    await tester.pump();
    expect(find.text('Guardando…'), findsOneWidget);

    await AppHarness.settle(tester);
    expect(find.text('Borrador guardado'), findsOneWidget);
    await drainStagger(tester);
  });
}
