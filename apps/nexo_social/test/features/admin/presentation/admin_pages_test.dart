import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_social/app/di/injection.dart';
import 'package:nexo_social/core/mock/demo_accounts.dart';
import 'package:nexo_social/features/admin/domain/entities/audit_entry.dart';
import 'package:nexo_social/features/admin/presentation/bloc/audit_log_cubit.dart';
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
          final chip = find.byKey(Key('admin-section-${section.name}'));
          // Los chips son una fila que scrollea: sin traerlo a la vista, el
          // tap cae afuera, Flutter sólo avisa y la sección queda sin probar.
          await tester.ensureVisible(chip);
          await AppHarness.settle(tester);
          await tester.tap(chip);
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

  group('los buscadores de la consola', () {
    setUp(() => signInAs(DemoAccounts.operator.id));

    Future<void> openSection(WidgetTester tester, AdminSection section) async {
      final chip = find.byKey(Key('admin-section-${section.name}'));
      await tester.ensureVisible(chip);
      await AppHarness.settle(tester);
      await tester.tap(chip);
      await AppHarness.settle(tester);
    }

    String fieldText(WidgetTester tester, String key) => tester
        .widget<TextField>(
          find.descendant(
            of: find.byKey(Key(key)),
            matching: find.byType(TextField),
          ),
        )
        .controller!
        .text;

    /// Una sección se desmonta al cambiar de chip. Con el controller adentro,
    /// lo escrito desaparecía mientras el filtro seguía aplicado.
    testWidgets('lo escrito sobrevive a cambiar de sección', (tester) async {
      await pumpAt(tester, const AdminConsolePage(), 390);

      await openSection(tester, AdminSection.accounts);
      await tester.enterText(
        find.byKey(const Key('admin-account-search')),
        'troll',
      );
      await openSection(tester, AdminSection.audit);
      await tester.enterText(find.byKey(const Key('audit-actor')), 'nexo');
      await openSection(tester, AdminSection.creators);

      await openSection(tester, AdminSection.accounts);
      expect(fieldText(tester, 'admin-account-search'), 'troll');
      expect(
        find.byKey(Key('account-${DemoAccounts.troll.username}')),
        findsOneWidget,
      );
      expect(
        find.byKey(Key('account-${DemoAccounts.elena.username}')),
        findsNothing,
        reason: 'El filtro y el texto tienen que coincidir',
      );

      await openSection(tester, AdminSection.audit);
      expect(fieldText(tester, 'audit-actor'), 'nexo');
    });

    testWidgets('la búsqueda espera a que se deje de tipear', (tester) async {
      await pumpAt(tester, const AdminConsolePage(), 390);
      await openSection(tester, AdminSection.accounts);
      final elena = find.byKey(Key('account-${DemoAccounts.elena.username}'));
      expect(elena, findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('admin-account-search')),
        DemoAccounts.troll.email,
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(elena, findsOneWidget, reason: 'Todavía no pasó el debounce');

      await AppHarness.settle(tester);
      expect(elena, findsNothing);
    });

    /// "Todo" y las entidades armaban un filtro nuevo y descartaban el de
    /// las últimas 24 horas, que seguía encendido en pantalla.
    testWidgets('las pastillas de auditoría conservan el resto del filtro', (
      tester,
    ) async {
      await pumpAt(tester, const AdminConsolePage(), 390);
      await openSection(tester, AdminSection.audit);
      final audit = BlocProvider.of<AuditLogCubit>(
        tester.element(find.byKey(const Key('audit-actor'))),
      );

      await tester.tap(find.byKey(const Key('audit-since')));
      await AppHarness.settle(tester);
      await tester.tap(find.byKey(const Key('audit-entity-account')));
      await AppHarness.settle(tester);

      expect(audit.state.filter.entity, AuditEntity.account);
      expect(audit.state.filter.since, isNotNull);

      await tester.tap(find.byKey(const Key('audit-entity-all')));
      await AppHarness.settle(tester);

      expect(audit.state.filter.entity, isNull);
      expect(audit.state.filter.since, isNotNull);
    });
  });

  testWidgets('una cuenta sin scope ve el rechazo del servidor', (
    tester,
  ) async {
    await signInAs(DemoAccounts.elena.id);
    await pumpAt(tester, const AdminConsolePage(), 390);

    expect(find.text('Acceso restringido'), findsOneWidget);
  });
}
