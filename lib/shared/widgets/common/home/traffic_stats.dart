import 'dart:async';
import 'package:astral/src/rust/api/simple.dart';
import 'package:astral/shared/widgets/common/home_box.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class TrafficStats extends StatefulWidget {
  const TrafficStats({super.key});

  @override
  State<TrafficStats> createState() => _TrafficStatsState();
}

class TrafficDataPoint {
  final DateTime timestamp;
  final BigInt rxBytes;
  final BigInt txBytes;

  TrafficDataPoint({
    required this.timestamp,
    required this.rxBytes,
    required this.txBytes,
  });
}

class _TrafficStatsState extends State<TrafficStats> {
  Timer? _refreshTimer;
  final List<TrafficDataPoint> _historyData = [];
  static const int _maxHistoryPoints = 20;
  static const int _displayPoints = 10;
  double _maxTrafficCache = 100;

  @override
  void initState() {
    super.initState();
    _historyData.add(
      TrafficDataPoint(
        timestamp: DateTime.now(),
        rxBytes: BigInt.zero,
        txBytes: BigInt.zero,
      ),
    );
    _loadTrafficData();
    _refreshTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _loadTrafficData();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadTrafficData() async {
    try {
      final status = await getNetworkStatus();
      if (mounted) {
        final (totalRx, totalTx) = _calculateTotalTrafficFromStatus(status);

        _historyData.add(
          TrafficDataPoint(
            timestamp: DateTime.now(),
            rxBytes: totalRx,
            txBytes: totalTx,
          ),
        );

        if (_historyData.length > _maxHistoryPoints) {
          _historyData.removeAt(0);
        }

        final currentMax = _getMaxTraffic();
        final currentMin = _getMinTraffic();
        final dataRange = currentMax - currentMin;
        final totalRange = dataRange / 0.6;
        final minY = currentMin - totalRange * 0.1;
        final maxY = currentMax + totalRange * 0.3;

        if (maxY > _maxTrafficCache || minY < 0) {
          _maxTrafficCache = maxY > 0 ? maxY : 100;
        }

        setState(() {});
      }
    } catch (_) {}
  }

  double _getMinTraffic() {
    if (_historyData.isEmpty) return 0;

    double minTotal = double.infinity;

    for (var data in _historyData) {
      final total = (data.rxBytes + data.txBytes).toDouble();
      if (total < minTotal) minTotal = total;
    }

    return minTotal == double.infinity ? 0 : minTotal;
  }

  (BigInt, BigInt) _calculateTotalTrafficFromStatus(KVNetworkStatus status) {
    BigInt totalRx = BigInt.zero;
    BigInt totalTx = BigInt.zero;

    for (var node in status.nodes) {
      totalRx += node.rxBytes;
      totalTx += node.txBytes;
    }

    return (totalRx, totalTx);
  }

  @override
  Widget build(BuildContext context) {
    var colorScheme = Theme.of(context).colorScheme;

    final displayData =
        _historyData.length > _displayPoints
            ? _historyData.sublist(_historyData.length - _displayPoints)
            : _historyData;

    return HomeBox(
      widthSpan: 2,
      fixedCellHeight: 180,
      isBorder: false,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
            child: SizedBox(
              width: constraints.maxWidth - 24,
              height: constraints.maxHeight - 32,
              child: LineChart(
                LineChartData(
                  backgroundColor: Colors.transparent,
                  gridData: FlGridData(show: false),
                  titlesData: FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  minX: 0,
                  maxX: (displayData.length - 1).toDouble(),
                  minY: 0,
                  maxY: _maxTrafficCache,
                  lineTouchData: LineTouchData(enabled: false),
                  clipData: FlClipData.all(),
                  baselineY: 0,
                  extraLinesData: ExtraLinesData(
                    horizontalLines: [
                      HorizontalLine(
                        y: 0,
                        color: Colors.transparent,
                        strokeWidth: 0,
                      ),
                    ],
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots:
                          displayData.asMap().entries.map((entry) {
                            return FlSpot(
                              entry.key.toDouble(),
                              (entry.value.rxBytes + entry.value.txBytes)
                                  .toDouble(),
                            );
                          }).toList(),
                      isCurved: true,
                      color: colorScheme.primary,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            colorScheme.primary.withValues(alpha: 0.3),
                            colorScheme.primary.withValues(alpha: 0.0),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                      preventCurveOverShooting: true,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  double _getMaxTraffic() {
    if (_historyData.isEmpty) return 0;

    double maxRx = 0;
    double maxTx = 0;

    for (var data in _historyData) {
      final rx = data.rxBytes.toDouble();
      final tx = data.txBytes.toDouble();
      if (rx > maxRx) maxRx = rx;
      if (tx > maxTx) maxTx = tx;
    }

    return maxRx > maxTx ? maxRx : maxTx;
  }
}
