const _months = [
  'Ocak',
  'Şubat',
  'Mart',
  'Nisan',
  'Mayıs',
  'Haziran',
  'Temmuz',
  'Ağustos',
  'Eylül',
  'Ekim',
  'Kasım',
  'Aralık',
];

const _shortMonths = [
  'Oca',
  'Şub',
  'Mar',
  'Nis',
  'May',
  'Haz',
  'Tem',
  'Ağu',
  'Eyl',
  'Eki',
  'Kas',
  'Ara',
];

String formatTurkishDate(DateTime date) {
  return '${date.day} ${_months[date.month - 1]} ${date.year}';
}

String formatShortDate(DateTime date) {
  return '${date.day} ${_shortMonths[date.month - 1]}';
}

/// Short month + year, e.g. "8 Eki 2026".
String formatShortDateWithYear(DateTime date) {
  return '${date.day} ${_shortMonths[date.month - 1]} ${date.year}';
}
