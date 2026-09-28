import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_social/app/di/injection.dart';
import 'package:nexo_social/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:nexo_social/features/auth/presentation/pages/auth_pages.dart';
import 'package:nexo_social/features/explore/presentation/pages/explore_page.dart';
import 'package:nexo_social/features/feed/presentation/pages/feed_page.dart';
import 'package:nexo_social/features/notifications/presentation/pages/activity_page.dart';
import 'package:nexo_social/features/posts/presentation/pages/create_post_page.dart';
import 'package:nexo_social/features/profile/presentation/pages/profile_page.dart';
import 'package:nexo_social/features/subscriptions/presentation/pages/subscription_page.dart';

import '../support/app_harness.dart';

/// Ninguna pantalla desborda en el teléfono más angosto que soportamos.
///
/// Un overflow de RenderFlex **no rompe la app**: pinta la banda amarilla en
/// debug y en release simplemente recorta, en silencio. Lo que se recorta es
/// siempre lo último de la fila, que en este diseño suele ser la insignia de
/// "en vivo" o el botón de acción — o sea, justo el dato por el que existe la
/// fila. Ya pasó una vez, en la tarjeta destacada del feed.
void main() {
  /// 320×640: iPhone SE de primera generación, el piso razonable.
  const smallPhone = Size(320, 640);

  /// Alto generoso para que el contenido quepa a lo largo: lo que se busca
  /// acá es el desborde **horizontal**, y un viewport corto produciría
  /// desbordes verticales que sólo dicen que la pantalla es corta.
  const tallSmallPhone = Size(320, 2400);

  setUp(() async {
    await AppHarness.bootstrap(
      initialPreferences: {
        'mock_session':
            '{"id":"creator-1","username":"elena_ux","name":"Elena Vega","role":"creator"}',
      },
    );
    await sl<AuthCubit>().restore();
  });

  Future<void> expectNoOverflow(
    WidgetTester tester,
    Widget screen, {
    Size size = tallSmallPhone,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(AppHarness.wrap(screen));
    await AppHarness.settle(tester);

    expect(tester.takeException(), isNull);
  }

  testWidgets('el feed no desborda', (tester) async {
    await expectNoOverflow(tester, const FeedPage());
  });

  testWidgets('explorar no desborda', (tester) async {
    await expectNoOverflow(tester, const ExplorePage());
  });

  testWidgets('actividad no desborda', (tester) async {
    await expectNoOverflow(tester, const ActivityPage());
  });

  testWidgets('el perfil no desborda', (tester) async {
    await expectNoOverflow(tester, const ProfilePage(username: 'elena_ux'));
  });

  testWidgets('premium no desborda', (tester) async {
    await expectNoOverflow(tester, const SubscriptionPage());
  });

  testWidgets('el compositor no desborda', (tester) async {
    await expectNoOverflow(tester, const CreatePostPage());
  });

  testWidgets('el onboarding no desborda', (tester) async {
    await expectNoOverflow(tester, const SignInPage());
  });

  /// El caso que originó el test: a 320 de ancho real, no sólo alto generoso.
  testWidgets('el feed no desborda en un viewport de 320x640', (tester) async {
    await expectNoOverflow(tester, const FeedPage(), size: smallPhone);
  });
}
