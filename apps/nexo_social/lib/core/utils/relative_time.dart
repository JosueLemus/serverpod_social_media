/// Short relative timestamps, feed style: `ahora`, `25 min`, `3 h`, `2 d`.
///
/// One implementation for the whole app. The feed used to print a hardcoded
/// "hace 25 min" on every row, and once real dates arrive the temptation is to
/// reach for `DateFormat` inside a widget — which puts formatting in the view
/// and makes the string untestable without pumping one.
abstract final class RelativeTime {
  /// [now] is injectable so tests assert against a fixed clock instead of
  /// racing the wall clock.
  static String format(DateTime moment, {DateTime? now}) {
    final elapsed = (now ?? DateTime.now()).difference(moment);

    // A timestamp slightly in the future (clock skew between a device and the
    // server) must not render as a negative age.
    if (elapsed.isNegative || elapsed.inMinutes < 1) return 'ahora';
    if (elapsed.inMinutes < 60) return '${elapsed.inMinutes} min';
    if (elapsed.inHours < 24) return '${elapsed.inHours} h';
    if (elapsed.inDays < 7) return '${elapsed.inDays} d';
    return '${(elapsed.inDays / 7).floor()} sem';
  }
}
