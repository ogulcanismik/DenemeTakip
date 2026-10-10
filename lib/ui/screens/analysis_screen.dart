import 'package:deneme_takip/domain/analysis_engine.dart';
import 'package:deneme_takip/domain/deneme_entry.dart';
import 'package:deneme_takip/domain/exam_type.dart';
import 'package:deneme_takip/domain/net_format.dart';
import 'package:deneme_takip/state/providers.dart';
import 'package:deneme_takip/ui/screens/detail_screen.dart';
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

  GlobalKey _chipKey(int index) => _chipKeys.putIfAbsent(index, GlobalKey.new);

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
              12,
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
                final sectionId = page == 0 ? null : exam.sections[page - 1].id;
                return _AnalysisPage(
                  exam: exam,
                  oldestFirst: oldestFirst,
                  sectionId: sectionId,
                  sectionIndex: page - 1,
                  target: sectionId == null
                      ? settings.targetFor(exam.id)
                      : null,
                  onGoToPage: _goToPage,
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
    required this.onGoToPage,
  });

  final ExamType exam;
  final List<DenemeEntry> oldestFirst;
  final String? sectionId;
  final int sectionIndex;
  final double? target;
  final ValueChanged<int> onGoToPage;

  static const _formWindow = 5;
  static const _chartWindow = 10;
  static const _maWindow = 3;

  @override
  Widget build(BuildContext context) {
    if (oldestFirst.isEmpty) {
      return CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.shellBodyHorizontal,
              0,
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
                      'Henüz deneme yok',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'İlk denemeni gir ve performansını analiz etmeye başla!',
                      style: TextStyle(
                        color: AppColors.of(context).textMuted,
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
    // Newest-first for recency weights (form average / vs-average delta).
    final formAvg = AnalysisEngine.calculateRecencyWeightedAverage(
      allValues.reversed.toList(),
    );
    final latest = allValues.last;
    final deltaPct = formAvg == null
        ? null
        : AnalysisEngine.calculateDeltaPercentage(latest, formAvg);
    final range = AnalysisEngine.calculateRange(
      allValues,
      windowSize: _formWindow,
    );
    final peakEntryId = _extremumEntryId(
      oldestFirst,
      sectionId,
      maximize: true,
    );
    final floorEntryId = _extremumEntryId(
      oldestFirst.length > _formWindow
          ? oldestFirst.sublist(oldestFirst.length - _formWindow)
          : oldestFirst,
      sectionId,
      maximize: false,
    );

    final chartStart = oldestFirst.length > _chartWindow
        ? oldestFirst.length - _chartWindow
        : 0;
    final chartEntries = oldestFirst.sublist(chartStart);
    final chartValues = allValues.sublist(chartStart);
    final trendOverlay = chartValues.length >= 2
        ? AnalysisEngine.movingAverageSeries(chartValues, _maWindow)
        : null;

    // Newest-first D / Y / boş counts for recency-weighted averages.
    final newestFirst = oldestFirst.reversed.toList();
    final correctSeries = <double>[];
    final incorrectSeries = <double>[];
    final emptySeries = <double>[];
    for (final entry in newestFirst) {
      final c = _countsForEntry(exam, entry, sectionId);
      correctSeries.add(c.correct.toDouble());
      incorrectSeries.add(c.incorrect.toDouble());
      emptySeries.add(c.empty.toDouble());
    }
    final weightedCounts = AnalysisEngine.calculateWeightedCountAverages(
      correctNewestFirst: correctSeries,
      incorrectNewestFirst: incorrectSeries,
      emptyNewestFirst: emptySeries,
    );

    final lineColor = sectionIndex < 0
        ? AppColors.of(context).emerald
        : sectionColor(sectionIndex);
    final chartTitle = sectionId == null
        ? 'Toplam net trendi'
        : '${exam.sectionById(sectionId!)?.name ?? 'Ders'} net trendi';
    final sparse = oldestFirst.length < 3;

    final studyRanking = sectionId == null
        ? _studyNeededRanking(exam, newestFirst)
        : const <({int sectionPage, String name})>[];

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.shellBodyHorizontal,
            0,
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
                peakEntryId: peakEntryId,
                floorEntryId: floorEntryId,
                weightedCorrect: weightedCounts.correct,
                weightedEmpty: weightedCounts.empty,
                weightedIncorrect: weightedCounts.incorrect,
              ),
              if (studyRanking.isNotEmpty) ...[
                const SizedBox(height: 16),
                _StudyNeededCard(
                  items: studyRanking,
                  onSubjectTap: onGoToPage,
                ),
              ],
              const SizedBox(height: 16),
              SurfaceCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      chartTitle,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    if (chartEntries.length < 2)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 28),
                        child: Text(
                          'Yeterli veri toplanıyor (En az 3 deneme)',
                          style: TextStyle(
                            color: AppColors.of(context).textMuted,
                          ),
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
            ]),
          ),
        ),
      ],
    );
  }

  /// Subjects ordered worst → best by (recency-weighted avg net) / questionCount.
  static List<({int sectionPage, String name})> _studyNeededRanking(
    ExamType exam,
    List<DenemeEntry> newestFirst,
  ) {
    final scored = <({int sectionPage, String name, double score})>[];
    for (var i = 0; i < exam.sections.length; i++) {
      final def = exam.sections[i];
      if (def.questionCount <= 0) continue;
      final nets = [
        for (final entry in newestFirst) _netFor(entry, def.id),
      ];
      final weighted = AnalysisEngine.calculateRecencyWeightedAverage(nets);
      if (weighted == null) continue;
      scored.add((
        sectionPage: i + 1,
        name: def.name,
        score: weighted / def.questionCount,
      ));
    }
    scored.sort((a, b) {
      final byScore = a.score.compareTo(b.score);
      if (byScore != 0) return byScore;
      return a.sectionPage.compareTo(b.sectionPage);
    });
    return [
      for (final item in scored)
        (sectionPage: item.sectionPage, name: item.name),
    ];
  }

  static double _netFor(DenemeEntry entry, String? sectionId) {
    if (sectionId == null) return entry.totalNet;
    for (final section in entry.sections) {
      if (section.sectionId == sectionId) return section.calculatedNet;
    }
    return 0;
  }

  /// First extremum in [entries] (chronological). Peak = max; taban window = min.
  static String? _extremumEntryId(
    List<DenemeEntry> entries,
    String? sectionId, {
    required bool maximize,
  }) {
    if (entries.isEmpty) return null;
    var bestId = entries.first.id;
    var bestNet = _netFor(entries.first, sectionId);
    for (var i = 1; i < entries.length; i++) {
      final net = _netFor(entries[i], sectionId);
      final better = maximize ? net > bestNet : net < bestNet;
      if (better) {
        bestNet = net;
        bestId = entries[i].id;
      }
    }
    return bestId;
  }

  /// Per-deneme D / Y / boş in selected scope. Empty = questionCount − D − Y.
  static ({int correct, int incorrect, int empty}) _countsForEntry(
    ExamType exam,
    DenemeEntry entry,
    String? sectionId,
  ) {
    var correct = 0;
    var incorrect = 0;
    var empty = 0;
    for (final def in exam.sections) {
      if (sectionId != null && def.id != sectionId) continue;
      var found = false;
      for (final section in entry.sections) {
        if (section.sectionId != def.id) continue;
        correct += section.correctCount;
        incorrect += section.incorrectCount;
        empty += section.emptyCount;
        found = true;
        break;
      }
      if (!found) empty += def.questionCount;
    }
    return (correct: correct, incorrect: incorrect, empty: empty);
  }
}

class _SparseBanner extends StatelessWidget {
  const _SparseBanner();

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Text(
        'Yeterli veri toplanıyor (En az 3 deneme)',
        style: TextStyle(color: AppColors.of(context).textMuted, height: 1.35),
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
    required this.peakEntryId,
    required this.floorEntryId,
    required this.weightedCorrect,
    required this.weightedEmpty,
    required this.weightedIncorrect,
  });

  final double? formAvg;
  final double? deltaPct;
  final double? peak;
  final double? floor;
  final String? peakEntryId;
  final String? floorEntryId;
  final double? weightedCorrect;
  final double? weightedEmpty;
  final double? weightedIncorrect;

  /// Soft muted coral — not bright alarm red.
  static const _incorrectCoral = Color(0xFFD4847A);

  static String _formatAvg(double? weighted) {
    if (weighted == null) return '—';
    return formatNet(weighted);
  }

  @override
  Widget build(BuildContext context) {
    final badge = _trendBadge(context, deltaPct);
    final colors = AppColors.of(context);

    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Form & Performans',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  formAvg == null ? '—' : formatNet(formAvg!),
                  style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w800,
                    height: 1.05,
                    letterSpacing: -0.5,
                  ).data,
                ),
              ),
              ?badge,
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _DeltaStyleChip(
                  text: _formatAvg(weightedCorrect),
                  color: colors.emerald,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _DeltaStyleChip(
                  text: _formatAvg(weightedEmpty),
                  color: colors.textMuted,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _DeltaStyleChip(
                  text: _formatAvg(weightedIncorrect),
                  color: _incorrectCoral,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Divider(
            height: 1,
            thickness: 1,
            color: colors.outline.withValues(alpha: 0.55),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _RangeTile(
                  label: 'Zirve Net',
                  value: peak == null ? '—' : formatNet(peak!),
                  onTap: peakEntryId == null
                      ? null
                      : () => _openEntryDetail(context, peakEntryId!),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _RangeTile(
                  label: 'Taban Net',
                  value: floor == null ? '—' : formatNet(floor!),
                  onTap: floorEntryId == null
                      ? null
                      : () => _openEntryDetail(context, floorEntryId!),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static void _openEntryDetail(BuildContext context, String entryId) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => DetailScreen(entryId: entryId),
      ),
    );
  }

  Widget? _trendBadge(BuildContext context, double? delta) {
    if (delta == null) return null;
    final positive = delta >= 0;
    final color = positive
        ? AppColors.of(context).emerald
        : AppColors.of(context).amber;
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
        ).data,
      ),
    );
  }
}

class _RangeTile extends StatelessWidget {
  const _RangeTile({
    required this.label,
    required this.value,
    this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback? onTap;

  static final _splash = Colors.white.withValues(alpha: 0.28);
  static final _highlight = Colors.white.withValues(alpha: 0.12);

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final radius = BorderRadius.circular(10);
    return Material(
      color: colors.surfaceHigh.withValues(alpha: 0.55),
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        splashColor: _splash,
        highlightColor: _highlight,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: colors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ).data,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: 20,
                color: colors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Matches Form trend badge: soft tinted pill, bold numeric.
class _DeltaStyleChip extends StatelessWidget {
  const _DeltaStyleChip({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 16,
        ).data,
      ),
    );
  }
}

class _StudyNeededCard extends StatelessWidget {
  const _StudyNeededCard({
    required this.items,
    required this.onSubjectTap,
  });

  final List<({int sectionPage, String name})> items;
  final ValueChanged<int> onSubjectTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Çalışman Gerekenler',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Dersler, göreli zayıftan güçlüye',
            style: TextStyle(
              color: colors.textMuted,
              fontSize: 12,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          Column(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0) const SizedBox(height: 8),
                Material(
                  color: colors.surfaceHigh.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    onTap: () => onSubjectTap(items[i].sectionPage),
                    borderRadius: BorderRadius.circular(10),
                    splashColor: Colors.white.withValues(alpha: 0.28),
                    highlightColor: Colors.white.withValues(alpha: 0.12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              items[i].name,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.chevron_right,
                            size: 20,
                            color: colors.textMuted,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
