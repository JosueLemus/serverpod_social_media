import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_social/app/di/injection.dart';
import 'package:nexo_social/app/theme/nexo_themes.dart';
import 'package:nexo_social/core/widgets/create_sheet_widget.dart';
import 'package:nexo_social/features/appearance/presentation/bloc/theme_cubit.dart';
import 'package:nexo_social/features/appearance/presentation/pages/themes_page.dart';
import 'package:nexo_social/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:nexo_social/features/auth/presentation/pages/auth_pages.dart';
import 'package:nexo_social/features/feed/presentation/pages/feed_page.dart';
import 'package:nexo_social/features/live/presentation/children/schedule_show/presentation/pages/schedule_show_page.dart';
import 'package:nexo_social/features/live/presentation/pages/creator_studio_page.dart';
import 'package:nexo_social/features/notifications/presentation/pages/activity_page.dart';
import 'package:nexo_social/features/posts/presentation/pages/create_post_page.dart';
import 'package:nexo_social/features/profile/presentation/pages/profile_page.dart';
import 'package:nexo_social/features/subscriptions/presentation/pages/subscription_page.dart';

import '../support/app_harness.dart';

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

  testWidgets('programar show no desborda', (tester) async {
    await expectNoOverflow(tester, const ScheduleShowPage());
  });

  // "Transmitir en Vivo" y su insignia no entran en una fila a 320.
  /// El escenario vertical con chat encima y la fila de cuatro controles con
  /// etiquetas que cambian ("Activar micrófono") son lo que más aprieta.
  testWidgets('el studio no desborda', (tester) async {
    await expectNoOverflow(tester, const CreatorStudioPage());
  });

  testWidgets('el menú de crear no desborda', (tester) async {
    await expectNoOverflow(tester, const CreateSheetWidget());
  });

  testWidgets('temas no desborda', (tester) async {
    await expectNoOverflow(
      tester,
      BlocProvider.value(value: sl<ThemeCubit>(), child: const ThemesPage()),
    );
  });

  // El feed con la fuente más ancha del catálogo y la más angosta: el layout
  // se midió con una sola tipografía, y un tema la cambia entera.
  for (final id in ['cyber', 'editorial', 'plancha']) {
    testWidgets('el feed no desborda con el tema $id', (tester) async {
      NexoThemes.activate(NexoThemes.byId(id));
      addTearDown(
        () => NexoThemes.activate(NexoThemes.byId(NexoThemes.defaultId)),
      );
      await expectNoOverflow(tester, const FeedPage(), size: smallPhone);
    });
  }

  testWidgets('el onboarding no desborda', (tester) async {
    await expectNoOverflow(tester, const SignInPage());
  });

  /// El caso que originó el test: a 320 de ancho real, no sólo alto generoso.
  testWidgets('el feed no desborda en un viewport de 320x640', (tester) async {
    await expectNoOverflow(tester, const FeedPage(), size: smallPhone);
  });
}
