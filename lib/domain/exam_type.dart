import 'dart:math';

class SectionDefinition {
  const SectionDefinition({
    required this.id,
    required this.name,
    required this.questionCount,
  });

  final String id;
  final String name;
  final int questionCount;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'questionCount': questionCount,
  };

  factory SectionDefinition.fromJson(Map<String, dynamic> json) {
    final rawCount = json['questionCount'];
    final count = rawCount is num ? rawCount.toInt() : 0;
    return SectionDefinition(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      questionCount: count,
    );
  }
}

class ExamType {
  const ExamType({
    required this.id,
    required this.name,
    required this.penaltyDivisor,
    required this.sections,
    required this.defaultTargetNet,
  });

  final String id;
  final String name;
  final int penaltyDivisor;
  final List<SectionDefinition> sections;
  final double defaultTargetNet;

  bool get isCustom => id.startsWith('custom_');

  int get totalQuestionCount {
    var total = 0;
    for (final section in sections) {
      total += section.questionCount;
    }
    return total;
  }

  SectionDefinition? sectionById(String id) {
    for (final section in sections) {
      if (section.id == id) return section;
    }
    return null;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'penaltyDivisor': penaltyDivisor,
    'defaultTargetNet': defaultTargetNet,
    'sections': [for (final section in sections) section.toJson()],
  };

  factory ExamType.fromJson(Map<String, dynamic> json) {
    final rawPenalty = json['penaltyDivisor'];
    final rawTarget = json['defaultTargetNet'];
    final rawSections = json['sections'];
    final sections = <SectionDefinition>[];
    if (rawSections is List) {
      for (final item in rawSections) {
        if (item is! Map) continue;
        sections.add(
          SectionDefinition.fromJson(Map<String, dynamic>.from(item)),
        );
      }
    }
    return ExamType(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      penaltyDivisor: rawPenalty is num ? rawPenalty.toInt() : 0,
      defaultTargetNet: rawTarget is num ? rawTarget.toDouble() : 0,
      sections: sections,
    );
  }
}

/// Suggested hedef net ≈ 70% of total questions (min 1).
double suggestedTargetNet(Iterable<SectionDefinition> sections) {
  var total = 0;
  for (final section in sections) {
    total += section.questionCount;
  }
  if (total <= 0) return 1;
  final suggested = (total * 0.7).roundToDouble();
  return suggested < 1 ? 1 : suggested;
}

String newCustomExamId() {
  final micros = DateTime.now().toUtc().microsecondsSinceEpoch.toRadixString(
    16,
  );
  final salt = Random().nextInt(0x7fffffff).toRadixString(16);
  return 'custom_$micros$salt';
}

String newSectionId() {
  final micros = DateTime.now().toUtc().microsecondsSinceEpoch.toRadixString(
    16,
  );
  final salt = Random().nextInt(0x7fffffff).toRadixString(16);
  return 's_$micros$salt';
}
