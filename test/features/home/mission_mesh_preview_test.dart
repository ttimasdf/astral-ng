import 'package:astral/features/home/widgets/mission_mesh_preview.dart';
import 'package:astral/src/rust/api/simple.dart';
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
}

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
