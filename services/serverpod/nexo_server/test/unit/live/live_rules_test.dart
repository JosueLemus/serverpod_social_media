import 'package:nexo_server/src/generated/protocol.dart';
import 'package:nexo_server/src/modules/live/services/live_rules.dart';
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';

Matcher _throwsInvalid() => throwsA(
  isA<NexoException>().having(
    (e) => e.code,
    'code',
    NexoErrorCode.invalidInput,
  ),
);

void main() {
  group('Given LiveRules.transitions', () {
    const allowed = {
      (LiveShowStatus.draft, LiveShowStatus.scheduled),
      (LiveShowStatus.draft, LiveShowStatus.cancelled),
      (LiveShowStatus.scheduled, LiveShowStatus.live),
      (LiveShowStatus.scheduled, LiveShowStatus.cancelled),
      (LiveShowStatus.live, LiveShowStatus.ending),
      (LiveShowStatus.live, LiveShowStatus.recorded),
      (LiveShowStatus.live, LiveShowStatus.failed),
      (LiveShowStatus.ending, LiveShowStatus.recorded),
      (LiveShowStatus.recorded, LiveShowStatus.published),
      (LiveShowStatus.recorded, LiveShowStatus.removed),
      (LiveShowStatus.published, LiveShowStatus.removed),
    };

    test('then exactly the SDD 0001 pairs are legal', () {
      for (final from in LiveShowStatus.values) {
        for (final to in LiveShowStatus.values) {
          expect(
            LiveRules.canTransition(from, to),
            allowed.contains((from, to)),
            reason: '${from.name} → ${to.name}',
          );
        }
      }
    });

    test('then cancelled, failed and removed are terminal', () {
      for (final terminal in [
        LiveShowStatus.cancelled,
        LiveShowStatus.failed,
        LiveShowStatus.removed,
      ]) {
        expect(
          LiveShowStatus.values.where(
            (to) => LiveRules.canTransition(terminal, to),
          ),
          isEmpty,
        );
      }
    });
  });

  group('Given a show draft', () {
    test('when the title is blank or too long then it is invalid', () {
      expect(() => LiveRules.normalizeTitle('   '), _throwsInvalid());
      expect(
        () => LiveRules.normalizeTitle('x' * (LiveRules.maxTitleLength + 1)),
        _throwsInvalid(),
      );
      expect(LiveRules.normalizeTitle('  Masterclass  '), 'Masterclass');
    });

    test('when the duration is out of range then it is invalid', () {
      expect(() => LiveRules.checkDuration(10), _throwsInvalid());
      expect(() => LiveRules.checkDuration(241), _throwsInvalid());
      expect(LiveRules.checkDuration(60), 60);
    });

    test('when it starts now or earlier then it is invalid', () {
      final now = DateTime.utc(2026, 10, 11, 12);
      expect(() => LiveRules.checkStartsAt(now, now), _throwsInvalid());
      expect(
        LiveRules.checkStartsAt(now.add(const Duration(minutes: 1)), now),
        now.add(const Duration(minutes: 1)),
      );
    });

    test('when guests repeat or carry @ then they come back clean', () {
      expect(LiveRules.normalizeGuests(['@Tomas', 'tomas', ' ana ', '']), [
        'tomas',
        'ana',
      ]);
      expect(
        () => LiveRules.normalizeGuests(['a', 'b', 'c', 'd']),
        _throwsInvalid(),
      );
    });
  });

  group('Given a chat message', () {
    test('when it is blank or too long then it is invalid', () {
      expect(() => LiveRules.normalizeChat('  '), _throwsInvalid());
      expect(
        () => LiveRules.normalizeChat('x' * (LiveRules.maxChatLength + 1)),
        _throwsInvalid(),
      );
      expect(LiveRules.normalizeChat('  hola  '), 'hola');
    });
  });

  group('Given the video channel rules', () {
    final elena = UuidValue.fromString('01a12c4d-5408-760b-8bc2-03c7b5e24f14');
    final carlos = UuidValue.fromString(
      '01a12c4d-5552-78f1-a058-c64efb1fca83',
    );

    test('then the channel is the one the app builds', () {
      expect(LiveRules.mediaChannel(12), 'nexo_live_12');
    });

    test('then a uid is stable, positive and fits in 31 bits', () {
      final uid = LiveRules.mediaUid(elena);

      expect(LiveRules.mediaUid(elena), uid);
      expect(uid, greaterThan(0));
      expect(uid, lessThan(1 << 31));
    });

    /// Las cuentas sembradas juntas tienen UUIDs v7 casi iguales: un uid
    /// sacado del prefijo las haría chocar en el mismo canal.
    test('then two accounts created together get different uids', () {
      expect(LiveRules.mediaUid(elena), isNot(LiveRules.mediaUid(carlos)));
    });

    test('then a guest gets 0 and Agora assigns one', () {
      expect(LiveRules.mediaUid(null), 0);
    });
  });
}
