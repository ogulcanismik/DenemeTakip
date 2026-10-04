import 'package:deneme_takip/domain/exam_type.dart';

class SectionCounts {
  const SectionCounts(this.correct, this.incorrect);

  final num correct;
  final num incorrect;
}

enum InputIssueKind { negative, nonInteger, overflow }

class InputIssue {
  const InputIssue(this.sectionId, this.kind);

  final String sectionId;
  final InputIssueKind kind;
}

class ComputedSection {
  const ComputedSection({
    required this.sectionId,
    required this.correctCount,
    required this.incorrectCount,
    required this.emptyCount,
    required this.net,
  });

  final String sectionId;
  final int correctCount;
  final int incorrectCount;
  final int emptyCount;
  final double net;
}

class NetResult {
  const NetResult({
    required this.sections,
    required this.totalNet,
    required this.issues,
  });

  final List<ComputedSection> sections;
  final double totalNet;
  final List<InputIssue> issues;

  bool get isValid => issues.isEmpty;

  ComputedSection? find(String sectionId) {
    for (final section in sections) {
      if (section.sectionId == sectionId) return section;
    }
    return null;
  }

  InputIssue? issueFor(String sectionId) {
    for (final issue in issues) {
      if (issue.sectionId == sectionId) return issue;
    }
    return null;
  }
}

abstract final class NetEngine {
  /// Net = correct when [ExamType.penaltyDivisor] is 0 (no wrong penalty).
  /// Otherwise net = correct - (incorrect / penaltyDivisor).
  /// Empty = questionCount - correct - incorrect.
  /// Invalid sections are omitted. The total is the raw sum of valid nets.
  static NetResult evaluate(ExamType exam, Map<String, SectionCounts> counts) {
    final sections = <ComputedSection>[];
    final issues = <InputIssue>[];
    var total = 0.0;

    for (final definition in exam.sections) {
      final input = counts[definition.id];
      if (input == null) {
        issues.add(InputIssue(definition.id, InputIssueKind.nonInteger));
        continue;
      }

      final correct = input.correct;
      final incorrect = input.incorrect;
      if (!_isWhole(correct) || !_isWhole(incorrect)) {
        issues.add(InputIssue(definition.id, InputIssueKind.nonInteger));
        continue;
      }

      final correctCount = correct.toInt();
      final incorrectCount = incorrect.toInt();
      if (correctCount < 0 || incorrectCount < 0) {
        issues.add(InputIssue(definition.id, InputIssueKind.negative));
        continue;
      }
      if (correctCount + incorrectCount > definition.questionCount) {
        issues.add(InputIssue(definition.id, InputIssueKind.overflow));
        continue;
      }

      final emptyCount =
          definition.questionCount - correctCount - incorrectCount;
      final net = exam.penaltyDivisor == 0
          ? correctCount.toDouble()
          : correctCount - (incorrectCount / exam.penaltyDivisor);
      total += net;
      sections.add(
        ComputedSection(
          sectionId: definition.id,
          correctCount: correctCount,
          incorrectCount: incorrectCount,
          emptyCount: emptyCount,
          net: net,
        ),
      );
    }

    return NetResult(sections: sections, totalNet: total, issues: issues);
  }

  static bool _isWhole(num value) {
    if (value is int) return true;
    if (value is! double || !value.isFinite) return false;
    return value == value.truncateToDouble();
  }
}
