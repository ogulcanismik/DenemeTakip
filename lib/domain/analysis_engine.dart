/// Pure analysis helpers — no Flutter UI imports.
///
/// Ratio aggregates use **all** exams in the active exam type for the selected
/// scope (Genel = every section; subject = that section only), not a rolling
/// window. Form / floor / chart windows are documented on each call site.
abstract final class AnalysisEngine {
  /// Mean of the last [windowSize] values (or all values if fewer).
  static double? calculateRollingAverage(
    List<double> values,
    int windowSize,
  ) {
    if (values.isEmpty || windowSize <= 0) return null;
    final start =
        values.length > windowSize ? values.length - windowSize : 0;
    final window = values.sublist(start);
    var sum = 0.0;
    for (final v in window) {
      sum += v;
    }
    return sum / window.length;
  }

  /// Percent change of [current] vs [baseline]: `((current - baseline) / |baseline|) * 100`.
  /// Returns `null` when [baseline] is 0 and [current] is non-zero (undefined %).
  static double? calculateDeltaPercentage(double current, double baseline) {
    if (baseline == 0) {
      if (current == 0) return 0;
      return null;
    }
    return ((current - baseline) / baseline.abs()) * 100;
  }

  /// [peak] = max over all [values]; [floor] = min over the last [windowSize].
  static ({double? peak, double? floor}) calculateRange(
    List<double> values, {
    required int windowSize,
  }) {
    if (values.isEmpty) return (peak: null, floor: null);

    var peak = values.first;
    for (final v in values) {
      if (v > peak) peak = v;
    }

    final start =
        values.length > windowSize && windowSize > 0
            ? values.length - windowSize
            : 0;
    final window = values.sublist(start);
    var floor = window.first;
    for (final v in window) {
      if (v < floor) floor = v;
    }
    return (peak: peak, floor: floor);
  }

  /// [accuracyRate] = D/(D+Y)*100; [attemptRate] = (D+Y)/totalQuestions*100.
  static ({double? accuracyRate, double? attemptRate}) calculateRatios({
    required int correct,
    required int incorrect,
    required int totalQuestions,
  }) {
    final attempted = correct + incorrect;
    final accuracyRate =
        attempted == 0 ? null : (correct / attempted) * 100.0;
    final attemptRate = totalQuestions <= 0
        ? null
        : (attempted / totalQuestions) * 100.0;
    return (accuracyRate: accuracyRate, attemptRate: attemptRate);
  }

  /// Trailing moving average aligned to each index (partial window at start).
  static List<double> movingAverageSeries(
    List<double> values,
    int windowSize,
  ) {
    if (values.isEmpty || windowSize <= 0) return const [];
    final out = <double>[];
    var sum = 0.0;
    for (var i = 0; i < values.length; i++) {
      sum += values[i];
      if (i >= windowSize) sum -= values[i - windowSize];
      final count = i + 1 < windowSize ? i + 1 : windowSize;
      out.add(sum / count);
    }
    return out;
  }

  /// One mentor-style Turkish sentence from recent ratios / subject gap.
  /// Returns `null` when there is not enough signal (caller shows sparse copy).
  static String? generateInsight({
    required int examCount,
    required double? accuracyRate,
    required double? attemptRate,
    required bool isGeneralScope,
    String? focusSubjectName,
  }) {
    if (examCount < 3) return null;

    if (accuracyRate != null && attemptRate != null) {
      if (accuracyRate >= 85 && attemptRate < 70) {
        return 'Doğruluğun yüksek ama biraz temkinlisin — emin olduğun sorularda '
            'cesaretlenip süreye daha fazla güvenmek netini yükseltebilir.';
      }
      if (accuracyRate < 70 && attemptRate >= 85) {
        return 'Çoğu soruya dokunuyorsun ama doğruluk düşüyor — şüpheli '
            'hissettiğin soruları boş bırakmak formunu koruyabilir.';
      }
      if (accuracyRate >= 85 && attemptRate >= 85) {
        return 'Doğruluk ve cevaplama oranların harika dengede — bu tempoyu '
            'korumaya devam et.';
      }
    }

    if (isGeneralScope &&
        focusSubjectName != null &&
        focusSubjectName.isNotEmpty) {
      return '$focusSubjectName dersinde potansiyeline en uzak noktadasın; '
          'önümüzdeki denemelerde buraya odaklan.';
    }

    return 'Son denemelerin istikrarlı görünüyor; 1-2 zayıf konuya odaklanarak '
        'formu bir üst seviyeye taşıyabilirsin.';
  }
}
