import 'dart:math' as math;

import 'package:astral/shared/utils/network/node_utils.dart';
import 'package:astral/src/rust/api/simple.dart';
import 'package:flutter/material.dart';

class MeshConstellationNode {
  final String id;
  final String name;
  final String ip;
  final bool isLocal;
  final bool isRelay;
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

        var previous = localId;
        final forwarded = networkNode.hops.isNotEmpty || networkNode.cost >= 2;
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
              latencyMs: hop.latencyMs,
              lossRate: hop.packetLoss,
              cost: 0,
              tunnelProtocol: '',
              nat: '',
            ),
          );
          _addEdge(edges, previous, hopId, forwarded: true);
          previous = hopId;
        }
        _addEdge(edges, previous, targetId, forwarded: forwarded);
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
    if (existing == null || (existing.forwarded && !forwarded)) {
      edges[edge.key] = edge;
    }
  }
}

Map<String, Offset> layoutMeshConstellation(
  List<MeshConstellationNode> nodes,
  Size size, {
  double margin = 64,
}) {
  if (nodes.isEmpty || size.isEmpty) return {};
  final usableWidth = math.max(0, size.width - margin * 2);
  final usableHeight = math.max(0, size.height - margin * 2);
  final center = Offset(size.width / 2, size.height / 2);
  if (nodes.length == 1) return {nodes.first.id: center};

  final goldenAngle = math.pi * (3 - math.sqrt(5));
  final maxX = usableWidth / 2;
  final maxY = usableHeight / 2;
  final result = <String, Offset>{};

  for (var i = 0; i < nodes.length; i++) {
    final normalizedRadius = math.sqrt((i + .65) / nodes.length);
    final seed = (_stableHash(nodes[i].id) % 360) * math.pi / 180;
    final angle = i * goldenAngle + seed * .18;
    result[nodes[i].id] = Offset(
      center.dx + math.cos(angle) * maxX * normalizedRadius,
      center.dy + math.sin(angle) * maxY * normalizedRadius,
    );
  }
  return result;
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
