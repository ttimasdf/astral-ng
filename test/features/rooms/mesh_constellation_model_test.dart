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
    expect(
      model.nodes.singleWhere((node) => node.ip == '10.1.0.1').isRelay,
      isFalse,
    );
    expect(
      model.nodes.singleWhere((node) => node.ip == '10.1.0.2').isRelay,
      isFalse,
    );
    expect(
      model.nodes.singleWhere((node) => node.ip == '10.1.0.3').isRelay,
      isFalse,
    );
    expect(model.directPeerCount, 1);
    expect(model.forwardedPeerCount, 1);
    expect(model.edges.map((edge) => edge.key).toSet(), {
      'ip_10.1.0.1::ip_10.1.0.2',
      'ip_10.1.0.2::ip_10.1.0.3',
    });
  });

  test('distinguishes relay identity from an endpoint forwarding a path', () {
    final model = MeshConstellationModel.fromNetwork([
      _node(peerId: 1, name: 'Local', ip: '10.1.0.1', cost: 0),
      _node(peerId: 2, name: 'Endpoint', ip: '10.1.0.2', cost: 1),
      _node(peerId: 3, name: 'PublicServer_Relay', ip: '10.1.0.3', cost: 1),
      _node(
        peerId: 4,
        name: 'Forwarded target',
        ip: '10.1.0.4',
        cost: 2,
        hops: const [
          NodeHopStats(
            peerId: 2,
            targetIp: '10.1.0.2',
            latencyMs: 12,
            packetLoss: 0,
            nodeName: 'Endpoint',
          ),
        ],
      ),
    ], localIp: '10.1.0.1');

    final endpoint = model.nodes.singleWhere((node) => node.ip == '10.1.0.2');
    final relay = model.nodes.singleWhere((node) => node.ip == '10.1.0.3');

    expect(endpoint.isRelay, isFalse);
    expect(relay.isRelay, isTrue);
  });

  test(
    'preserves direct peer and forwarded route when local peer ID collides',
    () {
      final local = _node(peerId: 2, name: 'Local', ip: '10.1.0.1', cost: 0);
      final direct = _node(
        peerId: 2,
        name: 'Direct',
        ip: '10.1.0.2',
        cost: 1,
        latency: 12,
      );
      final relayed = _node(
        peerId: 3,
        name: 'Relayed',
        ip: '10.1.0.3',
        cost: 2,
        latency: 28,
        hops: const [
          NodeHopStats(
            peerId: 2,
            targetIp: '10.1.0.1',
            latencyMs: 0,
            packetLoss: 0,
            nodeName: 'Local',
          ),
          NodeHopStats(
            peerId: 2,
            targetIp: '10.1.0.2',
            latencyMs: 12,
            packetLoss: 0,
            nodeName: 'Direct',
          ),
          NodeHopStats(
            peerId: 3,
            targetIp: '10.1.0.3',
            latencyMs: 28,
            packetLoss: 0,
            nodeName: 'Relayed',
          ),
        ],
      );

      final model = MeshConstellationModel.fromNetwork([
        direct,
        relayed,
        local,
      ], localIp: local.ipv4);

      expect(model.nodes, hasLength(3));
      expect(model.nodes.map((node) => node.ip), contains(direct.ipv4));
      expect(model.edges.map((edge) => edge.key).toSet(), {
        'ip_10.1.0.1::ip_10.1.0.2',
        'ip_10.1.0.2::ip_10.1.0.3',
      });
      expect(
        model.edges
            .singleWhere((edge) => edge.key == 'ip_10.1.0.1::ip_10.1.0.2')
            .forwarded,
        isFalse,
      );
      expect(
        model.edges
            .singleWhere((edge) => edge.key == 'ip_10.1.0.2::ip_10.1.0.3')
            .forwarded,
        isTrue,
      );
    },
  );

  test('stable peers keep positions when another peer joins', () {
    final baseModel = MeshConstellationModel.fromNetwork([
      _node(peerId: 1, name: 'Local', ip: '10.1.0.1', cost: 0),
      _node(peerId: 2, name: 'A', ip: '10.1.0.2', cost: 1),
      _node(peerId: 3, name: 'B', ip: '10.1.0.3', cost: 2),
    ], localIp: '10.1.0.1');
    final expandedModel = MeshConstellationModel.fromNetwork([
      _node(peerId: 1, name: 'Local', ip: '10.1.0.1', cost: 0),
      _node(peerId: 2, name: 'A', ip: '10.1.0.2', cost: 1),
      _node(peerId: 3, name: 'B', ip: '10.1.0.3', cost: 2),
      _node(peerId: 4, name: 'C', ip: '10.1.0.4', cost: 1),
    ], localIp: '10.1.0.1');
    const size = Size(800, 500);
    final before = layoutMeshConstellation(baseModel.nodes, size, margin: 60);
    final after = layoutMeshConstellation(
      expandedModel.nodes,
      size,
      margin: 60,
    );

    for (final id in before.keys) {
      expect(after[id], before[id]);
    }
  });

  test('layout resolves collisions between hashed ring slots', () {
    final model = MeshConstellationModel.fromNetwork([
      _node(peerId: 1, name: 'Local', ip: '10.1.0.1', cost: 0),
      for (var id = 2; id <= 17; id++)
        _node(
          peerId: id,
          name: 'Peer $id',
          ip: '10.1.0.$id',
          cost: id.isEven ? 1 : 2,
        ),
    ], localIp: '10.1.0.1');
    final positions =
        layoutMeshConstellation(
          model.nodes,
          const Size(800, 500),
          margin: 60,
        ).values.toList();

    for (var first = 0; first < positions.length; first++) {
      for (var second = first + 1; second < positions.length; second++) {
        expect(
          (positions[first] - positions[second]).distance,
          greaterThanOrEqualTo(54),
        );
      }
    }
  });

  test('layout centers local and organizes peers into role rings', () {
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
    expect(positions[local.id], size.center(Offset.zero));
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
