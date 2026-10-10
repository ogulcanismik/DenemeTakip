import 'package:deneme_takip/domain/analysis_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('calculateRollingAverage', () {
    test('returns null for empty or invalid window', () {
      expect(AnalysisEngine.calculateRollingAverage([], 5), isNull);
      expect(AnalysisEngine.calculateRollingAverage([1, 2], 0), isNull);
    });

    test('uses all values when fewer than window', () {
      expect(
        AnalysisEngine.calculateRollingAverage([10, 20, 30], 5),
        20,
      );
    });

    test('uses last windowSize values', () {
      expect(
        AnalysisEngine.calculateRollingAverage([1, 2, 3, 4, 5, 6], 3),
        5,
      );
    });
  });

  group('calculateRecencyWeightedAverage', () {
    test('returns null for empty', () {
      expect(AnalysisEngine.calculateRecencyWeightedAverage([]), isNull);
    });

    test('single item equals itself', () {
      expect(AnalysisEngine.calculateRecencyWeightedAverage([42]), 42);
    });

    test('weights newest higher (1.0, 0.9, …)', () {
      // newestFirst: 10 @1.0, 0 @0.9 → (10+0)/(1.0+0.9) = 10/1.9
      expect(
        AnalysisEngine.calculateRecencyWeightedAverage([10, 0]),
        closeTo(10 / 1.9, 1e-9),
      );
    });

    test('11th exam (i=10) has zero weight and is ignored', () {
      // 10 contributing: 1.0+0.9+…+0.1 = 5.5; values all 2 except ignored 11th
      final values = List<double>.filled(11, 2);
      values[10] = 999;
      expect(
        AnalysisEngine.calculateRecencyWeightedAverage(values),
        closeTo(2, 1e-9),
      );
    });
  });

  group('calculateWeightedCountAverages', () {
    test('weights correct / incorrect / empty newest-first', () {
      // newest @1.0, older @0.9 → Σw = 1.9
      final avgs = AnalysisEngine.calculateWeightedCountAverages(
        correctNewestFirst: [30, 20],
        incorrectNewestFirst: [5, 10],
        emptyNewestFirst: [5, 10],
      );
      expect(avgs.correct, closeTo(48 / 1.9, 1e-9));
      expect(avgs.incorrect, closeTo(14 / 1.9, 1e-9));
      expect(avgs.empty, closeTo(14 / 1.9, 1e-9));
    });
  });

  group('calculateDeltaPercentage', () {
    test('computes percent change vs baseline', () {
      expect(
        AnalysisEngine.calculateDeltaPercentage(110, 100),
        closeTo(10, 1e-9),
      );
      expect(
        AnalysisEngine.calculateDeltaPercentage(90, 100),
        closeTo(-10, 1e-9),
      );
    });

    test('zero baseline edge cases', () {
      expect(AnalysisEngine.calculateDeltaPercentage(0, 0), 0);
      expect(AnalysisEngine.calculateDeltaPercentage(5, 0), isNull);
    });
  });

  group('calculateRange', () {
    test('peak over all history, floor over window', () {
      final range = AnalysisEngine.calculateRange(
        [5, 20, 8, 12, 3, 15],
        windowSize: 5,
      );
      expect(range.peak, 20);
      expect(range.floor, 3);
    });

    test('empty list', () {
      final range = AnalysisEngine.calculateRange([], windowSize: 5);
      expect(range.peak, isNull);
      expect(range.floor, isNull);
    });
  });

  group('calculateRatios', () {
    test('accuracy and attempt rates', () {
      final ratios = AnalysisEngine.calculateRatios(
        correct: 8,
        incorrect: 2,
        totalQuestions: 20,
      );
      expect(ratios.accuracyRate, closeTo(80, 1e-9));
      expect(ratios.attemptRate, closeTo(50, 1e-9));
    });

    test('no attempts yields null accuracy', () {
      final ratios = AnalysisEngine.calculateRatios(
        correct: 0,
        incorrect: 0,
        totalQuestions: 40,
      );
      expect(ratios.accuracyRate, isNull);
      expect(ratios.attemptRate, 0);
    });
  });

  group('movingAverageSeries', () {
    test('trailing average with partial start', () {
      final series = AnalysisEngine.movingAverageSeries([2, 4, 6, 8], 3);
      expect(series, hasLength(4));
      expect(series[0], 2);
      expect(series[1], 3);
      expect(series[2], 4);
      expect(series[3], closeTo(6, 1e-9));
    });
  });
}
