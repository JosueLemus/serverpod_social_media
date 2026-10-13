import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_social/app/di/injection.dart';
import 'package:nexo_social/core/errors/failures.dart';
import 'package:nexo_social/core/media/live_media_engine.dart';
import 'package:nexo_social/core/media/simulated_live_media_engine.dart';
import 'package:nexo_social/features/live/domain/entities/live_comment.dart';
import 'package:nexo_social/features/live/domain/entities/live_media_grant.dart';
import 'package:nexo_social/features/live/domain/entities/live_room_event.dart';
import 'package:nexo_social/features/live/domain/entities/live_session.dart';
import 'package:nexo_social/features/live/domain/repositories/live_repository.dart';
import 'package:nexo_social/features/live/presentation/pages/live_room_page.dart';
import 'package:nexo_social/features/subscriptions/domain/repositories/subscription_repository.dart';

import '../../../support/app_harness.dart';

/// La sala vista desde la audiencia: una foto inicial y los eventos que el
/// test empuja como si llegaran del servidor.
class _AudienceRepository implements LiveRepository {
  _AudienceRepository(this.show);

  LiveSession show;
  final events = StreamController<LiveRoomEvent>.broadcast();

  /// Si no es null, la sala se corta antes de la primera foto.
  Object? dropWith;

  @override
  Stream<LiveRoomEvent> watch(String liveId) async* {
    if (dropWith case final error?) throw error;
    yield LiveRoomSnapshot(
      session: show,
      role: LiveRole.audience,
      comments: const [
        LiveComment(id: 'c1', author: 'Tomás Ríos', body: 'hola'),
      ],
    );
    yield* events.stream;
  }

  @override
  Future<LiveMediaGrant> mediaToken(String liveId) async => LiveMediaGrant(
    channel: 'nexo_live_$liveId',
    role: LiveMediaGrantRole.subscriber,
  );

  @override
  Stream<void> changes() => const Stream.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final startedAt = DateTime(2026, 10, 11, 20);
  final onAir = LiveSession(
    id: '5',
    title: 'Masterclass',
    hostName: 'Elena Vega',
    hostUsername: 'elena_ux',
    status: LiveStatus.live,
    startedAt: startedAt,
  );

  late _AudienceRepository repository;

  setUp(() async {
    await AppHarness.bootstrap();
    repository = _AudienceRepository(onAir);
    sl
      ..unregister<LiveRepository>()
      ..registerLazySingleton<LiveRepository>(() => repository)
      ..unregister<LiveMediaEngine>()
      ..registerFactory<LiveMediaEngine>(SimulatedLiveMediaEngine.new);
  });

  tearDown(() => repository.events.close());

  Future<void> pumpRoom(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(AppHarness.wrap(const LiveRoomPage(liveId: '5')));
    await AppHarness.settle(tester);
  }

  testWidgets('no hay mensaje fijado que nadie fijó', (tester) async {
    await pumpRoom(tester);

    expect(find.textContaining('hola', findRichText: true), findsOneWidget);
    expect(find.textContaining('MENSAJE FIJADO'), findsNothing);
    expect(find.textContaining('Sofía Streamer'), findsNothing);
  });

  testWidgets('cuando el host termina, la sala lo dice y ofrece salir', (
    tester,
  ) async {
    await pumpRoom(tester);
    expect(find.byKey(const Key('live-comment-field')), findsOneWidget);

    repository.events.add(
      LiveSessionChanged(
        LiveSession(
          id: '5',
          title: 'Masterclass',
          hostName: 'Elena Vega',
          hostUsername: 'elena_ux',
          status: LiveStatus.recorded,
          startedAt: startedAt,
          endedAt: startedAt.add(const Duration(minutes: 12)),
        ),
      ),
    );
    await AppHarness.settle(tester);

    expect(find.byKey(const Key('live-ended')), findsOneWidget);
    expect(find.text('El vivo terminó'), findsOneWidget);
    expect(find.text('@elena_ux · Duró 12 min'), findsOneWidget);
    expect(find.byKey(const Key('live-ended-back')), findsOneWidget);
    expect(find.byKey(const Key('live-ended-more')), findsOneWidget);
    // Ya no se puede comentar en un vivo terminado.
    expect(find.byKey(const Key('live-comment-field')), findsNothing);
  });

  testWidgets('un vivo cancelado dice que se canceló', (tester) async {
    repository.show = onAir.copyWith(status: LiveStatus.cancelled);
    await pumpRoom(tester);

    expect(find.text('Este vivo se canceló'), findsOneWidget);
    // Sin hora de inicio no se inventa una duración.
    expect(find.text('@elena_ux'), findsOneWidget);
  });

  testWidgets('el regalo está apagado, no finge funcionar', (tester) async {
    await pumpRoom(tester);

    expect(find.byTooltip('Regalos: muy pronto'), findsOneWidget);
  });

  testWidgets('cortada antes de la primera foto dice que reconecta', (
    tester,
  ) async {
    repository.dropWith = const NetworkFailure('socket closed');
    await pumpRoom(tester);

    expect(find.byKey(const Key('live-waiting')), findsOneWidget);
    expect(find.text('Reconectando…'), findsOneWidget);
    expect(find.text('Este vivo ya no está disponible'), findsNothing);

    repository.dropWith = null;
    await tester.pump(const Duration(seconds: 2));
    await AppHarness.settle(tester);
    expect(find.byKey(const Key('live-comment-field')), findsOneWidget);
  });

  testWidgets('un vivo que no existe sí dice que no está disponible', (
    tester,
  ) async {
    repository.dropWith = const NotFoundFailure('live');
    await pumpRoom(tester);

    expect(find.text('Este vivo ya no está disponible'), findsOneWidget);
  });

  testWidgets('con las preguntas apagadas no se ofrece el campo', (
    tester,
  ) async {
    repository.show = LiveSession(
      id: '5',
      title: 'Masterclass',
      hostName: 'Elena Vega',
      hostUsername: 'elena_ux',
      status: LiveStatus.live,
      allowQuestions: false,
    );
    await pumpRoom(tester);

    expect(find.byKey(const Key('live-comment-field')), findsNothing);
    expect(find.text('El host desactivó los comentarios'), findsOneWidget);
    // El amor sigue: no es una pregunta.
    expect(find.byKey(const Key('live-love')), findsOneWidget);
  });

  group('solo miembros', () {
    const membersOnly = LiveSession(
      id: '5',
      title: 'Masterclass',
      hostName: 'Elena Vega',
      hostUsername: 'elena_ux',
      status: LiveStatus.live,
      isPremium: true,
    );

    testWidgets('quien no es miembro ve la invitación, no el vivo', (
      tester,
    ) async {
      repository.show = membersOnly;
      await pumpRoom(tester);

      expect(find.byKey(const Key('live-members-only')), findsOneWidget);
      expect(find.text('Hacerme miembro'), findsOneWidget);
      expect(find.byKey(const Key('live-comment-field')), findsNothing);
    });

    testWidgets('un miembro entra como siempre', (tester) async {
      await sl<SubscriptionRepository>().subscribe('elena_ux');
      repository.show = membersOnly;
      await pumpRoom(tester);

      expect(find.byKey(const Key('live-members-only')), findsNothing);
      expect(find.byKey(const Key('live-comment-field')), findsOneWidget);
    });
  });
}
