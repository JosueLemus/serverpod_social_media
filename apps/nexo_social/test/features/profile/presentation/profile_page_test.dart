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
}
