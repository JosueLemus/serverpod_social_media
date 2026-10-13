import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_social/features/live/presentation/widgets/live_host_end_sheet.dart';

import '../../../support/app_harness.dart';

/// La hoja que el host confirma antes de salir o terminar un vivo (D6 del
/// SDD 0011). No aplica nada: devuelve lo que eligió, para que el llamador
/// decida qué hacer con el vivo.
void main() {
  /// Devuelve un getter porque la decisión se escribe recién cuando el
  /// usuario toca un botón de la hoja: devolver el valor pelado congelaría
  /// `null` para siempre.
  Future<HostLeaveChoice? Function()> openSheet(
    WidgetTester tester, {
    bool endOnly = false,
  }) async {
    HostLeaveChoice? result;
    await tester.pumpWidget(
      AppHarness.wrap(
        Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async {
                  result = await showHostEndSheet(context, endOnly: endOnly);
                },
                child: const Text('abrir'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await AppHarness.settle(tester);
    return () => result;
  }

  setUp(AppHarness.bootstrap);

  testWidgets('full sheet exposes both choices', (tester) async {
    final read = await openSheet(tester);
    expect(find.byKey(const Key('host-end-sheet-end')), findsOneWidget);
    expect(
      find.byKey(const Key('host-end-sheet-leave-on-air')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('host-end-sheet-cancel')), findsOneWidget);

    await tester.tap(find.byKey(const Key('host-end-sheet-leave-on-air')));
    await AppHarness.settle(tester);
    expect(read(), HostLeaveChoice.leaveOnAir);
  });

  testWidgets('endOnly hides the "stay on air" option', (tester) async {
    final read = await openSheet(tester, endOnly: true);
    expect(find.byKey(const Key('host-end-sheet-end')), findsOneWidget);
    expect(
      find.byKey(const Key('host-end-sheet-leave-on-air')),
      findsNothing,
    );

    await tester.tap(find.byKey(const Key('host-end-sheet-end')));
    await AppHarness.settle(tester);
    expect(read(), HostLeaveChoice.endLive);
  });

  testWidgets('cancel closes without a decision', (tester) async {
    final read = await openSheet(tester);
    await tester.tap(find.byKey(const Key('host-end-sheet-cancel')));
    await AppHarness.settle(tester);
    expect(read(), isNull);
  });
}
