int weeklyStreak(Iterable<DateTime> dates, {required DateTime today}) {
  final weeks = <DateTime>{for (final date in dates) isoWeekStart(date)};
  var cursor = isoWeekStart(today);
  var streak = 0;
  while (weeks.contains(cursor)) {
    streak += 1;
    cursor = cursor.subtract(const Duration(days: 7));
  }
  return streak;
}

DateTime isoWeekStart(DateTime date) {
  final day = DateTime(date.year, date.month, date.day);
  return day.subtract(Duration(days: day.weekday - DateTime.monday));
}
