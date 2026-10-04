import 'package:deneme_takip/domain/deneme_entry.dart';
import 'package:deneme_takip/domain/exam_type.dart';
import 'package:deneme_takip/domain/net_format.dart';
import 'package:deneme_takip/ui/theme.dart';
import 'package:deneme_takip/ui/turkish_date.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

const _axisStyle = TextStyle(color: AppColors.textMuted, fontSize: 11);

class TotalNetChart extends StatelessWidget {
  const TotalNetChart({super.key, required this.entries, required this.target});

  final List<DenemeEntry> entries;
  final double target;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const SizedBox.shrink();

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
              color: AppColors.outline.withValues(alpha: 0.45),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          extraLinesData: ExtraLinesData(
            horizontalLines: [
              HorizontalLine(
                y: target,
                color: AppColors.indigo,
                strokeWidth: 1.6,
                dashArray: const [6, 4],
                label: HorizontalLineLabel(
                  show: true,
                  alignment: Alignment.bottomRight,
                  padding: const EdgeInsets.only(right: 6, bottom: 4),
                  style: const TextStyle(
                    color: AppColors.indigo,
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
                getTitlesWidget: (value, meta) => SideTitleWidget(
                  meta: meta,
                  child: Text(formatNet(value), style: _axisStyle),
                ),
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
                      style: _axisStyle,
                    ),
                  );
                },
              ),
            ),
          ),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (spot) => AppColors.surfaceHigh,
              getTooltipItems: (spots) {
                return [
                  for (final spot in spots)
                    LineTooltipItem(
                      formatNet(spot.y),
                      const TextStyle(
                        color: AppColors.text,
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
              color: AppColors.emerald,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: AppColors.emerald.withValues(alpha: 0.14),
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
                  color: AppColors.outline.withValues(alpha: 0.45),
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(show: false),
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  fitInsideHorizontally: true,
                  fitInsideVertically: true,
                  getTooltipColor: (group) => AppColors.surfaceHigh,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final name = rodIndex < exam.sections.length
                        ? exam.sections[rodIndex].name
                        : '';
                    return BarTooltipItem(
                      '$name\n${formatNet(rod.toY)}',
                      const TextStyle(
                        color: AppColors.text,
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
                    getTitlesWidget: (value, meta) => SideTitleWidget(
                      meta: meta,
                      child: Text(formatNet(value), style: _axisStyle),
                    ),
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
                          style: _axisStyle,
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
                      style: const TextStyle(
                        color: AppColors.textMuted,
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
