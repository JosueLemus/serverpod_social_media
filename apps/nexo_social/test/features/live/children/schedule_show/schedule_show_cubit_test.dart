import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_social/core/errors/failures.dart';
import 'package:nexo_social/core/mock/demo_accounts.dart';
import 'package:nexo_social/core/mock/mock_platform.dart';
import 'package:nexo_social/features/live/domain/entities/live_session.dart';
import 'package:nexo_social/features/live/presentation/children/schedule_show/data/datasources/show_draft_local_data_source.dart';
import 'package:nexo_social/features/live/presentation/children/schedule_show/data/repositories/mock_show_schedule_repository.dart';
import 'package:nexo_social/features/live/presentation/children/schedule_show/domain/usecases/schedule_show.dart';
import 'package:nexo_social/features/live/presentation/children/schedule_show/presentation/bloc/schedule_show_cubit.dart';
import 'package:nexo_social/features/moderation/domain/entities/moderation_action.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../support/platform_harness.dart';

void main() {
  final now = DateTime(2024, 11, 26, 10);
  late MockPlatform platform;
  late MockShowScheduleRepository repository;

  ScheduleShowCubit build() => ScheduleShowCubit(
    repository,
    ScheduleShow(repository),
    now: () => now,
    autosaveDelay: Duration.zero,
  );

  /// Deja correr el timer del autoguardado y la escritura a disco.
  Future<void> flush() => Future<void>.delayed(Duration.zero);

  setUp(() async {
    platform = await platformAs(DemoAccounts.elena.id, now: () => now);
    repository = MockShowScheduleRepository(
      platform,
      ShowDraftLocalDataSource(await SharedPreferences.getInstance()),
    );
  });

  tearDown(() => platform.dispose());

  test('starts a fresh draft that cannot be scheduled yet', () async {
    final cubit = build();
    await cubit.load();

    expect(cubit.state.status, ScheduleShowStatus.editing);
    expect(cubit.state.draft!.startsAt, DateTime(2024, 11, 27, 19));
    expect(cubit.state.canSubmit, isFalse);
    expect(cubit.state.draftSaved, isFalse);
    await cubit.close();
  });

  test('a title makes it schedulable', () async {
    final cubit = build();
    await cubit.load();
    cubit.setTitle('Masterclass de Flutter');

    expect(cubit.state.canSubmit, isTrue);
    await cubit.close();
  });

  test('says "saved" only after the draft is on disk', () async {
    final cubit = build();
    await cubit.load();
    cubit.setTitle('Masterclass');
    expect(cubit.state.draftSaved, isFalse);

    await flush();
    await flush();
    expect(cubit.state.draftSaved, isTrue);
    expect((await repository.loadDraft())!.title, 'Masterclass');
    await cubit.close();
  });

  test('leaving with the back arrow keeps the draft', () async {
    final first = ScheduleShowCubit(
      repository,
      ScheduleShow(repository),
      now: () => now,
      // Un autoguardado que nunca llega a correr: el cierre tiene que
      // escribirlo igual.
      autosaveDelay: const Duration(hours: 1),
    );
    await first.load();
    first.setTitle('Borrador a medias');
    await first.close();
    await flush();

    final second = build();
    await second.load();
    expect(second.state.draft!.title, 'Borrador a medias');
    expect(second.state.draftSaved, isTrue);
    await second.close();
  });

  test('discarding deletes the draft', () async {
    final cubit = build();
    await cubit.load();
    cubit.setTitle('Se va');
    await flush();
    await cubit.discard();
    await cubit.close();

    expect(await repository.loadDraft(), isNull);
  });

  test('changing the date keeps the time, and vice versa', () async {
    final cubit = build();
    await cubit.load();
    cubit.setDate(DateTime(2024, 11, 28));
    expect(cubit.state.draft!.startsAt, DateTime(2024, 11, 28, 19));
    cubit.setTime(hour: 20, minute: 30);
    expect(cubit.state.draft!.startsAt, DateTime(2024, 11, 28, 20, 30));
    await cubit.close();
  });

  test('scheduling creates a scheduled session and clears the draft', () async {
    final cubit = build();
    await cubit.load();
    cubit
      ..setTitle('Masterclass')
      ..setDuration(90)
      ..setAccess(ShowAccess.members);
    await cubit.submit();

    final session = cubit.state.session!;
    expect(cubit.state.status, ScheduleShowStatus.scheduled);
    expect(session.status, LiveStatus.scheduled);
    expect(session.hostId, DemoAccounts.elena.id);
    expect(session.durationMinutes, 90);
    expect(session.isPremium, isTrue);
    expect(platform.live(session.id), session);
    expect(await repository.loadDraft(), isNull);
    await cubit.close();
  });

  test('an unverified creator is rejected with a typed reason', () async {
    platform
      ..bindSession(DemoAccounts.operator.id)
      ..setVerification(
        DemoAccounts.elena.id,
        verified: false,
        reason: ModerationReason.impersonation,
      )
      ..bindSession(DemoAccounts.elena.id);

    final cubit = build();
    await cubit.load();
    cubit.setTitle('Masterclass');
    await cubit.submit();

    expect(cubit.state.status, ScheduleShowStatus.editing);
    expect(cubit.state.issue, ScheduleShowIssue.notVerified);
    await cubit.close();
  });

  group('guests', () {
    test('invites an existing account by @username', () async {
      final cubit = build();
      await cubit.load();
      await cubit.addGuest('@${DemoAccounts.carlos.username}');

      expect(cubit.state.draft!.guests.single.id, DemoAccounts.carlos.id);
      await cubit.close();
    });

    test('the host cannot invite themself', () async {
      final cubit = build();
      await cubit.load();
      await cubit.addGuest(DemoAccounts.elena.username);

      expect(cubit.state.draft!.guests, isEmpty);
      expect(cubit.state.issue, ScheduleShowIssue.guestIsHost);
      await cubit.close();
    });

    test('an unknown username is reported, twice if asked twice', () async {
      final cubit = build();
      await cubit.load();
      await cubit.addGuest('nadie_por_aqui');
      final first = cubit.state.issueSerial;
      await cubit.addGuest('nadie_por_aqui');

      expect(cubit.state.issue, ScheduleShowIssue.guestNotFound);
      expect(cubit.state.issueSerial, first + 1);
      await cubit.close();
    });

    test('inviting the same person twice keeps one', () async {
      final cubit = build();
      await cubit.load();
      await cubit.addGuest(DemoAccounts.carlos.username);
      await cubit.addGuest(DemoAccounts.carlos.username);

      expect(cubit.state.draft!.guests, hasLength(1));
      await cubit.close();
    });

    test('stops at the limit', () async {
      final cubit = build();
      await cubit.load();
      for (final account in [
        DemoAccounts.carlos,
        DemoAccounts.viewer,
        DemoAccounts.moderator,
        DemoAccounts.operator,
      ]) {
        await cubit.addGuest(account.username);
      }

      expect(cubit.state.draft!.guests, hasLength(ShowDraft.maxGuests));
      expect(cubit.state.issue, ScheduleShowIssue.guestLimit);
      await cubit.close();
    });
  });

  group('the server rule', () {
    test('rejects a show in the past', () {
      expect(
        () => platform.scheduleShow(
          title: 'Tarde',
          description: '',
          startsAt: now.subtract(const Duration(minutes: 1)),
          durationMinutes: 60,
          isPremium: false,
          cohostIds: const [],
          allowQuestions: true,
          recordReplay: true,
        ),
        throwsA(isA<ConflictFailure>()),
      );
      expect(
        platform.lives().where((live) => live.title == 'Tarde'),
        isEmpty,
      );
    });

    test('a scheduled show survives a reload', () async {
      final session = platform.scheduleShow(
        title: 'Persistente',
        description: '# Temario',
        startsAt: now.add(const Duration(days: 2)),
        durationMinutes: 45,
        isPremium: false,
        cohostIds: [DemoAccounts.carlos.id],
        allowQuestions: false,
        recordReplay: true,
      );
      await flush();

      final reloaded = MockPlatform(
        await SharedPreferences.getInstance(),
        now: () => now,
      );
      expect(reloaded.live(session.id), session);
      await reloaded.dispose();
    });
  });
}
