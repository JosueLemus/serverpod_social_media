import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_social/app/di/injection.dart';
import 'package:nexo_social/core/mock/demo_accounts.dart';
import 'package:nexo_social/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:nexo_social/features/feed/presentation/pages/feed_page.dart';
import 'package:nexo_social/features/profile/presentation/pages/profile_page.dart';

import '../support/app_harness.dart';

/// Cada rol tiene que **verse** distinto, no sólo comportarse distinto.
///
/// Regresión: un operador y un usuario veían exactamente el mismo feed y el
/// mismo perfil —el de Elena—, así que en un teléfono no había nada que dijera
/// con qué cuenta se estaba ni que existiera una consola.
void main() {
  Future<void> signInAs(DemoAccount account) async {
    await AppHarness.bootstrap(
      initialPreferences: {'mock_session': '{"id":"${account.id}"}'},
    );
    await sl<AuthCubit>().restore();
  }

  Future<void> pumpPhone(WidgetTester tester, Widget page) async {
    tester.view.physicalSize = const Size(320, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(AppHarness.wrap(page));
    await AppHarness.settle(tester);
    expect(tester.takeException(), isNull, reason: 'desborda a 320');
  }

  group('el feed', () {
    testWidgets('un operador ve su acceso a la consola', (tester) async {
      await signInAs(DemoAccounts.operator);
      await pumpPhone(tester, const FeedPage());

      expect(find.text('Sesión de operador'), findsOneWidget);
      expect(find.text('Abrir consola de operador'), findsOneWidget);
    });

    testWidgets('un moderador ve la moderación, no la consola', (tester) async {
      await signInAs(DemoAccounts.moderator);
      await pumpPhone(tester, const FeedPage());

      expect(find.text('Abrir moderación'), findsOneWidget);
      expect(find.text('Abrir consola de operador'), findsNothing);
    });

    testWidgets('un usuario no ve nada de eso', (tester) async {
      await signInAs(DemoAccounts.elena);
      await pumpPhone(tester, const FeedPage());

      expect(find.byKey(const Key('staff-shortcut')), findsNothing);
      expect(find.byKey(const Key('session-role')), findsNothing);
    });
  });

  group('el perfil propio', () {
    testWidgets('un operador ve su cuenta y su rol, no a Elena', (
      tester,
    ) async {
      await signInAs(DemoAccounts.operator);
      await pumpPhone(tester, const ProfilePage());

      expect(find.text(DemoAccounts.operator.name), findsOneWidget);
      expect(find.text('OPERADOR'), findsWidgets);
      expect(find.text('@elena_ux'), findsNothing);
    });

    testWidgets('un espectador ve que no tiene acceso a moderar', (
      tester,
    ) async {
      await signInAs(DemoAccounts.viewer);
      await pumpPhone(tester, const ProfilePage());

      expect(find.text('USUARIO'), findsOneWidget);
      expect(find.text('Abrir moderación'), findsNothing);
    });
  });
}
