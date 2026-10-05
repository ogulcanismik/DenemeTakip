import 'package:deneme_takip/domain/deneme_entry.dart';
import 'package:deneme_takip/domain/exam_type.dart';
import 'package:deneme_takip/domain/net_format.dart';
import 'package:deneme_takip/state/providers.dart';
import 'package:deneme_takip/ui/theme.dart';
import 'package:deneme_takip/ui/widgets/net_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// null = Tümü (toplam net), otherwise a section id.
class AnalysisScreen extends ConsumerStatefulWidget {
  const AnalysisScreen({super.key});

  @override
  ConsumerState<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends ConsumerState<AnalysisScreen> {
  String? _sectionId;

  @override
  Widget build(BuildContext context) {
    final exam = ref.watch(activeExamProvider);
    final entriesNewestFirst = ref.watch(activeEntriesProvider);
    final settings = ref.watch(settingsProvider);
    if (exam == null) return const SizedBox.shrink();

    // Reset subject filter if exam sections changed / id no longer valid.
    if (_sectionId != null && exam.sectionById(_sectionId!) == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _sectionId = null);
      });
    }

    final oldestFirst = [...entriesNewestFirst]
      ..sort((a, b) {
        final byDate = a.date.compareTo(b.date);
        if (byDate != 0) return byDate;
        return a.id.compareTo(b.id);
      });

    final values = [
      for (final entry in oldestFirst) _netFor(entry, _sectionId),
    ];
    final metrics = _AnalysisMetrics.from(values);
    final wrongLoss = _wrongNetLoss(exam, oldestFirst, _sectionId);
    final target = _sectionId == null ? settings.targetFor(exam.id) : null;
    final sectionIndex = _sectionId == null
        ? -1
        : exam.sections.indexWhere((s) => s.id == _sectionId);
    final lineColor = sectionIndex < 0
        ? AppColors.emerald
        : sectionColor(sectionIndex);
    final chartTitle = _sectionId == null
        ? 'Toplam net trendi'
        : '${exam.sectionById(_sectionId!)?.name ?? 'Ders'} net trendi';

    return AppFrame(
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            sliver: SliverToBoxAdapter(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    FilterChip(
                      label: const Text('Tümü'),
                      selected: _sectionId == null,
                      onSelected: (_) => setState(() => _sectionId = null),
                    ),
                    for (final section in exam.sections) ...[
                      const SizedBox(width: 8),
                      FilterChip(
                        label: Text(section.name),
                        selected: _sectionId == section.id,
                        onSelected: (_) =>
                            setState(() => _sectionId = section.id),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          if (oldestFirst.isEmpty)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
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
                        'En az bir deneme kaydedince net özeti, trend ve yanlış maliyeti burada görünür.',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else ...[
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              sliver: SliverToBoxAdapter(
                child: _MetricsRow(metrics: metrics),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              sliver: SliverToBoxAdapter(
                child: SurfaceCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        chartTitle,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Eskiden yeniye',
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                      const SizedBox(height: 12),
                      NetTrendChart(
                        entries: oldestFirst,
                        values: values,
                        lineColor: lineColor,
                        target: target,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              sliver: SliverToBoxAdapter(
                child: _WrongCostCard(
                  loss: wrongLoss,
                  noPenalty: exam.penaltyDivisor == 0,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  double _netFor(DenemeEntry entry, String? sectionId) {
    if (sectionId == null) return entry.totalNet;
    for (final section in entry.sections) {
      if (section.sectionId == sectionId) return section.calculatedNet;
    }
    return 0;
  }

  /// Nets lost to wrong answers: sum(incorrect) / penaltyDivisor (0 → 0).
  double _wrongNetLoss(
    ExamType exam,
    List<DenemeEntry> entries,
    String? sectionId,
  ) {
    if (exam.penaltyDivisor == 0) return 0;
    var incorrect = 0;
    for (final entry in entries) {
      for (final section in entry.sections) {
        if (sectionId != null && section.sectionId != sectionId) continue;
        incorrect += section.incorrectCount;
      }
    }
    return incorrect / exam.penaltyDivisor;
  }
}

/// Son net değişimi = son deneme neti − önceki denemelerin ortalaması.
class _AnalysisMetrics {
  const _AnalysisMetrics({
    required this.highest,
    required this.average,
    required this.changeVsPriorAvg,
  });

  final double? highest;
  final double? average;

  /// null when fewer than 2 exams (no prior average).
  final double? changeVsPriorAvg;

  factory _AnalysisMetrics.from(List<double> values) {
    if (values.isEmpty) {
      return const _AnalysisMetrics(
        highest: null,
        average: null,
        changeVsPriorAvg: null,
      );
    }
    var max = values.first;
    var sum = 0.0;
    for (final v in values) {
      if (v > max) max = v;
      sum += v;
    }
    final avg = sum / values.length;
    double? change;
    if (values.length >= 2) {
      final prior = values.sublist(0, values.length - 1);
      final priorSum = prior.fold<double>(0, (a, b) => a + b);
      change = values.last - (priorSum / prior.length);
    }
    return _AnalysisMetrics(
      highest: max,
      average: avg,
      changeVsPriorAvg: change,
    );
  }
}

class _MetricsRow extends StatelessWidget {
  const _MetricsRow({required this.metrics});

  final _AnalysisMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final change = metrics.changeVsPriorAvg;
    final changeText = change == null
        ? '—'
        : '${change >= 0 ? '+' : ''}${formatNet(change)}';
    final changeColor = change == null
        ? AppColors.text
        : change >= 0
        ? AppColors.emerald
        : AppColors.amber;

    return Row(
      children: [
        Expanded(
          child: _MetricTile(
            label: 'En Yüksek Net',
            value: metrics.highest == null ? '—' : formatNet(metrics.highest!),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MetricTile(
            label: 'Ortalama Net',
            value: metrics.average == null ? '—' : formatNet(metrics.average!),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MetricTile(
            label: 'Son Net Değişimi',
            value: changeText,
            valueColor: changeColor,
            caption: 'son − önceki ort.',
          ),
        ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    this.valueColor,
    this.caption,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? AppColors.text,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (caption != null) ...[
            const SizedBox(height: 4),
            Text(
              caption!,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }
}

class _WrongCostCard extends StatelessWidget {
  const _WrongCostCard({required this.loss, required this.noPenalty});

  final double loss;
  final bool noPenalty;

  @override
  Widget build(BuildContext context) {
    final body = noPenalty
        ? 'Bu sınavda yanlışlar netten düşülmez.'
        : 'Yanlışların toplam ${formatNet(loss)} net kaybettirdi.';

    return SurfaceCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.amber.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.lightbulb_outline,
              color: AppColors.amber,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Yanlış Maliyeti',
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
