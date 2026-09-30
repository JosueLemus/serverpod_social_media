abstract final class ShowDateFormat {
  static const _weekdays = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
  static const _months = [
    'Ene',
    'Feb',
    'Mar',
    'Abr',
    'May',
    'Jun',
    'Jul',
    'Ago',
    'Sep',
    'Oct',
    'Nov',
    'Dic',
  ];

  static String date(DateTime moment) =>
      '${_weekdays[moment.weekday - 1]}, ${moment.day} '
      '${_months[moment.month - 1]} ${moment.year}';

  static String shortDate(DateTime moment) =>
      '${moment.day} ${_months[moment.month - 1]}';

  static String time(DateTime moment) =>
      '${_two(moment.hour)}:${_two(moment.minute)}';

  static String gmtOffset(Duration offset) {
    if (offset == Duration.zero) return 'GMT';
    final sign = offset.isNegative ? '-' : '+';
    final minutes = offset.inMinutes.abs();
    final hours = minutes ~/ 60;
    final rest = minutes % 60;
    return rest == 0 ? 'GMT$sign$hours' : 'GMT$sign$hours:${_two(rest)}';
  }

  static String countdown(DateTime moment, {required DateTime now}) {
    if (!moment.isAfter(now)) return 'Ya pasó';
    final days = DateTime(
      moment.year,
      moment.month,
      moment.day,
    ).difference(DateTime(now.year, now.month, now.day)).inDays;
    return switch (days) {
      0 => 'Hoy',
      1 => 'Mañana',
      _ => 'En $days días',
    };
  }

  static String duration(int minutes) {
    if (minutes < 60) return '$minutes min';
    final hours = minutes ~/ 60;
    final rest = minutes % 60;
    return rest == 0 ? '$hours h' : '$hours h $rest min';
  }

  static String _two(int value) => value.toString().padLeft(2, '0');
}
