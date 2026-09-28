import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_social/app/di/injection.dart';
import 'package:nexo_social/core/mock/demo_accounts.dart';
import 'package:nexo_social/features/admin/presentation/pages/account_detail_page.dart';
import 'package:nexo_social/features/admin/presentation/pages/admin_console_page.dart';
import 'package:nexo_social/features/auth/presentation/bloc/auth_cubit.dart';

import '../../../support/app_harness.dart';

/// La consola también es móvil (D8), así que entra en la misma regla que el
/// resto: nada desborda a 320.
void main() {
  Future<void> signInAs(String accountId) async {
    await AppHarness.bootstrap(
      initialPreferences: {'mock_session': '{"id":"$accountId"}'},
    );
    await sl<AuthCubit>().restore();
  }

  Future<void> pumpAt(WidgetTester tester, Widget page, double width) async {
    tester.view.physicalSize = Size(width, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(AppHarness.wrap(page));
    await AppHarness.settle(tester);
  }

  for (final width in [320.0, 1280.0]) {
    group('a ${width.toInt()} de ancho', () {
      setUp(() => signInAs(DemoAccounts.operator.id));

      testWidgets('cada sección de la consola dibuja sin desbordar', (
        tester,
      ) async {
        await pumpAt(tester, const AdminConsolePage(), width);
        expect(find.text('Cola de reportes'), findsOneWidget);

        for (final section in AdminSection.values) {
          await tester.tap(find.byKey(Key('admin-section-${section.name}')));
          await AppHarness.settle(tester);
          expect(tester.takeException(), isNull, reason: section.label);
        }
      });

      testWidgets('la ficha de cuenta dibuja sin desbordar', (tester) async {
        await pumpAt(
          tester,
          const AccountDetailPage(accountId: 'user-troll'),
          width,
        );

        expect(find.text('Historial de sanciones'), findsOneWidget);
        expect(find.byKey(const Key('account-suspend')), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    });
  }

  testWidgets('suspender pide el motivo y lo confirma', (tester) async {
    await signInAs(DemoAccounts.operator.id);
    await pumpAt(tester, const AccountDetailPage(accountId: 'user-troll'), 390);

    await tester.tap(find.byKey(const Key('account-suspend')));
    await AppHarness.settle(tester);
    // Sin motivo no hay confirmación posible.
    final confirm = tester.widget<FilledButton>(
      find.byKey(const Key('reason-confirm')),
    );
    expect(confirm.onPressed, isNull);

    await tester.tap(find.byKey(const Key('reason-harassment')));
    await AppHarness.settle(tester);
    await tester.tap(find.byKey(const Key('reason-confirm')));
    await AppHarness.settle(tester);

    expect(find.byKey(const Key('account-restore')), findsOneWidget);
  });

  testWidgets('una cuenta sin scope ve el rechazo del servidor', (
    tester,
  ) async {
    await signInAs(DemoAccounts.elena.id);
    await pumpAt(tester, const AdminConsolePage(), 390);

    expect(find.text('Acceso restringido'), findsOneWidget);
  });
}
