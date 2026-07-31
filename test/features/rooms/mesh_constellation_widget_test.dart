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
      ];

      await tester.pumpWidget(
        MaterialApp(home: MeshConstellation(nodes: nodes, localIp: '10.1.0.1')),
      );
      await tester.pump();

      expect(find.byType(InkWell), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    },
  );
}

KVNodeInfo _node(int peerId, String name, String ip, int cost) => KVNodeInfo(
  peerId: peerId,
  hostname: name,
  ipv4: ip,
  latencyMs: 12,
  nat: '',
  hops: const [],
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
