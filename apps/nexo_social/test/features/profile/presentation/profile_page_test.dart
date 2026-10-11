import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_social/app/di/injection.dart';
import 'package:nexo_social/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:nexo_social/features/profile/presentation/pages/profile_page.dart';

import '../../../support/app_harness.dart';

void main() {
  setUp(() async {
    // A saved creator session. Without one the page correctly renders the
    // guest wall, and asserting on the creator header would fail for a reason
    // that has nothing to do with what this test is about.
    await AppHarness.bootstrap(
      initialPreferences: {
        'mock_session':
            '{"id":"creator-1","username":"elena_ux","name":"Elena Vega","role":"creator"}',
      },
    );
    await sl<AuthCubit>().restore();
  });

  testWidgets('renders the creator header and a stable pinned tab bar', (
    tester,
  ) async {
    // Alto generoso: la portada, el resumen y la tarjeta VIP ocupan más que
    // los 600 del viewport por defecto, y las pestañas quedarían sin montar.
    tester.view.physicalSize = const Size(400, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      AppHarness.wrap(const ProfilePage(username: 'elena_ux')),
    );
    await AppHarness.settle(tester);

    expect(find.text('Elena Vega'), findsOneWidget);
    expect(find.text('Publicaciones'), findsOneWidget);
  });

  testWidgets('a visitor sees the sign-in wall instead of a profile', (
    tester,
  ) async {
    await AppHarness.bootstrap();
    await sl<AuthCubit>().guest();

    await tester.pumpWidget(AppHarness.wrap(const ProfilePage()));
    await AppHarness.settle(tester);

    expect(find.text('Tu perfil te está esperando.'), findsOneWidget);
    expect(find.text('Publicaciones'), findsNothing);
  });

  /// Regresión: el endpoint es público, pero un visitante que abría
  /// `/u/elena_ux` veía "Tu perfil te está esperando" y nada de Elena.
  testWidgets('a visitor sees the public profile of someone else', (
    tester,
  ) async {
    await AppHarness.bootstrap();
    await sl<AuthCubit>().guest();
    tester.view.physicalSize = const Size(400, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      AppHarness.wrap(const ProfilePage(username: 'elena_ux')),
    );
    await AppHarness.settle(tester);

    expect(find.text('Elena Vega'), findsOneWidget);
    expect(find.text('Tu perfil te está esperando.'), findsNothing);
    // Mirar sí; seguir y suscribirse, con una cuenta.
    expect(find.byKey(const Key('profile-follow')), findsNothing);
  });

  /// Regresión: el menú de un perfil ajeno ofrecía Creator Studio y "Cerrar
  /// sesión", como si fuera el propio.
  testWidgets('someone else\'s profile has no account menu', (tester) async {
    tester.view.physicalSize = const Size(400, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      AppHarness.wrap(const ProfilePage(username: 'carlos_mendez')),
    );
    await AppHarness.settle(tester);

    expect(find.text('Carlos Méndez'), findsOneWidget);
    expect(find.byTooltip('Opciones del perfil'), findsNothing);
    expect(find.byKey(const Key('profile-follow')), findsOneWidget);
  });

  testWidgets('an unknown account says so', (tester) async {
    await tester.pumpWidget(
      AppHarness.wrap(const ProfilePage(username: 'nadie_123')),
    );
    await AppHarness.settle(tester);

    expect(find.text('Esta cuenta no existe'), findsOneWidget);
  });

  /// Seguir pasa por el repositorio de seguir (el mock en los tests, el
  /// servidor con cuentas reales), no por un booleano local de la pantalla.
  testWidgets('following someone flips the button to "Siguiendo"', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      AppHarness.wrap(const ProfilePage(username: 'carlos_mendez')),
    );
    await AppHarness.settle(tester);
    final button = find.byKey(const Key('profile-follow'));
    expect(
      find.descendant(of: button, matching: find.text('Seguir')),
      findsOneWidget,
    );

    await tester.tap(button);
    await AppHarness.settle(tester);

    expect(
      find.descendant(of: button, matching: find.text('Siguiendo')),
      findsOneWidget,
    );
  });
}
