// Copyright (c) The ThingSet Project Contributors
// SPDX-License-Identifier: Apache-2.0
//
// ToDo: Time ranges 1 min, 5 min, 15 min, 30 min, 1h, 3h
//

import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/node.dart';
import '../theme.dart';

const colors = [
  Color(0xff005e83),
  Color(0xff00a072),
  Color(0xfff7b500),
  Color(0xffe06f00),
  Color(0xffbb1f11),
  Color(0xff883e8d),
];

class LiveChart extends StatelessWidget {
  final NodeModel node;
  final startTime = DateTime.now().millisecondsSinceEpoch;

  final List<Color> gradientColors = [
    primaryColor,
    secondaryColor,
  ];

  LiveChart({super.key, required this.node});

  Color _getChipColor(String name) {
    if (node.selectedSeries.contains(name)) {
      return colors[node.selectedSeries.indexOf(name) % colors.length];
    } else {
      return Colors.grey;
    }
  }

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
                    selectedColor: _getChipColor(name),
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

  // calculation inspired by the following StackOverflow post:
  // https://stackoverflow.com/questions/326679/choosing-an-attractive-linear-scale-for-a-graphs-y-axis
  (double, double) calcAxisScale() {
    double max = double.negativeInfinity;
    double min = double.infinity;
    for (final selected in node.selectedSeries) {
      var series = node.timeseries[selected]!;
      var seriesMax =
          series.reduce((curr, next) => curr.y > next.y ? curr : next).y;
      if (seriesMax > max) {
        max = seriesMax;
      }
      var seriesMin =
          series.reduce((curr, next) => curr.y < next.y ? curr : next).y;
      if (seriesMin < min) {
        min = seriesMin;
      }
    }

    const tickCount = 6;
    double range = max - min;
    double tickDistance = range / (tickCount - 1);
    double x = (log(10) / log(tickDistance) - 1).ceilToDouble();
    double pow10x = pow(10, x) as double;
    double roundedTickRange = ((tickDistance / pow10x) * pow10x).ceilToDouble();

    max = (max / roundedTickRange).ceilToDouble() * roundedTickRange;
    min = (min / roundedTickRange).floorToDouble() * roundedTickRange;

    return (max, min);
  }

  LineChartData mainData() {
    return LineChartData(
      lineTouchData: const LineTouchData(enabled: false),
      gridData: FlGridData(
        show: false,
        drawVerticalLine: false,
        horizontalInterval: 1,
        verticalInterval: 1,
        getDrawingHorizontalLine: (value) {
          return const FlLine(
            color: Colors.grey,
            strokeWidth: 1,
          );
        },
        getDrawingVerticalLine: (value) {
          return const FlLine(
            color: Colors.grey,
            strokeWidth: 1,
          );
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(
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
            spots: node.timeseries[series]!,
            isCurved: true,
            preventCurveOverShooting: true,
            color: colors[node.selectedSeries.indexOf(series) % colors.length],
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(
              show: false,
            ),
          ),
      ],
      maxY: calcAxisScale().$1,
      minY: calcAxisScale().$2,
    );
  }
}
