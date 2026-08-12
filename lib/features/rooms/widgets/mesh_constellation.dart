import 'dart:math' as math;

import 'package:astral/features/rooms/widgets/mesh_constellation_model.dart';
import 'package:astral/features/rooms/widgets/peer_connection_style.dart';
import 'package:astral/src/rust/api/simple.dart';
import 'package:astral/generated/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// A stable, non-hierarchical view of routes observed by this device.
class MeshConstellation extends StatelessWidget {
  final List<KVNodeInfo> nodes;
  final String localIp;
  final bool reduceMotion;

  const MeshConstellation({
    super.key,
    required this.nodes,
    required this.localIp,
    this.reduceMotion = false,
  });

  @override
  Widget build(BuildContext context) {
    final model = MeshConstellationModel.fromNetwork(nodes, localIp: localIp);
    final colorScheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final compact = constraints.maxWidth < 600;
        final dense = model.nodes.length > 12;
        final positions = layoutMeshConstellation(
          model.nodes,
          size,
          margin:
              compact
                  ? 42
                  : dense
                  ? 54
                  : 72,
        );

        return ClipRect(
          child: Material(
            color: colorScheme.surface,
            child: Stack(
              children: [
                Positioned.fill(
                  child: _AnimatedConstellationScene(
                    model: model,
                    positions: positions,
                    dense: dense,
                    reduceMotion: reduceMotion,
                    colorScheme: colorScheme,
                    onNodeTap: (node) => _showNodeDetails(context, node),
                  ),
                ),
                Positioned(
                  left: compact ? 10 : 16,
                  top: compact ? 10 : 16,
                  child: _ConstellationLegend(model: model),
                ),
                Positioned(
                  right: compact ? 10 : 16,
                  bottom: compact ? 10 : 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.surface.withValues(alpha: .9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colorScheme.outlineVariant),
                    ),
                    child: Text(
                      LocaleKeys.rooms_observed_here.tr(),
                      style: TextStyle(
                        fontSize: 10,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showNodeDetails(BuildContext context, MeshConstellationNode node) {
    final colorScheme = Theme.of(context).colorScheme;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder:
          (context) => SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _NodeGlyph(node: node, size: 42),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              node.name,
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            Text(
                              node.isLocal
                                  ? LocaleKeys.rooms_this_device.tr()
                                  : node.isRelay
                                  ? LocaleKeys.rooms_forwarding_peer.tr()
                                  : LocaleKeys.rooms_mesh_peer.tr(),
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Table(
                    defaultVerticalAlignment: TableCellVerticalAlignment.top,
                    columnWidths: const {
                      0: FixedColumnWidth(28),
                      1: IntrinsicColumnWidth(),
                      2: FlexColumnWidth(),
                    },
                    children: [
                      if (node.ip.isNotEmpty && !node.isRelay)
                        _detailRow(
                          colorScheme: colorScheme,
                          icon: Icons.lan_outlined,
                          label: LocaleKeys.virtual_network_ip.tr(),
                          value: node.ip,
                        ),
                      if (!node.isLocal && node.latencyMs > 0)
                        _detailRow(
                          colorScheme: colorScheme,
                          icon: Icons.speed_rounded,
                          label: LocaleKeys.mission_latency.tr(),
                          value: '${node.latencyMs.round()} ms',
                        ),
                      if (!node.isLocal)
                        _detailRow(
                          colorScheme: colorScheme,
                          icon: Icons.network_check_rounded,
                          label: LocaleKeys.rooms_packet_loss.tr(),
                          value: '${node.lossRate.toStringAsFixed(1)}%',
                        ),
                      if (node.tunnelProtocol.isNotEmpty)
                        _detailRow(
                          colorScheme: colorScheme,
                          icon: Icons.route_outlined,
                          label: LocaleKeys.rooms_transport.tr(),
                          value: PeerConnectionStyle.formatTunnelProto(
                            node.tunnelProtocol,
                          ),
                        ),
                      if (node.nat.isNotEmpty)
                        _detailRow(
                          colorScheme: colorScheme,
                          icon: Icons.router_outlined,
                          label: LocaleKeys.rooms_nat.tr(),
                          value: node.nat,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
    );
  }

  TableRow _detailRow({
    required ColorScheme colorScheme,
    required IconData icon,
    required String label,
    required String value,
  }) {
    const verticalPadding = EdgeInsets.symmetric(vertical: 7);
    return TableRow(
      children: [
        Padding(
          padding: verticalPadding,
          child: Icon(icon, size: 18, color: colorScheme.primary),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 7, 24, 7),
          child: Text(
            label,
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
        ),
        Padding(
          padding: verticalPadding,
          child: Text(
            value,
            textAlign: TextAlign.start,
            softWrap: true,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class _AnimatedConstellationScene extends StatefulWidget {
  final MeshConstellationModel model;
  final Map<String, Offset> positions;
  final bool dense;
  final bool reduceMotion;
  final ColorScheme colorScheme;
  final ValueChanged<MeshConstellationNode> onNodeTap;

  const _AnimatedConstellationScene({
    required this.model,
    required this.positions,
    required this.dense,
    required this.reduceMotion,
    required this.colorScheme,
    required this.onNodeTap,
  });

  @override
  State<_AnimatedConstellationScene> createState() =>
      _AnimatedConstellationSceneState();
}

class _AnimatedConstellationSceneState
    extends State<_AnimatedConstellationScene>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Map<String, Offset> _from = const {};
  Map<String, Offset> _to = const {};

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _to = widget.positions;
    _from = {
      for (final entry in _to.entries) entry.key: _spawnPosition(entry.key),
    };
    if (widget.reduceMotion) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(_AnimatedConstellationScene oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (mapEquals(oldWidget.positions, widget.positions)) return;
    final current = _interpolatedPositions();
    _from = {
      for (final entry in widget.positions.entries)
        entry.key: current[entry.key] ?? _spawnPosition(entry.key),
    };
    _to = widget.positions;
    if (widget.reduceMotion) {
      _controller.value = 1;
    } else {
      _controller.forward(from: 0);
    }
  }

  Offset _spawnPosition(String id) {
    for (final edge in widget.model.edges) {
      final next = _to[edge.b];
      if (edge.a == id && next != null) return next;
      final previous = _to[edge.a];
      if (edge.b == id && previous != null) return previous;
    }
    final local = widget.model.nodes.where((node) => node.isLocal).firstOrNull;
    return local == null ? Offset.zero : _to[local.id] ?? Offset.zero;
  }

  Map<String, Offset> _interpolatedPositions() {
    final progress = Curves.easeOutCubic.transform(_controller.value);
    return {
      for (final entry in _to.entries)
        entry.key:
            Offset.lerp(
              _from[entry.key] ?? entry.value,
              entry.value,
              progress,
            )!,
    };
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final positions = _interpolatedPositions();
        final nodeSize = widget.dense ? 48.0 : 62.0;
        return Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _ConstellationPainter(
                  positions: positions,
                  edges: widget.model.edges,
                  colorScheme: widget.colorScheme,
                ),
              ),
            ),
            for (final node in widget.model.nodes)
              if (positions[node.id] case final position?)
                Positioned(
                  key: ValueKey('position-${node.id}'),
                  left: position.dx - nodeSize / 2,
                  top: position.dy - nodeSize / 2,
                  child: GestureDetector(
                    key: ValueKey(node.id),
                    onTap: () => widget.onNodeTap(node),
                    child: _ConstellationNode(
                      node: node,
                      dense: widget.dense,
                      onTap: () => widget.onNodeTap(node),
                    ),
                  ),
                ),
          ],
        );
      },
    );
  }
}

class _ConstellationNode extends StatelessWidget {
  final MeshConstellationNode node;
  final bool dense;
  final VoidCallback onTap;

  const _ConstellationNode({
    required this.node,
    required this.dense,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final diameter = dense ? 48.0 : 62.0;
    return Semantics(
      button: true,
      label:
          '${node.name}, ${node.isLocal
              ? LocaleKeys.rooms_this_device.tr()
              : node.isRelay
              ? LocaleKeys.rooms_forwarding_peer.tr()
              : LocaleKeys.rooms_mesh_peer.tr()}',
      child: Tooltip(
        message:
            node.ip.isEmpty || node.isRelay
                ? node.name
                : '${node.name}\n${node.ip}',
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: diameter,
            height: diameter,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                _NodeGlyph(node: node, size: diameter),
                if (!dense)
                  Positioned(
                    top: diameter + 5,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 100),
                      child: Text(
                        node.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontSize: 10,
                          fontWeight:
                              node.isLocal ? FontWeight.w800 : FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NodeGlyph extends StatelessWidget {
  final MeshConstellationNode node;
  final double size;

  const _NodeGlyph({required this.node, required this.size});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color =
        node.isLocal
            ? colorScheme.primary
            : node.isRelay
            ? colorScheme.tertiary
            : colorScheme.secondary;
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * .18),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Color.alphaBlend(
          color.withValues(alpha: .18),
          colorScheme.surface,
        ),
        border: Border.all(color: color, width: node.isLocal ? 2.5 : 1.4),
        boxShadow:
            node.isLocal
                ? [
                  BoxShadow(
                    color: color.withValues(alpha: .22),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ]
                : null,
      ),
      child:
          node.isRelay
              ? Icon(Icons.dns_rounded, size: size * .36, color: color)
              : Text(node.emoji, style: TextStyle(fontSize: size * .34)),
    );
  }
}

class _ConstellationLegend extends StatelessWidget {
  final MeshConstellationModel model;

  const _ConstellationLegend({required this.model});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: .92),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            LocaleKeys.rooms_constellation.tr(),
            style: TextStyle(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            LocaleKeys.rooms_visible_summary.tr(
              namedArgs: {
                'nodes': '${model.nodes.length}',
                'direct': '${model.directPeerCount}',
                'forwarded': '${model.forwardedPeerCount}',
              },
            ),
            style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _ConstellationPainter extends CustomPainter {
  final Map<String, Offset> positions;
  final List<MeshConstellationEdge> edges;
  final ColorScheme colorScheme;

  const _ConstellationPainter({
    required this.positions,
    required this.edges,
    required this.colorScheme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final starPaint =
        Paint()..color = colorScheme.outlineVariant.withValues(alpha: .5);
    final seed = math.Random(47);
    for (var i = 0; i < 90; i++) {
      canvas.drawCircle(
        Offset(seed.nextDouble() * size.width, seed.nextDouble() * size.height),
        i % 11 == 0 ? 1.2 : .65,
        starPaint,
      );
    }

    for (final edge in edges) {
      final start = positions[edge.a];
      final end = positions[edge.b];
      if (start == null || end == null) continue;
      final paint =
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.6
            ..color = colorScheme.onSurfaceVariant.withValues(alpha: .52);
      if (edge.forwarded) {
        _drawDashedLine(canvas, start, end, paint);
      } else {
        canvas.drawLine(start, end, paint);
      }
    }
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    final distance = (end - start).distance;
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
  bool shouldRepaint(_ConstellationPainter oldDelegate) =>
      oldDelegate.positions != positions ||
      oldDelegate.edges != edges ||
      oldDelegate.colorScheme != colorScheme;
}
