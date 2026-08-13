import 'package:astral/features/rooms/widgets/room_network_stats.dart';
import 'package:astral/src/rust/api/simple.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('summarizes non-local mesh peers with median route health', () {
    final stats = RoomNetworkStats.fromNetwork([
      _node(1, 'Local', '10.1.0.1', 0),
      _node(2, 'Direct A', '10.1.0.2', 1, latency: 10, loss: 0),
      _node(3, 'Direct B', '10.1.0.3', 1, latency: 30, loss: 2),
      _node(4, 'Forwarded', '10.1.0.4', 2, latency: 20, loss: 1),
      _node(5, 'No latency', '10.1.0.5', 2, latency: 0, loss: 3),
      _node(6, 'PublicServer_Relay', '0.0.0.0', 1, latency: 100, loss: 99),
    ], localIp: '10.1.0.1');

    expect(stats.peerCount, 4);
    expect(stats.directPeerCount, 2);
    expect(stats.forwardedPeerCount, 2);
    expect(stats.medianLatencyMs, 20);
    expect(stats.medianRecentLoss, 1.5);
  });

  test('reports unavailable health when there are no peer samples', () {
    final stats = RoomNetworkStats.fromNetwork([
      _node(1, 'Local', '10.1.0.1', 0),
    ], localIp: '10.1.0.1');

    expect(stats.peerCount, 0);
    expect(stats.medianLatencyMs, isNull);
    expect(stats.medianRecentLoss, isNull);
  });

  for (final size in [const Size(1200, 850), const Size(390, 844)]) {
    testWidgets('metric cells fit at $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.topCenter,
              child: RoomNetworkStatsPanel(
                stats: RoomNetworkStats(
                  peerCount: 12,
                  directPeerCount: 8,
                  forwardedPeerCount: 4,
                  medianLatencyMs: 24,
                  medianRecentLoss: 0,
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byKey(const ValueKey('room_stats_peers')), findsOneWidget);
      expect(find.byKey(const ValueKey('room_stats_latency')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('room_stats_recent_loss')),
        findsOneWidget,
      );
      expect(find.text('24 ms'), findsOneWidget);
      expect(find.text('0.0%'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}

KVNodeInfo _node(
  int peerId,
  String name,
  String ip,
  int cost, {
  double latency = 0,
  double loss = 0,
}) => KVNodeInfo(
  peerId: peerId,
  hostname: name,
  ipv4: ip,
  latencyMs: latency,
  nat: '',
  hops: const [],
  lossRate: loss,
  connections: const [],
  tunnelProto: 'udp',
  connType: '',
  rxBytes: BigInt.zero,
  txBytes: BigInt.zero,
  version: '',
  cost: cost,
  proxyCidrs: const [],
);
