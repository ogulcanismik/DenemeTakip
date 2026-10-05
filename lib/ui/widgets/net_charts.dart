import 'package:deneme_takip/domain/deneme_entry.dart';
import 'package:deneme_takip/domain/exam_type.dart';
import 'package:deneme_takip/domain/net_format.dart';
import 'package:deneme_takip/ui/theme.dart';
import 'package:deneme_takip/ui/turkish_date.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

TextStyle _axisStyle(Color muted) =>
    TextStyle(color: muted, fontSize: 11);

/// Hide the padded axis max when it is not a clean interval tick (e.g. 116,69).
Widget _leftAxisTitle(double value, TitleMeta meta, TextStyle style) {
  final atMax = (value - meta.max).abs() < 1e-6;
  if (atMax) {
    final interval = meta.appliedInterval;
    if (interval > 0) {
      final stepsFromMin = (value - meta.min) / interval;
      if ((stepsFromMin - stepsFromMin.round()).abs() > 1e-6) {
        return const SizedBox.shrink();
      }
    }
  }
  return SideTitleWidget(
    meta: meta,
    child: Text(formatNet(value), style: style),
  );
}

class TotalNetChart extends StatelessWidget {
  const TotalNetChart({super.key, required this.entries, required this.target});

  final List<DenemeEntry> entries;
  final double target;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const SizedBox.shrink();

    final axisStyle = _axisStyle(AppColors.of(context).textMuted);
    var maxValue = target;
    var minValue = 0.0;
    for (final entry in entries) {
      if (entry.totalNet > maxValue) maxValue = entry.totalNet;
      if (entry.totalNet < minValue) minValue = entry.totalNet;
    }
    final span = (maxValue - minValue).abs();
    final maxY = maxValue + span * 0.18 + 4;
    final minY = minValue < 0 ? minValue - span * 0.08 - 2 : 0.0;

    return SizedBox(
      height: 240,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: entries.length + 1,
          minY: minY,
          maxY: maxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => FlLine(
              color: AppColors.of(context).outline.withValues(alpha: 0.45),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          extraLinesData: ExtraLinesData(
            horizontalLines: [
              HorizontalLine(
                y: target,
                color: AppColors.of(context).indigo,
                strokeWidth: 1.6,
                dashArray: const [6, 4],
                label: HorizontalLineLabel(
                  show: true,
                  alignment: Alignment.bottomRight,
                  padding: const EdgeInsets.only(right: 6, bottom: 4),
                  style: TextStyle(
                    color: AppColors.of(context).indigo,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                  labelResolver: (line) => 'Hedef ${formatNet(line.y)}',
                ),
              ),
            ],
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 42,
                getTitlesWidget: (value, meta) => _leftAxisTitle(value, meta, axisStyle),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                reservedSize: 32,
                getTitlesWidget: (value, meta) {
                  final index = value.round() - 1;
                  if ((value - value.round()).abs() > 0.01 ||
                      index < 0 ||
                      index >= entries.length) {
                    return const SizedBox.shrink();
                  }
                  return SideTitleWidget(
                    meta: meta,
                    child: Text(
                      formatShortDate(entries[index].date),
                      style: axisStyle,
                    ),
                  );
                },
              ),
            ),
          ),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (spot) => AppColors.of(context).surfaceHigh,
              getTooltipItems: (spots) {
                return [
                  for (final spot in spots)
                    LineTooltipItem(
                      formatNet(spot.y),
                      TextStyle(
                        color: AppColors.of(context).text,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                ];
              },
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: [
                for (var i = 0; i < entries.length; i++)
                  FlSpot((i + 1).toDouble(), entries[i].totalNet),
              ],
              color: AppColors.of(context).emerald,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: AppColors.of(context).emerald.withValues(alpha: 0.14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SectionNetChart extends StatelessWidget {
  const SectionNetChart({super.key, required this.exam, required this.entries});

  final ExamType exam;
  final List<DenemeEntry> entries;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const SizedBox.shrink();

    final recent = entries.length <= 5
        ? entries
        : entries.sublist(entries.length - 5);

    var maxValue = 1.0;
    var minValue = 0.0;
    for (final entry in recent) {
      for (final section in entry.sections) {
        if (section.calculatedNet > maxValue) maxValue = section.calculatedNet;
        if (section.calculatedNet < minValue) minValue = section.calculatedNet;
      }
    }
    final maxY = maxValue * 1.2 + 1;
    final minY = minValue < 0 ? minValue * 1.2 : 0.0;
    final rodWidth = exam.sections.length > 4 ? 8.0 : 12.0;
    final axisStyle = _axisStyle(AppColors.of(context).textMuted);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 240,
          child: BarChart(
            BarChartData(
              minY: minY,
              maxY: maxY,
              alignment: BarChartAlignment.spaceEvenly,
              groupsSpace: 18,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: AppColors.of(context).outline.withValues(alpha: 0.45),
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(show: false),
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  fitInsideHorizontally: true,
                  fitInsideVertically: true,
                  getTooltipColor: (group) => AppColors.of(context).surfaceHigh,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final name = rodIndex < exam.sections.length
                        ? exam.sections[rodIndex].name
                        : '';
                    return BarTooltipItem(
                      '$name\n${formatNet(rod.toY)}',
                      TextStyle(
                        color: AppColors.of(context).text,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 36,
                    getTitlesWidget: (value, meta) => _leftAxisTitle(value, meta, axisStyle),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 32,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= recent.length) {
                        return const SizedBox.shrink();
                      }
                      return SideTitleWidget(
                        meta: meta,
                        child: Text(
                          formatShortDate(recent[index].date),
                          style: axisStyle,
                        ),
                      );
                    },
                  ),
                ),
              ),
              barGroups: [
                for (var i = 0; i < recent.length; i++)
                  BarChartGroupData(
                    x: i,
                    barsSpace: 3,
                    barRods: [
                      for (var s = 0; s < exam.sections.length; s++)
                        BarChartRodData(
                          toY: _netFor(recent[i], exam.sections[s].id),
                          color: sectionColor(s),
                          width: rodWidth,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(3),
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            for (var i = 0; i < exam.sections.length; i++)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: sectionColor(i),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 6),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 220),
                    child: Text(
                      exam.sections[i].name,
                      style: TextStyle(
                        color: AppColors.of(context).textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }

  double _netFor(DenemeEntry entry, String sectionId) {
    for (final section in entry.sections) {
      if (section.sectionId == sectionId) return section.calculatedNet;
    }
    return 0;
  }
}

/// Line chart of one series (total or a single subject) over exams oldest→newest.
class NetTrendChart extends StatelessWidget {
  const NetTrendChart({
    super.key,
    required this.entries,
    required this.values,
    this.lineColor,
    this.target,
    this.trendValues,
  });

  final List<DenemeEntry> entries;
  final List<double> values;
  final Color? lineColor;
  final double? target;

  /// Optional smoothed overlay (e.g. 3–5 exam moving average), same length.
  final List<double>? trendValues;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty || values.length != entries.length) {
      return const SizedBox.shrink();
    }
    final colors = AppColors.of(context);
    final resolvedLine = lineColor ?? colors.emerald;
    final axisStyle = _axisStyle(colors.textMuted);
    final trend = trendValues;
    final hasTrend =
        trend != null && trend.length == values.length && trend.isNotEmpty;

    var maxValue = target ?? values.first;
    var minValue = 0.0;
    for (final value in values) {
      if (value > maxValue) maxValue = value;
      if (value < minValue) minValue = value;
    }
    if (hasTrend) {
      for (final value in trend) {
        if (value > maxValue) maxValue = value;
        if (value < minValue) minValue = value;
      }
    }
    if (target != null && target! > maxValue) maxValue = target!;
    final span = (maxValue - minValue).abs();
    final maxY = maxValue + span * 0.18 + 4;
    final minY = minValue < 0 ? minValue - span * 0.08 - 2 : 0.0;

    return SizedBox(
      height: 240,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: entries.length + 1,
          minY: minY,
          maxY: maxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => FlLine(
              color: AppColors.of(context).outline.withValues(alpha: 0.45),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          extraLinesData: target == null
              ? null
              : ExtraLinesData(
                  horizontalLines: [
                    HorizontalLine(
                      y: target!,
                      color: AppColors.of(context).indigo,
                      strokeWidth: 1.6,
                      dashArray: const [6, 4],
                      label: HorizontalLineLabel(
                        show: true,
                        alignment: Alignment.bottomRight,
                        padding: const EdgeInsets.only(right: 6, bottom: 4),
                        style: TextStyle(
                          color: AppColors.of(context).indigo,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                        labelResolver: (line) => 'Hedef ${formatNet(line.y)}',
                      ),
                    ),
                  ],
                ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 42,
                getTitlesWidget: (value, meta) => _leftAxisTitle(value, meta, axisStyle),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                reservedSize: 32,
                getTitlesWidget: (value, meta) {
                  final index = value.round() - 1;
                  if ((value - value.round()).abs() > 0.01 ||
                      index < 0 ||
                      index >= entries.length) {
                    return const SizedBox.shrink();
                  }
                  return SideTitleWidget(
                    meta: meta,
                    child: Text(
                      formatShortDate(entries[index].date),
                      style: axisStyle,
                    ),
                  );
                },
              ),
            ),
          ),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (spot) => AppColors.of(context).surfaceHigh,
              getTooltipItems: (spots) {
                return [
                  for (final spot in spots)
                    LineTooltipItem(
                      formatNet(spot.y),
                      TextStyle(
                        color: AppColors.of(context).text,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                ];
              },
            ),
          ),
          lineBarsData: [
            if (hasTrend)
              LineChartBarData(
                spots: [
                  for (var i = 0; i < trend.length; i++)
                    FlSpot((i + 1).toDouble(), trend[i]),
                ],
                color: resolvedLine.withValues(alpha: 0.35),
                barWidth: 3.5,
                isStrokeCapRound: true,
                isCurved: true,
                curveSmoothness: 0.28,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(show: false),
              ),
            LineChartBarData(
              spots: [
                for (var i = 0; i < values.length; i++)
                  FlSpot((i + 1).toDouble(), values[i]),
              ],
              color: resolvedLine,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: resolvedLine.withValues(alpha: 0.14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
