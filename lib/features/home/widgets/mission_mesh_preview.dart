import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A deliberately non-hierarchical mesh glimpse for the Home hero.
class MissionMeshPreview extends StatefulWidget {
  final int peerCount;
  final int directCount;
  final bool connected;
  final bool connecting;
  final bool reduceMotion;

  const MissionMeshPreview({
    super.key,
    required this.peerCount,
    required this.directCount,
    required this.connected,
    required this.connecting,
    required this.reduceMotion,
  });

  @override
  State<MissionMeshPreview> createState() => _MissionMeshPreviewState();
}

class _MissionMeshPreviewState extends State<MissionMeshPreview>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    _syncAnimation();
  }

  @override
  void didUpdateWidget(MissionMeshPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncAnimation();
  }

  void _syncAnimation() {
    final shouldAnimate =
        !widget.reduceMotion && (widget.connected || widget.connecting);
    if (shouldAnimate && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!shouldAnimate && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder:
            (context, _) => CustomPaint(
              painter: _MissionMeshPainter(
                colorScheme: colorScheme,
                peerCount: widget.peerCount,
                directCount: widget.directCount,
                connected: widget.connected,
                connecting: widget.connecting,
                phase: _controller.value,
              ),
              child: const SizedBox.expand(),
            ),
      ),
    );
  }
}

class _MissionMeshPainter extends CustomPainter {
  final ColorScheme colorScheme;
  final int peerCount;
  final int directCount;
  final bool connected;
  final bool connecting;
  final double phase;

  const _MissionMeshPainter({
    required this.colorScheme,
    required this.peerCount,
    required this.directCount,
    required this.connected,
    required this.connecting,
    required this.phase,
  });

  static const _positions = <Offset>[
    Offset(.16, .30),
    Offset(.42, .16),
    Offset(.75, .24),
    Offset(.86, .58),
    Offset(.61, .78),
    Offset(.29, .72),
    Offset(.48, .49),
    Offset(.12, .58),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final visibleCount =
        connected ? math.min(math.max(peerCount + 1, 2), _positions.length) : 5;
    final points = [
      for (var i = 0; i < visibleCount; i++)
        Offset(_positions[i].dx * size.width, _positions[i].dy * size.height),
    ];

    final linePaint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.25;
    final inactive = colorScheme.outlineVariant.withValues(alpha: .42);
    final direct = colorScheme.primary.withValues(alpha: connected ? .65 : .25);
    final forwarded = colorScheme.tertiary.withValues(alpha: .62);

    const edgePairs = <(int, int)>[
      (0, 1),
      (1, 2),
      (2, 3),
      (3, 4),
      (4, 5),
      (5, 0),
      (0, 6),
      (2, 6),
      (4, 6),
      (5, 7),
    ];

    var edgeIndex = 0;
    for (final edge in edgePairs) {
      if (edge.$1 >= points.length || edge.$2 >= points.length) continue;
      if (!connected) {
        linePaint.color = inactive;
      } else if (edgeIndex < directCount) {
        linePaint.color = direct;
      } else {
        linePaint.color = forwarded;
      }
      canvas.drawLine(points[edge.$1], points[edge.$2], linePaint);

      if ((connected || connecting) && edgeIndex % 2 == 0) {
        final pulse =
            Offset.lerp(
              points[edge.$1],
              points[edge.$2],
              (phase + edgeIndex * .17) % 1,
            )!;
        canvas.drawCircle(
          pulse,
          2.2,
          Paint()..color = linePaint.color.withValues(alpha: .95),
        );
      }
      edgeIndex++;
    }

    for (var i = 0; i < points.length; i++) {
      final isLocal = i == 0;
      final nodeColor =
          !connected
              ? colorScheme.outline
              : i <= directCount
              ? colorScheme.primary
              : colorScheme.tertiary;
      if (isLocal) {
        canvas.drawCircle(
          points[i],
          11,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1
            ..color = nodeColor.withValues(alpha: .35),
        );
      }
      canvas.drawCircle(
        points[i],
        isLocal ? 5.5 : 4.2,
        Paint()..color = nodeColor,
      );
      canvas.drawCircle(
        points[i],
        isLocal ? 2.5 : 1.8,
        Paint()..color = colorScheme.surface,
      );
    }
  }

  @override
  bool shouldRepaint(_MissionMeshPainter oldDelegate) =>
      oldDelegate.peerCount != peerCount ||
      oldDelegate.directCount != directCount ||
      oldDelegate.connected != connected ||
      oldDelegate.connecting != connecting ||
      oldDelegate.phase != phase ||
      oldDelegate.colorScheme != colorScheme;
}
