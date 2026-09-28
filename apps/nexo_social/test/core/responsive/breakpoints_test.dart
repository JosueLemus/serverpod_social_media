import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_social/core/responsive/breakpoints.dart';

void main() {
  group('form factor boundaries', () {
    test('a phone is compact', () {
      expect(AppBreakpoints.fromWidth(320), FormFactor.compact);
      expect(AppBreakpoints.fromWidth(430), FormFactor.compact);
      expect(AppBreakpoints.fromWidth(699), FormFactor.compact);
    });

    test('a tablet is medium', () {
      expect(AppBreakpoints.fromWidth(700), FormFactor.medium);
      expect(AppBreakpoints.fromWidth(1099), FormFactor.medium);
    });

    test('a desktop window is expanded', () {
      expect(AppBreakpoints.fromWidth(1100), FormFactor.expanded);
      expect(AppBreakpoints.fromWidth(2560), FormFactor.expanded);
    });

    // The boundary itself, stated once. Two screens that each pick their own
    // comparison stop switching at the same width and the app reflows in
    // pieces.
    test('the boundaries are inclusive at the lower edge', () {
      expect(
        AppBreakpoints.fromWidth(AppBreakpoints.medium),
        FormFactor.medium,
      );
      expect(
        AppBreakpoints.fromWidth(AppBreakpoints.expanded),
        FormFactor.expanded,
      );
    });
  });

  group('what each form factor implies', () {
    test('only compact uses the bottom bar', () {
      expect(FormFactor.compact.hasRail, isFalse);
      expect(FormFactor.medium.hasRail, isTrue);
      expect(FormFactor.expanded.hasRail, isTrue);
    });
  });
}
