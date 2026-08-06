import 'dart:math' as math;

import 'package:astral/features/rooms/widgets/mesh_constellation_model.dart';
import 'package:astral/features/rooms/widgets/peer_connection_style.dart';
import 'package:astral/src/rust/api/simple.dart';
import 'package:astral/generated/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// A stable, non-hierarchical view of routes observed by this device.
class MeshConstellation extends StatelessWidget {
  final List<KVNodeInfo> nodes;
  final String localIp;

  const MeshConstellation({
    super.key,
    required this.nodes,
    required this.localIp,
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
                  child: CustomPaint(
                    painter: _ConstellationPainter(
                      positions: positions,
                      edges: model.edges,
                      colorScheme: colorScheme,
                    ),
                  ),
                ),
                for (final node in model.nodes)
                  if (positions[node.id] case final position?)
                    Positioned(
                      left: position.dx - (dense ? 24 : 31),
                      top: position.dy - (dense ? 24 : 31),
                      child: _ConstellationNode(
                        node: node,
                        dense: dense,
                        onTap: () => _showNodeDetails(context, node),
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
      builder:
          (context) => SafeArea(
            child: Padding(
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
                                  : node.isTransit
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
                  if (node.ip.isNotEmpty)
                    _Detail(
                      icon: Icons.lan_outlined,
                      label: LocaleKeys.virtual_network_ip.tr(),
                      value: node.ip,
                    ),
                  if (!node.isLocal && node.latencyMs > 0)
                    _Detail(
                      icon: Icons.speed_rounded,
                      label: LocaleKeys.mission_latency.tr(),
                      value: '${node.latencyMs.round()} ms',
                    ),
                  if (!node.isLocal)
                    _Detail(
                      icon: Icons.network_check_rounded,
                      label: LocaleKeys.rooms_packet_loss.tr(),
                      value: '${node.lossRate.toStringAsFixed(1)}%',
                    ),
                  if (node.tunnelProtocol.isNotEmpty)
                    _Detail(
                      icon: Icons.route_outlined,
                      label: LocaleKeys.rooms_transport.tr(),
                      value: PeerConnectionStyle.formatTunnelProto(
                        node.tunnelProtocol,
                      ),
                    ),
                  if (node.nat.isNotEmpty)
                    _Detail(
                      icon: Icons.router_outlined,
                      label: LocaleKeys.rooms_nat.tr(),
                      value: node.nat,
                    ),
                ],
              ),
            ),
          ),
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
          '${node.name}, ${node.isLocal ? LocaleKeys.rooms_this_device.tr() : LocaleKeys.rooms_mesh_peer.tr()}',
      child: Tooltip(
        message: node.ip.isEmpty ? node.name : '${node.name}\n${node.ip}',
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
            : node.isTransit
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
      child: Icon(
        node.isLocal
            ? Icons.my_location_rounded
            : node.isTransit
            ? Icons.alt_route_rounded
            : Icons.circle,
        size: node.isTransit ? size * .36 : size * .28,
        color: color,
      ),
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
      final color = edge.forwarded ? colorScheme.tertiary : colorScheme.primary;
      final paint =
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = edge.forwarded ? 1.25 : 1.7
            ..color = color.withValues(alpha: .52);
      canvas.drawLine(start, end, paint);

      final midpoint = Offset.lerp(start, end, .5)!;
      canvas.drawCircle(
        midpoint,
        2,
        Paint()..color = color.withValues(alpha: .85),
      );
    }
  }

  @override
  bool shouldRepaint(_ConstellationPainter oldDelegate) =>
      oldDelegate.positions != positions ||
      oldDelegate.edges != edges ||
      oldDelegate.colorScheme != colorScheme;
}

class _Detail extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _Detail({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Icon(icon, size: 18, color: colorScheme.primary),
          const SizedBox(width: 10),
          Text(label, style: TextStyle(color: colorScheme.onSurfaceVariant)),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
