import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_social/core/utils/relative_time.dart';

void main() {
  // Fixed so the assertions do not race the wall clock.
  final now = DateTime(2026, 9, 27, 12);

  String format(Duration ago) =>
      RelativeTime.format(now.subtract(ago), now: now);

  test('collapses anything under a minute to "ahora"', () {
    expect(format(Duration.zero), 'ahora');
    expect(format(const Duration(seconds: 59)), 'ahora');
  });

  test('counts minutes, then hours, then days, then weeks', () {
    expect(format(const Duration(minutes: 1)), '1 min');
    expect(format(const Duration(minutes: 59)), '59 min');
    expect(format(const Duration(hours: 1)), '1 h');
    expect(format(const Duration(hours: 23)), '23 h');
    expect(format(const Duration(days: 1)), '1 d');
    expect(format(const Duration(days: 6)), '6 d');
    expect(format(const Duration(days: 7)), '1 sem');
    expect(format(const Duration(days: 21)), '3 sem');
  });

  test('a timestamp in the future reads as "ahora", never as negative', () {
    // Device and server clocks disagree by seconds all the time. "hace -3 min"
    // is the kind of thing that only ever shows up in a screenshot from a
    // user.
    expect(
      RelativeTime.format(now.add(const Duration(minutes: 5)), now: now),
      'ahora',
    );
  });
}
