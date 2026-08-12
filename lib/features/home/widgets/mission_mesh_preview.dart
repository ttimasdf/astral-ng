import 'dart:math' as math;

import 'package:astral/shared/utils/network/mesh_peer_identity.dart';
import 'package:astral/shared/utils/network/node_utils.dart';
import 'package:astral/src/rust/api/simple.dart';
import 'package:flutter/material.dart';

List<KVNodeInfo> projectMissionMeshEndpoints(
  List<KVNodeInfo> nodes, {
  required String localIp,
}) => nodes
    .where(
      (node) => node.ipv4 != localIp && !isServerNode(node) && node.cost > 0,
    )
    .toList(growable: false);

/// A simplified endpoint overview for Home.
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
    final colorScheme = Theme.of(context).colorScheme;
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
              painter: _MissionMeshPainter(
                colorScheme: colorScheme,
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

class _MissionMeshPainter extends CustomPainter {
  final ColorScheme colorScheme;
  final List<KVNodeInfo> peers;
  final String localEmoji;
  final bool connected;
  final bool connecting;
  final double progress;

  const _MissionMeshPainter({
    required this.colorScheme,
    required this.peers,
    required this.localEmoji,
    required this.connected,
    required this.connecting,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * .43);
    final radiusX = math.max(0, size.width / 2 - 34);
    final radiusY = math.max(0, size.height * .34 - 28);
    final linePaint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..color = colorScheme.onSurfaceVariant.withValues(
            alpha: connected ? .52 : .24,
          );

    if (peers.isEmpty) {
      canvas.drawOval(
        Rect.fromCenter(
          center: center,
          width: radiusX * 1.45,
          height: radiusY * 1.25,
        ),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = colorScheme.outlineVariant.withValues(alpha: .38),
      );
    }

    final occupied = <int>{};
    const slotCount = 48;
    for (final peer in [...peers]
      ..sort((a, b) => _identity(a).compareTo(_identity(b)))) {
      var slot = _stableHash(_identity(peer)) % slotCount;
      while (occupied.contains(slot)) {
        slot = (slot + 1) % slotCount;
      }
      occupied.add(slot);
      final angle = -math.pi / 2 + slot * math.pi * 2 / slotCount;
      final target = Offset(
        center.dx + math.cos(angle) * radiusX,
        center.dy + math.sin(angle) * radiusY,
      );
      final endpoint = Offset.lerp(center, target, progress)!;
      if (peer.cost >= 2) {
        _drawDashedLine(canvas, center, endpoint, linePaint);
      } else {
        canvas.drawLine(center, endpoint, linePaint);
      }
      _drawEmojiNode(
        canvas,
        endpoint,
        MeshPeerIdentity.emojiForNode(peer),
        local: false,
        opacity: progress,
      );
    }

    _drawEmojiNode(
      canvas,
      center,
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

  @override
  bool shouldRepaint(_MissionMeshPainter oldDelegate) =>
      oldDelegate.peers != peers ||
      oldDelegate.localEmoji != localEmoji ||
      oldDelegate.connected != connected ||
      oldDelegate.connecting != connecting ||
      oldDelegate.progress != progress ||
      oldDelegate.colorScheme != colorScheme;
}
