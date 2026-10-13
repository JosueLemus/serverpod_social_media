import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_social/app/theme/app_theme.dart';
import 'package:nexo_social/core/errors/failures.dart';
import 'package:nexo_social/core/widgets/app_state_views.dart';
import 'package:nexo_social/features/moderation/domain/entities/moderation_action.dart';
import 'package:nexo_social/features/moderation/domain/repositories/moderation_repository.dart';
import 'package:nexo_social/features/moderation/presentation/bloc/moderation_cubit.dart';
import 'package:nexo_social/features/moderation/presentation/widgets/report_queue.dart';

/// Un servidor de moderación a mano: falla cuando se le pide y deja una
/// acción colgada hasta que el test la suelta.
class _QueueServer implements ModerationRepository {
  _QueueServer(this.queue);

  final List<ModerationReport> queue;
  Failure? readFailure;
  Failure? actFailure;

  /// Si no es null, resolver espera a que se complete.
  Completer<void>? gate;
  final resolved = <(String, ModerationType)>[];
  final dismissed = <String>[];

  @override
  Future<List<ModerationReport>> reports() async {
    final failure = readFailure;
    if (failure != null) throw failure;
    return List.of(queue);
  }

  @override
  Future<List<ModerationAction>> list() async => const [];

  @override
  Future<ModerationAction> resolve(
    String reportId,
    ModerationDecision decision,
  ) async {
    await gate?.future;
    final failure = actFailure;
    if (failure != null) throw failure;
    resolved.add((reportId, decision.type));
    queue.removeWhere((report) => report.id == reportId);
    return ModerationAction(
      id: 'a-$reportId',
      type: decision.type,
      target: reportId,
      reason: ModerationReason.spam,
      actor: '@mod',
      createdAt: DateTime(2026),
    );
  }

  @override
  Future<void> dismiss(String reportId) async {
    await gate?.future;
    dismissed.add(reportId);
    queue.removeWhere((report) => report.id == reportId);
  }

  @override
  Future<void> reportComment({
    required String liveId,
    required String commentId,
    required ModerationReason reason,
  }) async {}

  @override
  Stream<void> changes() => const Stream.empty();
}

ModerationReport _report(String id) => ModerationReport(
  id: id,
  content: 'Comentario $id',
  author: '@autor_$id',
  reason: ModerationReason.spam,
  severity: ReportSeverity.high,
  createdAt: DateTime(2026),
);

void main() {
  late _QueueServer server;
  late ModerationCubit cubit;

  setUp(() {
    server = _QueueServer([_report('r1'), _report('r2')]);
    cubit = ModerationCubit(server);
  });
  tearDown(() => cubit.close());

  group('ModerationCubit', () {
    test(
      'una lectura fallida sin cola es un error, no una cola vacía',
      () async {
        server.readFailure = const ServerFailure('caído');

        await cubit.load();

        expect(cubit.state.failedToLoad, isTrue);
        expect(cubit.state.loadIssue, ModerationIssue.other);
        expect(cubit.state.actionIssue, isNull);
      },
    );

    test('una relectura fallida conserva la cola que ya se mostraba', () async {
      await cubit.load();
      server.readFailure = const ServerFailure('caído');

      await cubit.load();

      expect(cubit.state.reports, hasLength(2));
      expect(cubit.state.loadIssue, ModerationIssue.other);
      expect(cubit.state.failedToLoad, isFalse);
    });

    test('un rechazo de la acción no se confunde con uno de lectura', () async {
      await cubit.load();
      server.actFailure = const ConflictFailure('ya resuelto');

      await cubit.resolve(cubit.state.reports.first, ModerationType.banUser);

      expect(cubit.state.actionIssue, ModerationIssue.conflict);
      expect(cubit.state.loadIssue, isNull);
      expect(cubit.state.isWorking, isFalse);
    });

    test('mientras una acción corre, otra no sale', () async {
      await cubit.load();
      server.gate = Completer<void>();
      final report = cubit.state.reports.first;

      final first = cubit.resolve(report, ModerationType.banUser);
      expect(cubit.state.isWorking, isTrue);
      // El doble tap: no es otra sanción.
      await cubit.resolve(report, ModerationType.banUser);
      await cubit.dismiss(cubit.state.reports.last);

      server.gate!.complete();
      await first;

      expect(server.resolved, [('r1', ModerationType.banUser)]);
      expect(server.dismissed, isEmpty);
      expect(cubit.state.isWorking, isFalse);
    });

    test('isWorking forma parte de la igualdad del estado', () {
      expect(
        const ModerationState(isWorking: true),
        isNot(const ModerationState()),
      );
    });
  });

  group('ReportQueueSection', () {
    Future<void> pump(WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        BlocProvider.value(
          value: cubit,
          child: MaterialApp(
            theme: AppTheme.nexo,
            home: const Scaffold(
              body: SingleChildScrollView(child: ReportQueueSection()),
            ),
          ),
        ),
      );
      for (var step = 0; step < 8; step++) {
        await tester.pump(const Duration(milliseconds: 120));
      }
    }

    testWidgets('si la cola no se pudo leer, muestra el error con reintento', (
      tester,
    ) async {
      server.readFailure = const ServerFailure('caído');
      await cubit.load();
      await pump(tester);

      expect(find.byType(AppErrorView), findsOneWidget);
      expect(find.text('Reintentar'), findsOneWidget);
      expect(find.text('No hay reportes pendientes.'), findsNothing);

      server.readFailure = null;
      await tester.tap(find.text('Reintentar'));
      for (var step = 0; step < 8; step++) {
        await tester.pump(const Duration(milliseconds: 120));
      }

      expect(find.byKey(const Key('report-r1')), findsOneWidget);
    });

    testWidgets('expulsar pide confirmación antes de sancionar', (
      tester,
    ) async {
      await cubit.load();
      await pump(tester);

      await tester.tap(find.byKey(const Key('ban-r1')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('¿Expulsar a @autor_r1?'), findsOneWidget);
      expect(server.resolved, isEmpty, reason: 'Un tap no expulsa');

      await tester.tap(find.byKey(const Key('ban-cancel')));
      await tester.pump(const Duration(milliseconds: 300));
      expect(server.resolved, isEmpty);

      await tester.tap(find.byKey(const Key('ban-r1')));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.byKey(const Key('ban-confirm')));
      await tester.pump(const Duration(milliseconds: 300));

      expect(server.resolved, [('r1', ModerationType.banUser)]);
      // La cola se rearma y sus tarjetas entran con demora: dejar que
      // terminen antes de desmontar.
      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets('los botones se apagan mientras corre una acción', (
      tester,
    ) async {
      await cubit.load();
      await pump(tester);
      server.gate = Completer<void>();

      await tester.tap(find.byKey(const Key('hide-r1')));
      await tester.pump();

      for (final key in ['hide-r2', 'dismiss-r2', 'mute-r2', 'ban-r2']) {
        final button = tester.widget<ButtonStyleButton>(find.byKey(Key(key)));
        expect(button.onPressed, isNull, reason: key);
      }

      server.gate!.complete();
      await tester.pump(const Duration(milliseconds: 300));
      final hide = tester.widget<ButtonStyleButton>(
        find.byKey(const Key('hide-r2')),
      );
      expect(hide.onPressed, isNotNull);
      await tester.pump(const Duration(seconds: 2));
    });
  });
}
