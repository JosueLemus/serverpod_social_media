import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_social/features/live/presentation/children/schedule_show/domain/entities/show_draft.dart';
import 'package:nexo_social/features/live/presentation/children/schedule_show/presentation/utils/show_date_format.dart';

void main() {
  final now = DateTime(2024, 11, 26, 10);

  group('ShowDraft', () {
    test('a new draft starts tomorrow at 19:00', () {
      expect(ShowDraft.startingFrom(now).startsAt, DateTime(2024, 11, 27, 19));
    });

    test('rolls over the end of the month', () {
      expect(
        ShowDraft.startingFrom(DateTime(2024, 11, 30, 10)).startsAt,
        DateTime(2024, 12, 1, 19),
      );
    });

    test('a new draft is only missing its title', () {
      expect(ShowDraft.startingFrom(now).issuesAt(now), {
        ShowDraftIssue.titleMissing,
      });
    });

    test('a blank title is still missing', () {
      final draft = ShowDraft.startingFrom(now).copyWith(title: '   ');
      expect(draft.issuesAt(now), contains(ShowDraftIssue.titleMissing));
    });

    test('rejects a title over the limit', () {
      final draft = ShowDraft.startingFrom(
        now,
      ).copyWith(title: 'a' * (ShowDraft.maxTitleLength + 1));
      expect(draft.issuesAt(now), {ShowDraftIssue.titleTooLong});
    });

    test('rejects a start that already passed', () {
      final draft = ShowDraft(title: 'Show', startsAt: now);
      expect(draft.issuesAt(now), {ShowDraftIssue.startInPast});
    });

    test('survives a round trip through JSON', () {
      final draft = ShowDraft.startingFrom(now).copyWith(
        title: 'Masterclass',
        description: '**Temario**',
        durationMinutes: 90,
        access: ShowAccess.members,
        recordReplay: false,
        guests: const [
          ShowGuest(id: 'carlos', username: 'carlos_ui', name: 'Carlos'),
        ],
      );
      expect(ShowDraft.fromJson(draft.toJson()), draft);
    });
  });

  group('ShowDateFormat', () {
    test('formats the date in Spanish', () {
      expect(ShowDateFormat.date(DateTime(2024, 11, 28)), 'Jue, 28 Nov 2024');
    });

    test('formats the time in 24 hours', () {
      expect(ShowDateFormat.time(DateTime(2024, 11, 28, 9, 5)), '09:05');
    });

    test('names the offset, not the zone', () {
      expect(ShowDateFormat.gmtOffset(const Duration(hours: -3)), 'GMT-3');
      expect(
        ShowDateFormat.gmtOffset(const Duration(hours: 5, minutes: 30)),
        'GMT+5:30',
      );
      expect(ShowDateFormat.gmtOffset(Duration.zero), 'GMT');
    });

    test('counts calendar days, not hours', () {
      final lateTonight = DateTime(2024, 11, 26, 23);
      expect(
        ShowDateFormat.countdown(DateTime(2024, 11, 27, 9), now: lateTonight),
        'Mañana',
      );
      expect(
        ShowDateFormat.countdown(DateTime(2024, 11, 26, 23, 30), now: lateTonight),
        'Hoy',
      );
      expect(
        ShowDateFormat.countdown(DateTime(2024, 11, 28, 19), now: lateTonight),
        'En 2 días',
      );
      expect(
        ShowDateFormat.countdown(DateTime(2024, 11, 26, 20), now: lateTonight),
        'Ya pasó',
      );
    });

    test('formats durations', () {
      expect(ShowDateFormat.duration(45), '45 min');
      expect(ShowDateFormat.duration(60), '1 h');
      expect(ShowDateFormat.duration(150), '2 h 30 min');
    });
  });
}
