import 'dart:math' as math;

import 'package:enmesh/shared/utils/network/mesh_peer_identity.dart';
import 'package:enmesh/shared/utils/network/node_utils.dart';
import 'package:enmesh/src/rust/api/simple.dart';
import 'package:flutter/material.dart';

List<KVNodeInfo> projectMissionMeshEndpoints(
  List<KVNodeInfo> nodes, {
  required String localIp,
}) => nodes
    .where(
      (node) => node.ipv4 != localIp && !isServerNode(node) && node.cost > 0,
    )
    .toList(growable: false);

class MissionMeshGraphLayout {
  final Offset localCenter;
  final List<Offset> peerCenters;

  const MissionMeshGraphLayout({
    required this.localCenter,
    required this.peerCenters,
  });
}

/// Fits the original local-centered graph to the peers that actually exist.
MissionMeshGraphLayout layoutMissionMeshGraph(
  List<KVNodeInfo> peers,
  Size size,
) {
  const local = Offset.zero;
  if (peers.isEmpty || size.isEmpty) {
    return MissionMeshGraphLayout(
      localCenter: Offset(size.width / 2, (size.height - 92) / 2),
      peerCenters: const [],
    );
  }

  final occupied = <int>{};
  const slotCount = 48;
  final sortedPeers = [...peers]
    ..sort((a, b) => _identity(a).compareTo(_identity(b)));
  final rawPeers = <Offset>[];
  for (final peer in sortedPeers) {
    var slot = _stableHash(_identity(peer)) % slotCount;
    while (occupied.contains(slot)) {
      slot = (slot + 1) % slotCount;
    }
    occupied.add(slot);
    final angle = -math.pi / 2 + slot * math.pi * 2 / slotCount;
    rawPeers.add(Offset(math.cos(angle) * 180, math.sin(angle) * 100));
  }

  final points = [local, ...rawPeers];
  final minX = points.map((point) => point.dx).reduce(math.min);
  final maxX = points.map((point) => point.dx).reduce(math.max);
  final minY = points.map((point) => point.dy).reduce(math.min);
  final maxY = points.map((point) => point.dy).reduce(math.max);
  final rawWidth = maxX - minX;
  final rawHeight = maxY - minY;

  // Leave room for node circles and for the metrics overlay at the bottom.
  final target = Rect.fromLTRB(
    40,
    28,
    math.max(40, size.width - 40),
    math.max(28, size.height - 100),
  );
  final scaleX = rawWidth > .001 ? target.width / rawWidth : 0.0;
  final scaleY = rawHeight > .001 ? target.height / rawHeight : 0.0;
  final rawCenter = Offset((minX + maxX) / 2, (minY + maxY) / 2);
  final targetCenter = target.center;

  Offset fit(Offset point) => Offset(
    rawWidth > .001
        ? targetCenter.dx + (point.dx - rawCenter.dx) * scaleX
        : targetCenter.dx,
    rawHeight > .001
        ? targetCenter.dy + (point.dy - rawCenter.dy) * scaleY
        : targetCenter.dy,
  );
  return MissionMeshGraphLayout(
    localCenter: fit(local),
    peerCenters: rawPeers.map(fit).toList(growable: false),
  );
}

/// A simplified route overview for Home.
///
/// Relay servers are intentionally omitted. Each room peer is projected from
/// the local node using a solid direct line or a dashed forwarded line.
class MissionMeshPreview extends StatelessWidget {
  final List<KVNodeInfo> nodes;
  final String username;
  final String localIp;
  final bool connected;
  final bool connecting;
  final bool reduceMotion;

  const MissionMeshPreview({
    super.key,
    required this.nodes,
    required this.username,
    required this.localIp,
    required this.connected,
    required this.connecting,
    required this.reduceMotion,
  });

  @override
  Widget build(BuildContext context) {
    final peers =
        connected
            ? projectMissionMeshEndpoints(nodes, localIp: localIp)
            : const <KVNodeInfo>[];
    final local = nodes.where((node) => node.ipv4 == localIp).firstOrNull;
    final localEmoji =
        local == null
            ? MeshPeerIdentity.emojiFor(username: username, ip: localIp)
            : MeshPeerIdentity.emojiForNode(local);

    return RepaintBoundary(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration:
            reduceMotion ? Duration.zero : const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        builder:
            (context, progress, _) => CustomPaint(
              painter: MissionMeshPainter(
                colorScheme: Theme.of(context).colorScheme,
                peers: peers,
                localEmoji: localEmoji,
                connected: connected,
                connecting: connecting,
                progress: progress,
              ),
              child: const SizedBox.expand(),
            ),
      ),
    );
  }
}

class MissionMeshPainter extends CustomPainter {
  final ColorScheme colorScheme;
  final List<KVNodeInfo> peers;
  final String localEmoji;
  final bool connected;
  final bool connecting;
  final double progress;

  const MissionMeshPainter({
    required this.colorScheme,
    required this.peers,
    required this.localEmoji,
    required this.connected,
    required this.connecting,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final sortedPeers = [...peers]
      ..sort((a, b) => _identity(a).compareTo(_identity(b)));
    final layout = layoutMissionMeshGraph(sortedPeers, size);
    final linePaint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..color = colorScheme.onSurfaceVariant.withValues(
            alpha: connected ? .52 : .24,
          );

    for (var index = 0; index < sortedPeers.length; index++) {
      final peer = sortedPeers[index];
      final endpoint =
          Offset.lerp(layout.localCenter, layout.peerCenters[index], progress)!;
      if (peer.cost >= 2) {
        _drawDashedLine(canvas, layout.localCenter, endpoint, linePaint);
      } else {
        canvas.drawLine(layout.localCenter, endpoint, linePaint);
      }
      _drawEmojiNode(
        canvas,
        endpoint,
        MeshPeerIdentity.emojiForNode(peer),
        local: false,
        opacity: progress,
      );
    }

    // Disconnected keeps the local identity but deliberately has no oval.
    _drawEmojiNode(
      canvas,
      layout.localCenter,
      localEmoji,
      local: true,
      opacity: connected || connecting ? 1 : .68,
    );
  }

  void _drawEmojiNode(
    Canvas canvas,
    Offset center,
    String emoji, {
    required bool local,
    required double opacity,
  }) {
    final radius = local ? 22.0 : 18.0;
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Color.alphaBlend(
          colorScheme.surfaceContainerHighest.withValues(alpha: opacity),
          colorScheme.surface,
        ),
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = local ? 2.4 : 1.2
        ..color = (local ? colorScheme.primary : colorScheme.outline)
            .withValues(alpha: opacity),
    );
    final text = TextPainter(
      text: TextSpan(text: emoji, style: TextStyle(fontSize: local ? 20 : 17)),
      textDirection: TextDirection.ltr,
    )..layout();
    text.paint(canvas, center - Offset(text.width / 2, text.height / 2));
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    final distance = (end - start).distance;
    if (distance == 0) return;
    final direction = (end - start) / distance;
    const dashLength = 7.0;
    const gapLength = 5.0;
    for (
      var offset = 0.0;
      offset < distance;
      offset += dashLength + gapLength
    ) {
      final dashEnd = math.min(offset + dashLength, distance);
      canvas.drawLine(
        start + direction * offset,
        start + direction * dashEnd,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(MissionMeshPainter oldDelegate) =>
      oldDelegate.peers != peers ||
      oldDelegate.localEmoji != localEmoji ||
      oldDelegate.connected != connected ||
      oldDelegate.connecting != connecting ||
      oldDelegate.progress != progress ||
      oldDelegate.colorScheme != colorScheme;
}

String _identity(KVNodeInfo node) =>
    '${node.hostname.trim().toLowerCase()}|${node.ipv4.trim()}';

int _stableHash(String source) {
  var hash = 2166136261;
  for (final unit in source.codeUnits) {
    hash ^= unit;
    hash = (hash * 16777619) & 0x7fffffff;
  }
  return hash;
}
