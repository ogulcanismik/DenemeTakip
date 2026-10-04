import 'package:deneme_takip/domain/exam_migration.dart';
import 'package:deneme_takip/domain/exam_registry.dart';
import 'package:deneme_takip/domain/net_engine.dart';
import 'package:deneme_takip/domain/net_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final yks = ExamRegistry.byId('yks_tyt')!;
  final lgs = ExamRegistry.byId('lgs')!;
  final hmgs = ExamRegistry.byId('hmgs')!;

  test('YKS TYT subtracts incorrect divided by 4', () {
    final result = NetEngine.evaluate(yks, const {
      'tr': SectionCounts(30, 4),
      'sos': SectionCounts(0, 0),
      'mat': SectionCounts(20, 8),
      'fen': SectionCounts(0, 0),
    });

    expect(result.isValid, isTrue);
    expect(result.find('tr')!.net, 29);
    expect(result.find('tr')!.emptyCount, 6);
    expect(result.find('mat')!.net, 18);
    expect(result.find('mat')!.emptyCount, 12);
    expect(result.find('sos')!.net, 0);
    expect(result.find('fen')!.emptyCount, 20);
    expect(result.totalNet, 47);
  });

  test('LGS subtracts incorrect divided by 3 without rounding the sum', () {
    final result = NetEngine.evaluate(lgs, const {
      'tr': SectionCounts(8, 2),
      'mat': SectionCounts(0, 2),
      'fen': SectionCounts(0, 0),
      'ink': SectionCounts(0, 0),
      'din': SectionCounts(0, 0),
      'dil': SectionCounts(0, 0),
    });

    expect(result.isValid, isTrue);
    expect(result.find('tr')!.net, closeTo(8 - 2 / 3, 1e-12));
    expect(result.find('tr')!.emptyCount, 10);
    expect(result.find('mat')!.net, closeTo(-2 / 3, 1e-12));
    expect(result.totalNet, closeTo(8 - 4 / 3, 1e-12));
  });

  test('HMGS ignores wrong answers when penaltyDivisor is 0', () {
    final result = NetEngine.evaluate(hmgs, {
      for (final section in hmgs.sections)
        section.id: section.id == 'anayasa'
            ? const SectionCounts(5, 1)
            : const SectionCounts(0, 0),
    });

    expect(result.isValid, isTrue);
    expect(result.find('anayasa')!.net, 5);
    expect(result.find('anayasa')!.emptyCount, 0);
    expect(result.totalNet, 5);
  });

  test('empty count is question count minus correct minus incorrect', () {
    final result = NetEngine.evaluate(yks, const {
      'tr': SectionCounts(25, 5),
      'sos': SectionCounts(20, 0),
      'mat': SectionCounts(0, 0),
      'fen': SectionCounts(0, 8),
    });

    expect(result.isValid, isTrue);
    expect(result.find('tr')!.emptyCount, 10);
    expect(result.find('tr')!.net, 23.75);
    expect(result.find('sos')!.emptyCount, 0);
    expect(result.find('sos')!.net, 20);
    expect(result.find('mat')!.emptyCount, 40);
    expect(result.find('fen')!.emptyCount, 12);
    expect(result.find('fen')!.net, -2);
    expect(result.totalNet, 41.75);
  });

  test('rejects correct plus incorrect above the question count', () {
    final result = NetEngine.evaluate(yks, const {
      'tr': SectionCounts(39, 2),
      'sos': SectionCounts(0, 0),
      'mat': SectionCounts(30, 10),
      'fen': SectionCounts(0, 0),
    });

    expect(result.isValid, isFalse);
    expect(result.issueFor('tr')?.kind, InputIssueKind.overflow);
    expect(result.find('tr'), isNull);
    expect(result.find('mat')!.emptyCount, 0);
    expect(result.find('mat')!.net, 27.5);
  });

  test('rejects negative and non-integer counts', () {
    final result = NetEngine.evaluate(yks, {
      'tr': const SectionCounts(-1, 0),
      'sos': const SectionCounts(1.5, 0),
      'mat': const SectionCounts(0, 0),
      'fen': SectionCounts(0, double.nan),
    });

    expect(result.isValid, isFalse);
    expect(result.issueFor('tr')?.kind, InputIssueKind.negative);
    expect(result.issueFor('sos')?.kind, InputIssueKind.nonInteger);
    expect(result.issueFor('fen')?.kind, InputIssueKind.nonInteger);
    expect(result.find('mat')!.net, 0);
  });

  test('formats nets with a Turkish comma and trims trailing zeros', () {
    expect(formatNet(29), '29');
    expect(formatNet(29.5), '29,5');
    expect(formatNet(23.75), '23,75');
    expect(formatNet(8 - 2 / 3), '7,33');
    expect(formatNet(0), '0');
    expect(formatNet(-2), '-2');
  });

  test('migrates legacy exam and section ids', () {
    expect(ExamMigration.migrateExamTypeId('yks-tyt'), 'yks_tyt');
    expect(ExamMigration.migrateExamTypeId('kpss-lisans'), 'kpss_lisans');
    expect(ExamMigration.migrateExamTypeId('lgs'), 'lgs');
    expect(ExamMigration.migrateSectionId('yks_tyt', 'turkce'), 'tr');
    expect(ExamMigration.migrateSectionId('yks_tyt', 'sosyal'), 'sos');
    expect(ExamMigration.migrateSectionId('yks_tyt', 'matematik'), 'mat');
    expect(ExamMigration.migrateSectionId('lgs', 'inkilap'), 'ink');
    expect(ExamMigration.migrateSectionId('lgs', 'yabanci'), 'dil');
  });
}
