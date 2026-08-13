import 'package:astral/shared/utils/network/mesh_peer_identity.dart';
import 'package:astral/shared/utils/network/node_utils.dart';
import 'package:astral/src/rust/api/simple.dart';

class MeshConstellationNode {
  final String id;
  final String name;
  final String ip;
  final bool isLocal;
  final bool isRelay;
  final String emoji;
  final double latencyMs;
  final double lossRate;
  final int cost;
  final String tunnelProtocol;
  final String nat;

  const MeshConstellationNode({
    required this.id,
    required this.name,
    required this.ip,
    required this.isLocal,
    required this.isRelay,
    required this.emoji,
    required this.latencyMs,
    required this.lossRate,
    required this.cost,
    required this.tunnelProtocol,
    required this.nat,
  });
}

class MeshConstellationEdge {
  final String a;
  final String b;
  final bool forwarded;

  const MeshConstellationEdge({
    required this.a,
    required this.b,
    required this.forwarded,
  });

  String get key => a.compareTo(b) <= 0 ? '$a::$b' : '$b::$a';
}

class MeshConstellationModel {
  final List<MeshConstellationNode> nodes;
  final List<MeshConstellationEdge> edges;
  final int directPeerCount;
  final int forwardedPeerCount;

  const MeshConstellationModel({
    required this.nodes,
    required this.edges,
    required this.directPeerCount,
    required this.forwardedPeerCount,
  });

  factory MeshConstellationModel.fromNetwork(
    List<KVNodeInfo> networkNodes, {
    required String localIp,
  }) {
    final nodes = <String, MeshConstellationNode>{};
    final idsByPeer = <int, String>{};
    final idsByIp = <String, String>{};

    for (final node in networkNodes) {
      final id = _nodeId(node.peerId, node.ipv4, node.hostname);
      final isLocal = localIp.isNotEmpty && node.ipv4 == localIp;
      // The Rust status adapter currently synthesizes the local row from a
      // remote connection and can therefore reuse that remote peer ID. Keep
      // virtual IP as the primary identity and never let the synthetic local
      // peer ID overwrite a remote route lookup.
      if (!isLocal && node.peerId > 0) idsByPeer[node.peerId] = id;
      if (_hasUniqueVirtualIp(node.ipv4)) idsByIp[node.ipv4] = id;
      nodes[id] = MeshConstellationNode(
        id: id,
        name: _displayName(node.hostname),
        ip: node.ipv4,
        isLocal: isLocal,
        isRelay: isServerNode(node),
        emoji: MeshPeerIdentity.emojiForNode(node),
        latencyMs: node.latencyMs,
        lossRate: node.lossRate,
        cost: node.cost,
        tunnelProtocol: node.tunnelProto,
        nat: node.nat,
      );
    }

    String? localId;
    for (final node in nodes.values) {
      if (node.isLocal) {
        localId = node.id;
        break;
      }
    }

    final edges = <String, MeshConstellationEdge>{};
    var directPeers = 0;
    var forwardedPeers = 0;

    if (localId != null) {
      for (final networkNode in networkNodes) {
        final targetId = _nodeId(
          networkNode.peerId,
          networkNode.ipv4,
          networkNode.hostname,
        );
        if (targetId == localId) continue;

        if (networkNode.cost == 1) {
          directPeers++;
        } else if (networkNode.cost >= 2) {
          forwardedPeers++;
        }

        if (networkNode.cost == 1) {
          _addEdge(edges, localId, targetId, forwarded: false);
          continue;
        }

        final route = <String>[];
        for (final hop in networkNode.hops) {
          final hopId =
              idsByIp[hop.targetIp] ??
              idsByPeer[hop.peerId] ??
              _nodeId(hop.peerId, hop.targetIp, hop.nodeName);
          nodes.putIfAbsent(
            hopId,
            () => MeshConstellationNode(
              id: hopId,
              name: _displayName(
                hop.nodeName.isEmpty ? hop.targetIp : hop.nodeName,
              ),
              ip: hop.targetIp,
              isLocal: false,
              isRelay: isServerIdentity(hop.nodeName, hop.targetIp),
              emoji: MeshPeerIdentity.emojiFor(
                username: hop.nodeName,
                ip: hop.targetIp,
              ),
              latencyMs: hop.latencyMs,
              lossRate: hop.packetLoss,
              cost: 0,
              tunnelProtocol: '',
              nat: '',
            ),
          );
          if (hopId != localId && hopId != targetId && !route.contains(hopId)) {
            route.add(hopId);
          }
        }
        route.add(targetId);

        final routeUsesRelay = route.any(
          (routeNode) => nodes[routeNode]?.isRelay == true,
        );
        var previous = localId;
        for (var index = 0; index < route.length; index++) {
          _addEdge(
            edges,
            previous,
            route[index],
            forwarded: routeUsesRelay || index > 0 || route.length == 1,
          );
          previous = route[index];
        }
      }
    }

    final sortedNodes =
        nodes.values.toList()..sort((a, b) {
          final hashComparison = _stableHash(a.id).compareTo(_stableHash(b.id));
          return hashComparison != 0 ? hashComparison : a.id.compareTo(b.id);
        });

    return MeshConstellationModel(
      nodes: sortedNodes,
      edges: edges.values.toList(),
      directPeerCount: directPeers,
      forwardedPeerCount: forwardedPeers,
    );
  }

  static void _addEdge(
    Map<String, MeshConstellationEdge> edges,
    String a,
    String b, {
    required bool forwarded,
  }) {
    if (a == b) return;
    final edge = MeshConstellationEdge(a: a, b: b, forwarded: forwarded);
    final existing = edges[edge.key];
    if (existing == null || (!existing.forwarded && forwarded)) {
      edges[edge.key] = edge;
    }
  }
}

String _nodeId(int peerId, String ip, String name) {
  if (_hasUniqueVirtualIp(ip)) return 'ip_$ip';
  if (peerId > 0) return 'peer_$peerId';
  return 'name_$name';
}

bool _hasUniqueVirtualIp(String ip) => ip.isNotEmpty && ip != '0.0.0.0';

String _displayName(String raw) =>
    raw.startsWith('PublicServer_')
        ? raw.substring('PublicServer_'.length)
        : raw;

int _stableHash(String source) {
  var hash = 2166136261;
  for (final unit in source.codeUnits) {
    hash ^= unit;
    hash = (hash * 16777619) & 0x7fffffff;
  }
  return hash;
}
