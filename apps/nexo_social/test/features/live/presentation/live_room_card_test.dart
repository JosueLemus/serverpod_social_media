import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_social/features/live/domain/entities/live_session.dart';
import 'package:nexo_social/features/live/presentation/widgets/live_room_card.dart';

import '../../../support/app_harness.dart';

/// La tarjeta de sala del home (SDD 0011, Etapa 5).
void main() {
  setUp(() => AppHarness.bootstrap());

  LiveSession session({
    List<String> cohosts = const [],
    int viewers = 530,
  }) => LiveSession(
    id: 'live-5',
    title: 'Masterclass',
    hostId: 'host-elena',
    hostName: 'Elena Vega',
    hostUsername: 'elena_ux',
    status: LiveStatus.live,
    viewers: viewers,
    cohostIds: cohosts,
  );

  Future<void> pumpCard(WidgetTester tester, LiveSession s) async {
    tester.view.physicalSize = const Size(380, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      AppHarness.wrap(
        Padding(
          padding: const EdgeInsets.all(16),
          child: LiveRoomCard(
            session: s,
            speakers: LiveRoomSpeakers.fromSession(s),
            onJoin: () {},
          ),
        ),
      ),
    );
    await AppHarness.settle(tester);
  }

  testWidgets('apila al host y hasta cuatro invitados', (tester) async {
    await pumpCard(tester, session(cohosts: ['a', 'b', 'c', 'd']));

    // Host + 4 invitados = 5 avatares.
    expect(
      find.byKey(const Key('room-card-speaker-host-elena')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('room-card-speaker-a')), findsOneWidget);
    expect(find.byKey(const Key('room-card-speaker-d')), findsOneWidget);
    expect(find.text('+1'), findsNothing);
  });

  testWidgets('con más de cuatro extras muestra "+N"', (tester) async {
    await pumpCard(
      tester,
      session(cohosts: ['a', 'b', 'c', 'd', 'e', 'f', 'g']),
    );

    expect(find.text('+3'), findsOneWidget);
  });

  testWidgets('nunca inventa oradores que no vienen en el modelo', (
    tester,
  ) async {
    await pumpCard(tester, session(cohosts: const []));

    // Sólo el host.
    expect(
      find.byKey(const Key('room-card-speaker-host-elena')),
      findsOneWidget,
    );
    // No se dibujan participantes que no están en `cohostIds`.
    expect(find.byKey(const Key('room-card-speaker-a')), findsNothing);
  });

  testWidgets('N escuchando con separador tabular', (tester) async {
    await pumpCard(tester, session(viewers: 2845));

    expect(find.text('2.8K escuchando'), findsOneWidget);
  });

  testWidgets('CTA es "Escuchar", no "Unirme al Live"', (tester) async {
    await pumpCard(tester, session());

    expect(find.text('Escuchar'), findsOneWidget);
  });

  testWidgets('la propia sala del host dice "Volver a tu sala"', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(380, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final s = session();
    await tester.pumpWidget(
      AppHarness.wrap(
        Padding(
          padding: const EdgeInsets.all(16),
          child: LiveRoomCard(
            session: s,
            speakers: LiveRoomSpeakers.fromSession(s),
            onJoin: () {},
            isOwn: true,
          ),
        ),
      ),
    );
    await AppHarness.settle(tester);

    expect(find.text('Volver a tu sala'), findsOneWidget);
  });
}
