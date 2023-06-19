//
// Time ranges: 1 min, 5 min, 15 min, 30 min, 1h, 3h
//

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/node.dart';
import '../theme.dart';

class LiveChart extends StatelessWidget {
  final NodeModel node;
  final startTime = DateTime.now().millisecondsSinceEpoch;

  final List<Color> gradientColors = [
    primaryColor,
    secondaryColor,
  ];

  LiveChart({super.key, required this.node});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        AspectRatio(
          aspectRatio: 1.70,
          child: Padding(
            padding: const EdgeInsets.only(
              right: 18,
              left: 12,
              top: 24,
              bottom: 12,
            ),
            child: LineChart(mainData()),
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: node.timeseries.keys
              .map((name) => FilterChip(
                    label: Text(name),
                    selected: node.selectedSeries.contains(name),
                    onSelected: (bool selected) {
                      if (selected) {
                        node.selectedSeries.add(name);
                      } else {
                        node.selectedSeries.remove(name);
                      }
                    },
                    showCheckmark: false,
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget bottomTitleWidgets(double value, TitleMeta meta) {
    Widget text;
    var time = DateTime.fromMillisecondsSinceEpoch(
        ((node.startTime + value) * 1000).toInt());

    if (value.toInt().toDouble() == value.toDouble()) {
      text = Text(
          '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}');
    } else {
      text = Container();
    }
    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: text,
    );
  }

  LineChartData mainData() {
    return LineChartData(
      lineTouchData: LineTouchData(enabled: false),
      gridData: FlGridData(
        show: false,
        drawVerticalLine: false,
        horizontalInterval: 1,
        verticalInterval: 1,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: Colors.grey,
            strokeWidth: 1,
          );
        },
        getDrawingVerticalLine: (value) {
          return FlLine(
            color: Colors.grey,
            strokeWidth: 1,
          );
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: 60,
            getTitlesWidget: bottomTitleWidgets,
          ),
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border.all(color: const Color(0xff37434d)),
      ),
      lineBarsData: [
        for (final series in node.selectedSeries)
          LineChartBarData(
            spots: node.timeseries[series],
            isCurved: true,
            gradient: LinearGradient(
              colors: gradientColors,
            ),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: false,
            ),
          ),
      ],
    );
  }
}
