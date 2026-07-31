import 'package:astral/features/rooms/widgets/mesh_constellation_model.dart';
import 'package:astral/src/rust/api/simple.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('builds observed direct and forwarded mesh paths without a hub', () {
    final local = _node(peerId: 1, name: 'Local', ip: '10.1.0.1', cost: 0);
    final direct = _node(
      peerId: 2,
      name: 'Direct',
      ip: '10.1.0.2',
      cost: 1,
      latency: 12,
    );
    final forwarded = _node(
      peerId: 3,
      name: 'Forwarded',
      ip: '10.1.0.3',
      cost: 2,
      latency: 28,
      hops: const [
        NodeHopStats(
          peerId: 2,
          targetIp: '10.1.0.2',
          latencyMs: 12,
          packetLoss: 0,
          nodeName: 'Direct',
        ),
      ],
    );

    final model = MeshConstellationModel.fromNetwork([
      local,
      direct,
      forwarded,
    ], localIp: local.ipv4);

    expect(model.nodes, hasLength(3));
    expect(model.directPeerCount, 1);
    expect(model.forwardedPeerCount, 1);
    expect(model.edges.map((edge) => edge.key).toSet(), {
      'peer_1::peer_2',
      'peer_2::peer_3',
    });
  });

  test('layout gives all peers equal non-central placement', () {
    final model = MeshConstellationModel.fromNetwork([
      _node(peerId: 1, name: 'Local', ip: '10.1.0.1', cost: 0),
      _node(peerId: 2, name: 'A', ip: '10.1.0.2', cost: 1),
      _node(peerId: 3, name: 'B', ip: '10.1.0.3', cost: 1),
      _node(peerId: 4, name: 'C', ip: '10.1.0.4', cost: 2),
    ], localIp: '10.1.0.1');
    const size = Size(800, 500);
    final positions = layoutMeshConstellation(model.nodes, size, margin: 60);
    final local = model.nodes.singleWhere((node) => node.isLocal);

    expect(positions, hasLength(model.nodes.length));
    expect(positions[local.id], isNot(size.center(Offset.zero)));
    for (final position in positions.values) {
      expect(position.dx, inInclusiveRange(60, 740));
      expect(position.dy, inInclusiveRange(60, 440));
    }
  });
}

KVNodeInfo _node({
  required int peerId,
  required String name,
  required String ip,
  required int cost,
  double latency = 0,
  List<NodeHopStats> hops = const [],
}) => KVNodeInfo(
  peerId: peerId,
  hostname: name,
  ipv4: ip,
  latencyMs: latency,
  nat: '',
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
