import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/ctos_colors.dart';

class TrafficSparkline extends StatelessWidget {
  final List<double> data;
  final Color color;
  final double height;

  const TrafficSparkline({
    super.key,
    required this.data,
    this.color = CtosColors.cyan,
    this.height = 80,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return SizedBox(height: height);

    final spots = data.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value);
    }).toList();

    final maxY = data.reduce((a, b) => a > b ? a : b) * 1.2;

    return SizedBox(
      height: height,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: (data.length - 1).toDouble(),
          minY: 0,
          maxY: maxY,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.4,
              color: color,
              barWidth: 1.5,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    color.withOpacity(0.3),
                    color.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Full traffic chart with axes
class TrafficChart extends StatelessWidget {
  final List<double> data;
  final String unit;

  const TrafficChart({
    super.key,
    required this.data,
    this.unit = 'kbps',
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox(height: 160);

    final spots = data.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value);
    }).toList();

    final maxY = data.reduce((a, b) => a > b ? a : b) * 1.25;

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY / 4,
          getDrawingHorizontalLine: (val) => FlLine(
            color: CtosColors.gridLine,
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 46,
              getTitlesWidget: (val, _) => Text(
                val >= 1000
                    ? '${(val / 1000).toStringAsFixed(1)}M'
                    : '${val.toInt()}K',
                style: const TextStyle(
                  fontFamily: 'ShareTechMono',
                  fontSize: 9,
                  color: CtosColors.textMuted,
                ),
              ),
            ),
          ),
          rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          bottomTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(
          show: true,
          border: const Border(
            left: BorderSide(color: CtosColors.gridLine),
            bottom: BorderSide(color: CtosColors.gridLine),
          ),
        ),
        minX: 0,
        maxX: (data.length - 1).toDouble(),
        minY: 0,
        maxY: maxY,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.3,
            color: CtosColors.cyan,
            barWidth: 1.5,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  CtosColors.cyan.withOpacity(0.25),
                  CtosColors.cyan.withOpacity(0.0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
