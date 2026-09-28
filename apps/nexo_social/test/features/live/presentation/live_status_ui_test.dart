import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_social/features/live/domain/entities/live_session.dart';
import 'package:nexo_social/features/live/presentation/utils/live_status_ui.dart';

void main() {
  /// Regression: the list printed `status.name`, so users read "live",
  /// "scheduled" and "recorded" — backend identifiers, in English, in a
  /// Spanish app.
  test('every status has a label that is not its Dart identifier', () {
    for (final status in LiveStatus.values) {
      expect(status.label, isNotEmpty);
      expect(
        status.label,
        isNot(status.name),
        reason: '${status.name} se está pintando con .name',
      );
    }
  });

  test('every status has a colour', () {
    // An exhaustive switch means a new status fails to compile rather than
    // falling through to a default nobody chose.
    for (final status in LiveStatus.values) {
      expect(status.color, isNotNull);
    }
  });

  group('what the status means', () {
    test('only an active broadcast is on air', () {
      expect(LiveStatus.live.isOnAir, isTrue);
      expect(LiveStatus.ending.isOnAir, isTrue);
      for (final status in [
        LiveStatus.draft,
        LiveStatus.scheduled,
        LiveStatus.recorded,
        LiveStatus.published,
        LiveStatus.cancelled,
      ]) {
        expect(
          status.isOnAir,
          isFalse,
          reason: '${status.name} no está al aire',
        );
      }
    });

    test('a recorded session is not closed — it has a replay', () {
      expect(LiveStatus.recorded.isClosed, isFalse);
      expect(LiveStatus.published.isClosed, isFalse);
      expect(LiveStatus.cancelled.isClosed, isTrue);
      expect(LiveStatus.failed.isClosed, isTrue);
      expect(LiveStatus.removed.isClosed, isTrue);
    });
  });
}
