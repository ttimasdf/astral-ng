import 'package:astral/features/rooms/widgets/mesh_constellation.dart';
import 'package:astral/src/rust/api/simple.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'constellation renders tappable peers without a parent scaffold',
    (tester) async {
      final nodes = [
        _node(1, 'Local', '10.1.0.1', 0),
        _node(2, 'Peer', '10.1.0.2', 1),
        _node(3, 'PublicServer_Relay', '0.0.0.0', 1),
        _node(
          4,
          'Forwarded target',
          '10.1.0.4',
          2,
          hops: const [
            NodeHopStats(
              peerId: 2,
              targetIp: '10.1.0.2',
              latencyMs: 12,
              packetLoss: 0,
              nodeName: 'Peer',
            ),
          ],
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(home: MeshConstellation(nodes: nodes, localIp: '10.1.0.1')),
      );
      await tester.pump();

      expect(find.byType(InkWell), findsNWidgets(4));
      expect(find.byIcon(Icons.my_location_rounded), findsOneWidget);
      expect(find.byIcon(Icons.computer_rounded), findsNWidgets(2));
      expect(find.byIcon(Icons.dns_rounded), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('detail values align and scroll in a short viewport', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 240);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: MeshConstellation(
          nodes: [
            _node(1, 'Local', '10.1.0.1', 0),
            _node(2, 'PublicServer_Relay', '0.0.0.0', 1),
            _node(3, 'Peer', '10.1.0.3', 1, nat: 'Restricted'),
          ],
          localIp: '10.1.0.1',
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byIcon(Icons.computer_rounded));
    await tester.pumpAndSettle();

    final values = ['10.1.0.3', '12 ms', '0.0%', 'udp4'];
    final leftEdges = [
      for (final value in values) tester.getTopLeft(find.text(value)).dx,
    ];

    for (final leftEdge in leftEdges.skip(1)) {
      expect(leftEdge, moreOrLessEquals(leftEdges.first, epsilon: .1));
    }
    expect(find.text('0.0.0.0'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

KVNodeInfo _node(
  int peerId,
  String name,
  String ip,
  int cost, {
  List<NodeHopStats> hops = const [],
  String nat = '',
}) => KVNodeInfo(
  peerId: peerId,
  hostname: name,
  ipv4: ip,
  latencyMs: 12,
  nat: nat,
  hops: hops,
  lossRate: 0,
  connections: const [],
  tunnelProto: 'udp',
  connType: '',
  rxBytes: BigInt.zero,
  txBytes: BigInt.zero,
  version: '',
  cost: cost,
  proxyCidrs: const [],
);
