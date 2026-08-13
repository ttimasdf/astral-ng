import 'package:astral/features/home/widgets/mission_mesh_preview.dart';
import 'package:astral/shared/utils/network/mesh_peer_identity.dart';
import 'package:astral/src/rust/api/simple.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Home projection keeps endpoints and omits local and relay nodes', () {
    final endpoints = projectMissionMeshEndpoints([
      _node(name: 'Local', ip: '10.1.0.1', cost: 0),
      _node(name: 'Direct', ip: '10.1.0.2', cost: 1),
      _node(name: 'Forwarded', ip: '10.1.0.3', cost: 2),
      _node(name: 'PublicServer_relay', ip: '0.0.0.0', cost: 1),
    ], localIp: '10.1.0.1');

    expect(endpoints.map((node) => node.hostname), ['Direct', 'Forwarded']);
    expect(endpoints.map((node) => node.cost), [1, 2]);
  });

  test('sparse graph fits its occupied bounds with fixed margins', () {
    const size = Size(500, 250);
    final peers = [
      _node(name: 'Direct', ip: '10.1.0.2', cost: 1),
      _node(name: 'Forwarded', ip: '10.1.0.3', cost: 2),
    ];
    final one = layoutMissionMeshGraph(peers.take(1).toList(), size);
    final two = layoutMissionMeshGraph(peers, size);

    for (final point in [
      one.localCenter,
      ...one.peerCenters,
      two.localCenter,
      ...two.peerCenters,
    ]) {
      expect(point.dx, inInclusiveRange(40, size.width - 40));
      expect(point.dy, inInclusiveRange(28, size.height - 100));
    }
    expect(
      (one.peerCenters.single - one.localCenter).distance,
      greaterThan(size.width * .6),
    );
    final twoBounds = [two.localCenter, ...two.peerCenters];
    final occupiedWidth = twoBounds
        .map((point) => point.dx)
        .reduce((a, b) => a < b ? a : b);
    final occupiedRight = twoBounds
        .map((point) => point.dx)
        .reduce((a, b) => a > b ? a : b);
    expect(occupiedRight - occupiedWidth, greaterThan(size.width * .5));
  });

  testWidgets('disconnected preview keeps local identity without an oval', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SizedBox(
          width: 500,
          height: 250,
          child: MissionMeshPreview(
            nodes: [],
            username: 'Local',
            localIp: '10.1.0.1',
            connected: false,
            connecting: false,
            reduceMotion: true,
          ),
        ),
      ),
    );

    final painter = _meshPainter(tester);
    expect(painter.peers, isEmpty);
    expect(
      painter.localEmoji,
      MeshPeerIdentity.emojiFor(username: 'Local', ip: '10.1.0.1'),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('connected preview preserves local and remote graph semantics', (
    tester,
  ) async {
    final nodes = [
      _node(name: 'Local', ip: '10.1.0.1', cost: 0),
      _node(name: 'Direct', ip: '10.1.0.2', cost: 1),
      _node(name: 'Forwarded', ip: '10.1.0.3', cost: 2),
      _node(name: 'PublicServer_relay', ip: '0.0.0.0', cost: 1),
    ];
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 500,
          height: 250,
          child: MissionMeshPreview(
            nodes: nodes,
            username: 'Local',
            localIp: '10.1.0.1',
            connected: true,
            connecting: false,
            reduceMotion: true,
          ),
        ),
      ),
    );

    final painter = _meshPainter(tester);
    expect(painter.peers.map((node) => node.hostname), ['Direct', 'Forwarded']);
    expect(
      painter.localEmoji,
      MeshPeerIdentity.emojiFor(username: 'Local', ip: '10.1.0.1'),
    );
    final layout = layoutMissionMeshGraph(painter.peers, const Size(500, 250));
    expect(layout.peerCenters, hasLength(2));
    expect(tester.takeException(), isNull);
  });
}

MissionMeshPainter _meshPainter(WidgetTester tester) =>
    tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((paint) => paint.painter)
        .whereType<MissionMeshPainter>()
        .single;

KVNodeInfo _node({
  required String name,
  required String ip,
  required int cost,
}) => KVNodeInfo(
  peerId: name.hashCode,
  hostname: name,
  ipv4: ip,
  latencyMs: 0,
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
