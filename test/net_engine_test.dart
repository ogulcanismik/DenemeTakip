import 'package:deneme_takip/domain/exam_registry.dart';
import 'package:deneme_takip/domain/net_engine.dart';
import 'package:deneme_takip/domain/net_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final yks = ExamRegistry.byId('yks-tyt')!;
  final lgs = ExamRegistry.byId('lgs')!;

  test('YKS TYT subtracts incorrect divided by 4', () {
    final result = NetEngine.evaluate(yks, const {
      'turkce': SectionCounts(30, 4),
      'sosyal': SectionCounts(0, 0),
      'matematik': SectionCounts(20, 8),
      'fen': SectionCounts(0, 0),
    });

    expect(result.isValid, isTrue);
    expect(result.find('turkce')!.net, 29);
    expect(result.find('turkce')!.emptyCount, 6);
    expect(result.find('matematik')!.net, 18);
    expect(result.find('matematik')!.emptyCount, 12);
    expect(result.find('sosyal')!.net, 0);
    expect(result.find('fen')!.emptyCount, 20);
    expect(result.totalNet, 47);
  });

  test('LGS subtracts incorrect divided by 3 without rounding the sum', () {
    final result = NetEngine.evaluate(lgs, const {
      'turkce': SectionCounts(8, 2),
      'matematik': SectionCounts(0, 2),
      'fen': SectionCounts(0, 0),
      'inkilap': SectionCounts(0, 0),
      'din': SectionCounts(0, 0),
      'yabanci': SectionCounts(0, 0),
    });

    expect(result.isValid, isTrue);
    expect(result.find('turkce')!.net, closeTo(8 - 2 / 3, 1e-12));
    expect(result.find('turkce')!.emptyCount, 10);
    expect(result.find('matematik')!.net, closeTo(-2 / 3, 1e-12));
    expect(result.totalNet, closeTo(8 - 4 / 3, 1e-12));
  });

  test('empty count is question count minus correct minus incorrect', () {
    final result = NetEngine.evaluate(yks, const {
      'turkce': SectionCounts(25, 5),
      'sosyal': SectionCounts(20, 0),
      'matematik': SectionCounts(0, 0),
      'fen': SectionCounts(0, 8),
    });

    expect(result.isValid, isTrue);
    expect(result.find('turkce')!.emptyCount, 10);
    expect(result.find('turkce')!.net, 23.75);
    expect(result.find('sosyal')!.emptyCount, 0);
    expect(result.find('sosyal')!.net, 20);
    expect(result.find('matematik')!.emptyCount, 40);
    expect(result.find('fen')!.emptyCount, 12);
    expect(result.find('fen')!.net, -2);
    expect(result.totalNet, 41.75);
  });

  test('rejects correct plus incorrect above the question count', () {
    final result = NetEngine.evaluate(yks, const {
      'turkce': SectionCounts(39, 2),
      'sosyal': SectionCounts(0, 0),
      'matematik': SectionCounts(30, 10),
      'fen': SectionCounts(0, 0),
    });

    expect(result.isValid, isFalse);
    expect(result.issueFor('turkce')?.kind, InputIssueKind.overflow);
    expect(result.find('turkce'), isNull);
    expect(result.find('matematik')!.emptyCount, 0);
    expect(result.find('matematik')!.net, 27.5);
  });

  test('rejects negative and non-integer counts', () {
    final result = NetEngine.evaluate(yks, {
      'turkce': const SectionCounts(-1, 0),
      'sosyal': const SectionCounts(1.5, 0),
      'matematik': const SectionCounts(0, 0),
      'fen': SectionCounts(0, double.nan),
    });

    expect(result.isValid, isFalse);
    expect(result.issueFor('turkce')?.kind, InputIssueKind.negative);
    expect(result.issueFor('sosyal')?.kind, InputIssueKind.nonInteger);
    expect(result.issueFor('fen')?.kind, InputIssueKind.nonInteger);
    expect(result.find('matematik')!.net, 0);
  });

  test('formats nets with a Turkish comma and trims trailing zeros', () {
    expect(formatNet(29), '29');
    expect(formatNet(29.5), '29,5');
    expect(formatNet(23.75), '23,75');
    expect(formatNet(8 - 2 / 3), '7,33');
    expect(formatNet(0), '0');
    expect(formatNet(-2), '-2');
  });
}
