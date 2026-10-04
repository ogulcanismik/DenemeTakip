String formatNet(double value) {
  if (!value.isFinite) return '—';
  final negative = value < 0;
  final absolute = negative ? -value : value;
  final trimmed = absolute
      .toStringAsFixed(2)
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');
  final text = trimmed.replaceAll('.', ',');
  return negative ? '-$text' : text;
}
