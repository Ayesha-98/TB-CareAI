import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:tbcare_main/core/app_constants.dart';

class Chart extends StatelessWidget {
  final Map<int, int> weeklyData;

  const Chart({super.key, required this.weeklyData});

  @override
  Widget build(BuildContext context) {
    // Determine max Y for scale, default to 5 if empty
    int maxY = 5;
    if (weeklyData.isNotEmpty) {
      final maxVal = weeklyData.values.reduce((a, b) => a > b ? a : b);
      if (maxVal > maxY) maxY = maxVal + 1;
    }

    return Container(
      padding: const EdgeInsets.all(defaultPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.all(Radius.circular(10)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Weekly Diagnoses",
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: defaultPadding),
          SizedBox(
            height: 220,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY.toDouble(),
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    tooltipBgColor: Colors.blueGrey,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        rod.toY.toInt().toString(),
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: maxY > 10 ? 5 : 1, // Dynamic interval
                      getTitlesWidget: (value, meta) {
                        if (value % 1 != 0) return const SizedBox(); // Only integers
                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        final now = DateTime.now();
                        final date = now.subtract(Duration(days: 6 - value.toInt()));
                        const days = ['S', 'M', 'T', 'W', 'T', 'F', 'S']; // Sunday starts at index 0 in some conventions, but DateTime.weekday uses 1-7
                        
                        // DateTime.weekday: 1 = Monday, 7 = Sunday
                        final weekday = date.weekday;
                        final dayLabels = ['', 'M', 'T', 'W', 'T', 'F', 'S', 'S'];
                        final label = dayLabels[weekday];

                        if (value.toInt() >= 0 && value.toInt() < 7) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              label,
                              style: const TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                            ),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.grey[200]!,
                    strokeWidth: 1,
                  ),
                ),
                barGroups: List.generate(7, (index) {
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: (weeklyData[index] ?? 0).toDouble(),
                        color: primaryColor,
                        width: 16,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: maxY.toDouble(),
                          color: Colors.grey[100],
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
