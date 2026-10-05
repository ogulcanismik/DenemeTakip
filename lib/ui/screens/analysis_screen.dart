import 'package:deneme_takip/domain/analysis_engine.dart';
import 'package:deneme_takip/domain/deneme_entry.dart';
import 'package:deneme_takip/domain/exam_type.dart';
import 'package:deneme_takip/domain/net_format.dart';
import 'package:deneme_takip/state/providers.dart';
import 'package:deneme_takip/ui/theme.dart';
import 'package:deneme_takip/ui/widgets/net_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Page 0 = Genel (toplam net); pages 1..n = exam.sections[i].
class AnalysisScreen extends ConsumerStatefulWidget {
  const AnalysisScreen({super.key});

  @override
  ConsumerState<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends ConsumerState<AnalysisScreen> {
  late final PageController _pageController;
  final ScrollController _chipScrollController = ScrollController();
  final Map<int, GlobalKey> _chipKeys = {};
  int _pageIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _chipScrollController.dispose();
    super.dispose();
  }

  GlobalKey _chipKey(int index) =>
      _chipKeys.putIfAbsent(index, GlobalKey.new);

  void _scrollSelectedChipIntoView(int index) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final context = _chipKeys[index]?.currentContext;
      if (context == null) return;
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        alignment: 0.5,
        alignmentPolicy: ScrollPositionAlignmentPolicy.explicit,
      );
    });
  }

  void _onPageIndexChanged(int page) {
    if (_pageIndex == page) return;
    setState(() => _pageIndex = page);
    _scrollSelectedChipIntoView(page);
  }

  void _goToPage(int page) {
    if (_pageIndex == page) return;
    _onPageIndexChanged(page);
    if (_pageController.hasClients) {
      _pageController.jumpToPage(page);
    }
  }

  @override
  Widget build(BuildContext context) {
    final exam = ref.watch(activeExamProvider);
    final entriesNewestFirst = ref.watch(activeEntriesProvider);
    final settings = ref.watch(settingsProvider);
    if (exam == null) return const SizedBox.shrink();

    final pageCount = 1 + exam.sections.length;
    if (_pageIndex >= pageCount) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _goToPage(0);
      });
    }

    final oldestFirst = [...entriesNewestFirst]
      ..sort((a, b) {
        final byDate = a.date.compareTo(b.date);
        if (byDate != 0) return byDate;
        return a.id.compareTo(b.id);
      });

    return AppFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.shellBodyHorizontal,
              AppSpacing.shellBodyTop,
              AppSpacing.shellBodyHorizontal,
              0,
            ),
            child: SingleChildScrollView(
              controller: _chipScrollController,
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  KeyedSubtree(
                    key: _chipKey(0),
                    child: FilterChip(
                      label: const Text('Genel'),
                      selected: _pageIndex == 0,
                      onSelected: (_) => _goToPage(0),
                    ),
                  ),
                  for (var i = 0; i < exam.sections.length; i++) ...[
                    const SizedBox(width: 8),
                    KeyedSubtree(
                      key: _chipKey(i + 1),
                      child: FilterChip(
                        label: Text(exam.sections[i].name),
                        selected: _pageIndex == i + 1,
                        onSelected: (_) => _goToPage(i + 1),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: pageCount,
              onPageChanged: _onPageIndexChanged,
              itemBuilder: (context, page) {
                final sectionId =
                    page == 0 ? null : exam.sections[page - 1].id;
                return _AnalysisPage(
                  exam: exam,
                  oldestFirst: oldestFirst,
                  sectionId: sectionId,
                  sectionIndex: page - 1,
                  target: sectionId == null
                      ? settings.targetFor(exam.id)
                      : null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalysisPage extends StatelessWidget {
  const _AnalysisPage({
    required this.exam,
    required this.oldestFirst,
    required this.sectionId,
    required this.sectionIndex,
    required this.target,
  });

  final ExamType exam;
  final List<DenemeEntry> oldestFirst;
  final String? sectionId;
  final int sectionIndex;
  final double? target;

  static const _formWindow = 5;
  static const _chartWindow = 10;
  static const _maWindow = 3;
  static const _insightExamWindow = 3;

  @override
  Widget build(BuildContext context) {
    if (oldestFirst.isEmpty) {
      return CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.shellBodyHorizontal,
              AppSpacing.shellBodyTop,
              AppSpacing.shellBodyHorizontal,
              28,
            ),
            sliver: SliverToBoxAdapter(
              child: SurfaceCard(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Analiz için deneme yok',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'En az bir deneme kaydedince form, trend ve isabet burada görünür.',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }

    final allValues = [
      for (final entry in oldestFirst) _netFor(entry, sectionId),
    ];
    final formAvg =
        AnalysisEngine.calculateRollingAverage(allValues, _formWindow);
    final latest = allValues.last;
    final deltaPct = formAvg == null
        ? null
        : AnalysisEngine.calculateDeltaPercentage(latest, formAvg);
    final range = AnalysisEngine.calculateRange(
      allValues,
      windowSize: _formWindow,
    );

    final chartStart = oldestFirst.length > _chartWindow
        ? oldestFirst.length - _chartWindow
        : 0;
    final chartEntries = oldestFirst.sublist(chartStart);
    final chartValues = allValues.sublist(chartStart);
    final trendOverlay = chartValues.length >= 2
        ? AnalysisEngine.movingAverageSeries(chartValues, _maWindow)
        : null;

    // Ratios: all exams for active exam type in selected scope.
    final counts = _aggregateCounts(exam, oldestFirst, sectionId);
    final ratios = AnalysisEngine.calculateRatios(
      correct: counts.correct,
      incorrect: counts.incorrect,
      totalQuestions: counts.totalQuestions,
    );

    final insightWindowStart = oldestFirst.length > _insightExamWindow
        ? oldestFirst.length - _insightExamWindow
        : 0;
    final insightEntries = oldestFirst.sublist(insightWindowStart);
    final insightCounts = _aggregateCounts(exam, insightEntries, sectionId);
    final insightRatios = AnalysisEngine.calculateRatios(
      correct: insightCounts.correct,
      incorrect: insightCounts.incorrect,
      totalQuestions: insightCounts.totalQuestions,
    );
    final focusSubject = sectionId == null
        ? _weakestSubjectName(exam, insightEntries)
        : null;
    final insight = AnalysisEngine.generateInsight(
      examCount: oldestFirst.length,
      accuracyRate: insightRatios.accuracyRate,
      attemptRate: insightRatios.attemptRate,
      isGeneralScope: sectionId == null,
      focusSubjectName: focusSubject,
    );

    final lineColor =
        sectionIndex < 0 ? AppColors.emerald : sectionColor(sectionIndex);
    final chartTitle = sectionId == null
        ? 'Toplam net trendi'
        : '${exam.sectionById(sectionId!)?.name ?? 'Ders'} net trendi';
    final sparse = oldestFirst.length < 3;

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.shellBodyHorizontal,
            AppSpacing.shellBodyTop,
            AppSpacing.shellBodyHorizontal,
            28,
          ),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              if (sparse) ...[
                const _SparseBanner(),
                const SizedBox(height: 12),
              ],
              _FormPerformanceCard(
                formAvg: formAvg,
                deltaPct: deltaPct,
                peak: range.peak,
                floor: range.floor,
                examCount: oldestFirst.length,
              ),
              const SizedBox(height: 12),
              SurfaceCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      chartTitle,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      chartEntries.length >= _chartWindow
                          ? 'Son $_chartWindow deneme · yumuşak çizgi $_maWindow deneme ort.'
                          : 'Eskiden yeniye · yumuşak çizgi $_maWindow deneme ort.',
                      style: const TextStyle(color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 12),
                    if (chartEntries.length < 2)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 28),
                        child: Text(
                          'Yeterli veri toplanıyor (En az 3 deneme)',
                          style: TextStyle(color: AppColors.textMuted),
                        ),
                      )
                    else
                      NetTrendChart(
                        entries: chartEntries,
                        values: chartValues,
                        lineColor: lineColor,
                        target: target,
                        trendValues: trendOverlay,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _TacticsCard(
                accuracyRate: ratios.accuracyRate,
                attemptRate: ratios.attemptRate,
              ),
              const SizedBox(height: 12),
              _InsightCard(
                insight: insight,
                sparse: sparse,
              ),
            ]),
          ),
        ),
      ],
    );
  }

  static double _netFor(DenemeEntry entry, String? sectionId) {
    if (sectionId == null) return entry.totalNet;
    for (final section in entry.sections) {
      if (section.sectionId == sectionId) return section.calculatedNet;
    }
    return 0;
  }

  static ({int correct, int incorrect, int totalQuestions}) _aggregateCounts(
    ExamType exam,
    List<DenemeEntry> entries,
    String? sectionId,
  ) {
    var correct = 0;
    var incorrect = 0;
    var totalQuestions = 0;
    for (final entry in entries) {
      for (final def in exam.sections) {
        if (sectionId != null && def.id != sectionId) continue;
        totalQuestions += def.questionCount;
        for (final section in entry.sections) {
          if (section.sectionId != def.id) continue;
          correct += section.correctCount;
          incorrect += section.incorrectCount;
        }
      }
    }
    return (
      correct: correct,
      incorrect: incorrect,
      totalQuestions: totalQuestions,
    );
  }

  /// Subject with largest gap vs potential (questionCount − avg net) over entries.
  static String? _weakestSubjectName(
    ExamType exam,
    List<DenemeEntry> entries,
  ) {
    if (entries.isEmpty || exam.sections.isEmpty) return null;
    String? worstName;
    var worstGap = double.negativeInfinity;
    for (final def in exam.sections) {
      var sum = 0.0;
      for (final entry in entries) {
        sum += _netFor(entry, def.id);
      }
      final avg = sum / entries.length;
      final gap = def.questionCount - avg;
      if (gap > worstGap) {
        worstGap = gap;
        worstName = def.name;
      }
    }
    return worstName;
  }
}

class _SparseBanner extends StatelessWidget {
  const _SparseBanner();

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: const Text(
        'Yeterli veri toplanıyor (En az 3 deneme)',
        style: TextStyle(color: AppColors.textMuted, height: 1.35),
      ),
    );
  }
}

class _FormPerformanceCard extends StatelessWidget {
  const _FormPerformanceCard({
    required this.formAvg,
    required this.deltaPct,
    required this.peak,
    required this.floor,
    required this.examCount,
  });

  final double? formAvg;
  final double? deltaPct;
  final double? peak;
  final double? floor;
  final int examCount;

  @override
  Widget build(BuildContext context) {
    final badge = _trendBadge(deltaPct);

    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Form & Performans',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Form Düzeyi',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      formAvg == null ? '—' : formatNet(formAvg!),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      examCount >= 5
                          ? 'Son 5 deneme ort.'
                          : 'Mevcut deneme ort.',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              ?badge,
            ],
          ),
          const SizedBox(height: 18),
          const Text(
            'Güvenli Net Aralığı',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _RangeTile(
                  label: 'Zirve Net',
                  value: peak == null ? '—' : formatNet(peak!),
                  caption: 'Tüm geçmiş',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _RangeTile(
                  label: 'Taban Net',
                  value: floor == null ? '—' : formatNet(floor!),
                  caption: examCount >= 5 ? 'Son 5 deneme' : 'Mevcut denemeler',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget? _trendBadge(double? delta) {
    if (delta == null) return null;
    final positive = delta >= 0;
    final color = positive ? AppColors.emerald : AppColors.amber;
    final arrow = positive ? '▲' : '▼';
    final sign = positive ? '+' : '';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$arrow $sign${delta.toStringAsFixed(1).replaceAll('.', ',')}%',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
      ),
    );
  }
}

class _RangeTile extends StatelessWidget {
  const _RangeTile({
    required this.label,
    required this.value,
    required this.caption,
  });

  final String label;
  final String value;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(
            caption,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _TacticsCard extends StatelessWidget {
  const _TacticsCard({
    required this.accuracyRate,
    required this.attemptRate,
  });

  final double? accuracyRate;
  final double? attemptRate;

  static const _accuracyBar = Color(0xFF22C55E);
  static const _attemptBar = Color(0xFF818CF8);

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Deneme Stratejin',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 14),
          _ProgressRow(
            label: 'Doğruluk Oranı',
            percent: accuracyRate,
            barColor: _accuracyBar,
            micro: _accuracyMicro(accuracyRate),
          ),
          const SizedBox(height: 16),
          _ProgressRow(
            label: 'Cevaplama Oranı',
            percent: attemptRate,
            barColor: _attemptBar,
            micro: _attemptMicro(attemptRate),
          ),
        ],
      ),
    );
  }

  static String _accuracyMicro(double? accuracy) {
    if (accuracy == null) return 'Henüz işaretlenen soru yok.';
    if (accuracy >= 90) {
      return 'Neredeyse hiç fire vermiyorsun, işaretlediğin sorular çok '
          'sağlam geliyor.';
    }
    if (accuracy >= 70) {
      final per10 = (accuracy / 10).clamp(0, 10).round();
      return 'İşaretlediğin her 10 sorudan yaklaşık '
          '${_turkishAccusativePer10(per10)} doğru.';
    }
    return 'Hata payın biraz yüksek; emin olmadığın soruları boş bırakmak '
        'formunu yükseltebilir.';
  }

  static String _attemptMicro(double? attempt) {
    if (attempt == null) return 'Soru sayısı tanımsız.';
    if (attempt >= 85) {
      return 'Soruların büyük kısmına ulaştın, boş soru sayın oldukça az.';
    }
    if (attempt >= 60) {
      final per10 = (attempt / 10).clamp(0, 10).round();
      return 'Her 10 sorudan ${_turkishDativePer10(per10)} cevap verdin; '
          'kalanlar için süre dengesini gözetebilirsin.';
    }
    return 'Soruların önemli bir kısmı boş kalmış; süre yönetimi veya soru '
        'eleme hızına odaklanabilirsin.';
  }

  /// Accusative for 0–10 (e.g. 8'i, 9'u) — avoids awkward "10'i".
  static String _turkishAccusativePer10(int n) {
    const suffixes = <int, String>{
      0: "'ı",
      1: "'i",
      2: "'yi",
      3: "'ü",
      4: "'ü",
      5: "'i",
      6: "'yı",
      7: "'yi",
      8: "'i",
      9: "'u",
      10: "'u",
    };
    return '$n${suffixes[n] ?? "'u"}';
  }

  /// Dative for 0–10 (e.g. 8'ine, 9'una).
  static String _turkishDativePer10(int n) {
    const suffixes = <int, String>{
      0: "'ına",
      1: "'ine",
      2: "'sine",
      3: "'üne",
      4: "'üne",
      5: "'ine",
      6: "'sına",
      7: "'sine",
      8: "'ine",
      9: "'una",
      10: "'una",
    };
    return '$n${suffixes[n] ?? "'una"}';
  }
}

class _ProgressRow extends StatelessWidget {
  const _ProgressRow({
    required this.label,
    required this.percent,
    required this.micro,
    required this.barColor,
  });

  final String label;
  final double? percent;
  final String micro;
  final Color barColor;

  @override
  Widget build(BuildContext context) {
    final value = percent == null ? 0.0 : (percent! / 100).clamp(0.0, 1.0);
    final labelPct = percent == null ? '—' : '%${percent!.round()}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            Text(
              labelPct,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: percent == null ? null : value,
            minHeight: 8,
            backgroundColor: AppColors.surfaceHigh,
            color: barColor,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          micro,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 12,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.insight, required this.sparse});

  final String? insight;
  final bool sparse;

  @override
  Widget build(BuildContext context) {
    final body = sparse
        ? 'Yeterli veri toplanıyor (En az 3 deneme). Birkaç deneme daha girince '
            'burada net bir teşhis çıkar.'
        : (insight ??
            'Son denemelerin istikrarlı görünüyor; 1-2 zayıf konuya odaklanarak '
                'formu bir üst seviyeye taşıyabilirsin.');

    return SurfaceCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.indigo.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.auto_awesome_outlined,
              color: AppColors.indigo,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Akıllı Teşhis Notu',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  body,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
