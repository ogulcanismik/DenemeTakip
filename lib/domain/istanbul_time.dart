DateTime istanbulToday() {
  final shifted = DateTime.now().toUtc().add(const Duration(hours: 3));
  return DateTime(shifted.year, shifted.month, shifted.day);
}
