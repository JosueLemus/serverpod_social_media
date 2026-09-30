import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:nexo_social/app/app.dart';
import 'package:nexo_social/app/di/injection.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The hackathon demo path, end to end on a real device.
///
/// Widget tests cover each screen in isolation; this one exists to catch what
/// only shows up when they are wired together — the router guard, the shell's
/// per-tab navigators, and a session that has to survive from sign-in to a
/// live room.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    // A clean, signed-out install every run. Without the reset the second run
    // on the same simulator starts from whatever the first one left on disk.
    SharedPreferences.setMockInitialValues({});
    await resetDependencies();
    await configureDependencies(
      preferences: await SharedPreferences.getInstance(),
    );
  });

  /// `pumpAndSettle` cannot be used anywhere in this app: the skeleton pulse
  /// and the live indicator repeat forever, so there is always a frame
  /// scheduled and waiting for none hangs until the timeout.
  Future<void> settle(WidgetTester tester) async {
    for (var step = 0; step < 12; step++) {
      await tester.pump(const Duration(milliseconds: 120));
    }
  }

  testWidgets('sign in, react, publish, and join a live', (tester) async {
    await tester.pumpWidget(const NexoApp());
    await settle(tester);

    // The splash resolves the session and the guard moves on by itself.
    expect(find.text('Encuentra tu comunidad.'), findsOneWidget);

    await tester.tap(find.text('Crear cuenta'));
    await settle(tester);

    await tester.enterText(
      find.byKey(const Key('auth-email')),
      'elena@nexo.social',
    );
    await tester.enterText(find.byKey(const Key('auth-password')), 'secret123');
    await tester.tap(find.byKey(const Key('auth-submit')));
    await settle(tester);

    // Signing in changes the session; the redirect — not a listener — brings
    // the user into the shell.
    expect(find.text('Elena Vega'), findsWidgets);
    expect(find.text('Inicio'), findsOneWidget);

    // El feed abre con historias y la tarjeta destacada, así que el primer
    // post queda bajo la línea de flotación — y la lista es perezosa, por lo
    // que ni siquiera está construido hasta que se desplaza hasta él.
    final like = find.byKey(const Key('like-post-1'));
    // Por el CustomScrollView de la página y no por `scrollUntilVisible`: la
    // pantalla tiene tres scrollables (la fila de filtros, la de historias y
    // la lista), y el helper exige que haya uno solo.
    await tester.dragUntilVisible(
      like,
      find.byType(CustomScrollView).first,
      const Offset(0, -240),
    );
    await settle(tester);
    await tester.tap(like);
    await settle(tester);
    expect(find.text('483'), findsOneWidget);

    // El botón de componer no lleva etiqueta —es una acción, no un destino—
    // así que se busca por su semántica.
    await tester.tap(find.bySemanticsLabel('Crear publicación'));
    await settle(tester);
    await tester.tap(find.byKey(const Key('create-option-post')));
    await settle(tester);

    await tester.enterText(
      find.byKey(const Key('create-post-field')),
      'Hola comunidad',
    );
    await settle(tester);
    await tester.tap(find.byKey(const Key('publish-button')));
    await settle(tester);

    // El nuevo post queda arriba del feed, y el feed seguía desplazado desde
    // el paso del like.
    await tester.dragUntilVisible(
      find.text('Hola comunidad'),
      find.byType(CustomScrollView).first,
      const Offset(0, 240),
    );
    await settle(tester);

    // The composer pops back to the tab it was opened from.
    expect(find.text('Hola comunidad'), findsOneWidget);
    expect(find.byKey(const Key('create-post-field')), findsNothing);

    // Los vivos viven dentro de Explorar, que es la segunda pestaña.
    await tester.tap(find.byIcon(Icons.explore_outlined));
    await settle(tester);
    expect(find.text('En vivo ahora'), findsWidgets);

    await tester.tap(find.text('Masterclass de Diseño Mobile').last);
    await settle(tester);

    await tester.enterText(
      find.byKey(const Key('live-comment-field')),
      'Buenísimo',
    );
    await tester.tap(find.byKey(const Key('live-send')));
    await settle(tester);
    // findRichText, because a chat line is one RichText with the author in
    // bold — `find.text` only walks plain Text widgets and would report the
    // message as missing.
    expect(
      find.textContaining('Buenísimo', findRichText: true),
      findsOneWidget,
    );
  });

  testWidgets('a guest browses but cannot publish', (tester) async {
    await tester.pumpWidget(const NexoApp());
    await settle(tester);

    await tester.tap(find.byKey(const Key('explore-as-guest')));
    await settle(tester);

    // Browsing is public.
    expect(find.text('Para ti'), findsWidgets);

    // Composing is not. The visitor still sees what they could create; the
    // guard bounces them to the wall that lets them upgrade once they pick.
    await tester.tap(find.bySemanticsLabel('Crear publicación'));
    await settle(tester);
    expect(find.text('¿Qué deseas crear?'), findsOneWidget);
    await tester.tap(find.byKey(const Key('create-option-post')));
    await settle(tester);
    expect(find.byKey(const Key('create-post-field')), findsNothing);
    expect(find.text('Encuentra tu comunidad.'), findsOneWidget);
  });
}
