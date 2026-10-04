class SectionDefinition {
  const SectionDefinition({
    required this.id,
    required this.name,
    required this.questionCount,
  });

  final String id;
  final String name;
  final int questionCount;
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

  String get penaltyLabel => '$penaltyDivisor yanlış 1 doğruyu götürür';

  SectionDefinition? sectionById(String id) {
    for (final section in sections) {
      if (section.id == id) return section;
    }
    return null;
  }
}
