import 'dart:math';

class SectionScore {
  const SectionScore({
    required this.sectionId,
    required this.correctCount,
    required this.incorrectCount,
    required this.emptyCount,
    required this.calculatedNet,
  });

  final String sectionId;
  final int correctCount;
  final int incorrectCount;
  final int emptyCount;
  final double calculatedNet;

  Map<String, dynamic> toJson() => {
    'sectionId': sectionId,
    'correctCount': correctCount,
    'incorrectCount': incorrectCount,
    'emptyCount': emptyCount,
    'calculatedNet': calculatedNet,
  };

  factory SectionScore.fromJson(Map<String, dynamic> json) {
    return SectionScore(
      sectionId: _asString(json['sectionId']),
      correctCount: _asInt(json['correctCount']),
      incorrectCount: _asInt(json['incorrectCount']),
      emptyCount: _asInt(json['emptyCount']),
      calculatedNet: _asDouble(json['calculatedNet']),
    );
  }
}

class DenemeEntry {
  const DenemeEntry({
    required this.id,
    required this.examTypeId,
    required this.title,
    required this.date,
    required this.durationMinutes,
    required this.difficultyRating,
    required this.sections,
    required this.totalNet,
  });

  final String id;
  final String examTypeId;
  final String title;
  final DateTime date;
  final int? durationMinutes;
  final int? difficultyRating;
  final List<SectionScore> sections;
  final double totalNet;

  Map<String, dynamic> toJson() => {
    'id': id,
    'examTypeId': examTypeId,
    'title': title,
    'date': formatIsoDate(date),
    'durationMinutes': durationMinutes,
    'difficultyRating': difficultyRating,
    'sections': [for (final section in sections) section.toJson()],
    'totalNet': totalNet,
  };

  factory DenemeEntry.fromJson(Map<String, dynamic> json) {
    final rawSections = json['sections'];
    if (rawSections is! List) {
      throw const FormatException('sections eksik');
    }
    return DenemeEntry(
      id: _asString(json['id']),
      examTypeId: _asString(json['examTypeId']),
      title: _asString(json['title']),
      date: parseIsoDate(_asString(json['date'])),
      durationMinutes: _asOptionalInt(json['durationMinutes']),
      difficultyRating: _asOptionalInt(json['difficultyRating']),
      sections: [
        for (final item in rawSections)
          SectionScore.fromJson(Map<String, dynamic>.from(item as Map)),
      ],
      totalNet: _asDouble(json['totalNet']),
    );
  }
}

String newEntryId() {
  final micros = DateTime.now().toUtc().microsecondsSinceEpoch.toRadixString(
    16,
  );
  final salt = Random().nextInt(1 << 32).toRadixString(16);
  return '$micros$salt';
}

String formatIsoDate(DateTime date) {
  final year = date.year.toString().padLeft(4, '0');
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}

DateTime parseIsoDate(String value) {
  final parts = value.split('-');
  if (parts.length != 3) {
    throw FormatException('Tarih okunamadı: $value');
  }
  final year = int.parse(parts[0]);
  final month = int.parse(parts[1]);
  final day = int.parse(parts[2]);
  return DateTime(year, month, day);
}

String _asString(Object? value) {
  if (value is String && value.isNotEmpty) return value;
  throw const FormatException('Metin eksik');
}

int _asInt(Object? value) {
  if (value is int) return value;
  if (value is double && value == value.truncateToDouble()) {
    return value.toInt();
  }
  throw const FormatException('Tam sayı değil');
}

int? _asOptionalInt(Object? value) {
  if (value == null) return null;
  return _asInt(value);
}

double _asDouble(Object? value) {
  if (value is int) return value.toDouble();
  if (value is double) return value;
  throw const FormatException('Sayı değil');
}
