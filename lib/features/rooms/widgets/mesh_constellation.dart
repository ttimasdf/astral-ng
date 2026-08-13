import 'dart:math' as math;

import 'package:astral/features/rooms/widgets/mesh_constellation_model.dart';
import 'package:astral/features/rooms/widgets/peer_connection_style.dart';
import 'package:astral/generated/locale_keys.g.dart';
import 'package:astral/shared/widgets/network/mesh_peer_badge.dart';
import 'package:astral/src/rust/api/simple.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:graphview/GraphView.dart' as gv;

Offset meshConstellationAxisScale(Size canvasSize) =>
    canvasSize.width < 600 ? const Offset(.92, 1.18) : const Offset(1.18, .88);

/// A force-directed view of routes observed by this device.
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
        final compact = constraints.maxWidth < 600;
        final dense = model.nodes.length > 12;
        return ClipRect(
          child: Material(
            color: colorScheme.surface,
            child: Stack(
              children: [
                const Positioned.fill(child: _StarField()),
                Positioned.fill(
                  child: _ConstellationGraphScene(
                    model: model,
                    dense: dense,
                    reduceMotion: reduceMotion,
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

class _ConstellationGraphScene extends StatefulWidget {
  final MeshConstellationModel model;
  final bool dense;
  final bool reduceMotion;
  final ValueChanged<MeshConstellationNode> onNodeTap;

  const _ConstellationGraphScene({
    required this.model,
    required this.dense,
    required this.reduceMotion,
    required this.onNodeTap,
  });

  @override
  State<_ConstellationGraphScene> createState() =>
      _ConstellationGraphSceneState();
}

class _ConstellationGraphSceneState extends State<_ConstellationGraphScene>
    with WidgetsBindingObserver {
  late final TransformationController _transformationController;
  final _graphNodes = <String, gv.Node>{};
  final _latestNodes = <String, MeshConstellationNode>{};
  late gv.Graph _graph;
  late _StableFruchtermanReingoldAlgorithm _algorithm;
  late Widget _graphView;
  late String _topology;
  bool _appVisible = true;
  bool _needsFrame = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _transformationController = TransformationController();
    _algorithm = _StableFruchtermanReingoldAlgorithm(
      gv.FruchtermanReingoldConfiguration(
        iterations: 180,
        repulsionRate: .46,
        attractionRate: .08,
        repulsionPercentage: .7,
        lerpFactor: .08,
        movementThreshold: .35,
        shuffleNodes: false,
      ),
    );
    _topology = _topologyFingerprint(widget.model);
    _graph = _buildGraph(widget.model);
    _graphView = _buildGraphView();
  }

  @override
  void didUpdateWidget(_ConstellationGraphScene oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncLatestNodes(widget.model);
    final nextTopology = _topologyFingerprint(widget.model);
    if (nextTopology == _topology) return;
    _topology = nextTopology;
    _graph = _buildGraph(widget.model);
    _graphView = _buildGraphView();
    _needsFrame = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _frameConstellation();
    });
  }

  gv.Graph _buildGraph(MeshConstellationModel model) {
    final activeIds = model.nodes.map((node) => node.id).toSet();
    _graphNodes.removeWhere((id, _) => !activeIds.contains(id));
    _syncLatestNodes(model);

    final local = model.nodes.where((node) => node.isLocal).firstOrNull;
    if (local != null) {
      _graphNodes.putIfAbsent(local.id, () {
        final node = gv.Node.Id(local.id);
        node.position = const Offset(400, 300);
        return node;
      });
    }

    for (final modelNode in model.nodes.where((node) => !node.isLocal)) {
      _graphNodes.putIfAbsent(modelNode.id, () {
        final node = gv.Node.Id(modelNode.id);
        node.position = _seedPosition(modelNode.id, model);
        return node;
      });
    }

    final graph = gv.Graph();
    graph.addNodes([
      for (final modelNode in model.nodes) _graphNodes[modelNode.id]!,
    ]);
    for (final edge in model.edges) {
      graph.addEdgeS(
        gv.Edge(
          _graphNodes[edge.a]!,
          _graphNodes[edge.b]!,
          key: ValueKey(edge.key),
        ),
      );
    }
    return graph;
  }

  void _syncLatestNodes(MeshConstellationModel model) {
    _latestNodes
      ..clear()
      ..addEntries(model.nodes.map((node) => MapEntry(node.id, node)));
  }

  Offset _seedPosition(String id, MeshConstellationModel model) {
    for (final edge in model.edges) {
      final neighborId =
          edge.a == id
              ? edge.b
              : edge.b == id
              ? edge.a
              : null;
      final neighbor = neighborId == null ? null : _graphNodes[neighborId];
      if (neighbor != null) {
        final angle = _stableHash(id) % 360 * math.pi / 180;
        return neighbor.position +
            Offset(math.cos(angle), math.sin(angle)) * 36;
      }
    }

    final hash = _stableHash(id);
    final angle = hash % 360 * math.pi / 180;
    final radius = 150.0 + hash % 90;
    return const Offset(400, 300) +
        Offset(math.cos(angle), math.sin(angle)) * radius;
  }

  void _frameConstellation() {
    final local = widget.model.nodes.where((node) => node.isLocal).firstOrNull;
    final localNode = local == null ? null : _graphNodes[local.id];
    final renderBox = context.findRenderObject() as RenderBox?;
    if (localNode == null || renderBox == null || !renderBox.hasSize) return;

    final viewport = renderBox.size;
    final bounds = _graph.calculateGraphBounds();
    final localCenter =
        localNode.position + Offset(localNode.width / 2, localNode.height / 2);
    final horizontalExtent = math.max(
      (localCenter.dx - bounds.left).abs(),
      (bounds.right - localCenter.dx).abs(),
    );
    final verticalExtent = math.max(
      (localCenter.dy - bounds.top).abs(),
      (bounds.bottom - localCenter.dy).abs(),
    );
    final scaleX =
        horizontalExtent == 0
            ? 1.0
            : viewport.width * .82 / (horizontalExtent * 2);
    final scaleY =
        verticalExtent == 0
            ? 1.0
            : viewport.height * .82 / (verticalExtent * 2);
    final scale = math.min(1.0, math.min(scaleX, scaleY)).clamp(.55, 1.0);
    final translation = viewport.center(Offset.zero) - localCenter * scale;
    _transformationController.value =
        Matrix4.identity()
          ..translateByDouble(translation.dx, translation.dy, 0, 1)
          ..scaleByDouble(scale, scale, 1, 1);
  }

  Widget _buildGraphView() => gv.GraphView(
    key: ValueKey(_topology),
    graph: _graph,
    algorithm: _algorithm,
    animated: !widget.reduceMotion,
    toggleAnimationDuration:
        widget.reduceMotion ? Duration.zero : const Duration(milliseconds: 260),
    builder: (graphNode) {
      final id = graphNode.key?.value as String?;
      final node = id == null ? null : _latestNodes[id];
      if (node == null) return const SizedBox.shrink();
      return _ConstellationNode(
        key: ValueKey(node.id),
        node: node,
        dense: widget.dense,
        onTap: () => widget.onNodeTap(_latestNodes[node.id] ?? node),
      );
    },
  );

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final visible = state == AppLifecycleState.resumed;
    if (_appVisible == visible) return;
    setState(() => _appVisible = visible);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    _algorithm.renderer = _ObservedRouteRenderer(
      forwardedByEdge: {
        for (final edge in widget.model.edges) edge.key: edge.forwarded,
      },
      color: colorScheme.onSurfaceVariant.withValues(alpha: .56),
    );

    return TickerMode(
      enabled: _appVisible,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final canvasSize = constraints.biggest;
          final glyphSize = widget.dense ? 36.0 : 42.0;
          final vertical = canvasSize.width < 600;
          final preferredLength = glyphSize * (vertical ? 3.25 : 4.1);
          final primaryExtent = vertical ? canvasSize.height : canvasSize.width;
          final availableLength = primaryExtent * (vertical ? .22 : .18);
          _algorithm
            ..targetEdgeLength = math.min(preferredLength, availableLength)
            ..canvasSize = canvasSize
            ..vertical = vertical
            ..anchorNodeId =
                widget.model.nodes
                    .where((node) => node.isLocal)
                    .firstOrNull
                    ?.id;
          if (_needsFrame) {
            _needsFrame = false;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _frameConstellation();
            });
          }
          return InteractiveViewer(
            transformationController: _transformationController,
            constrained: false,
            boundaryMargin: EdgeInsets.zero,
            minScale: .55,
            maxScale: 1.8,
            panEnabled: _appVisible,
            scaleEnabled: _appVisible,
            child: SizedBox(
              width: canvasSize.width,
              height: canvasSize.height,
              child: RepaintBoundary(child: _graphView),
            ),
          );
        },
      ),
    );
  }
}

class _StableFruchtermanReingoldAlgorithm
    extends gv.FruchtermanReingoldAlgorithm {
  double targetEdgeLength = 150;
  Size canvasSize = const Size(800, 600);
  bool vertical = false;
  String? anchorNodeId;

  _StableFruchtermanReingoldAlgorithm(super.configuration);

  @override
  Size run(gv.Graph? graph, double shiftX, double shiftY) {
    if (graph == null || graph.nodes.isEmpty) return Size.zero;
    init(graph);
    super.run(graph, 0, 0);
    _normalizeSpacing(graph);
    return canvasSize;
  }

  void _normalizeSpacing(gv.Graph graph) {
    final lengths =
        graph.edges
            .map(
              (edge) =>
                  (_nodeCenter(edge.source) - _nodeCenter(edge.destination))
                      .distance,
            )
            .where((length) => length > 0)
            .toList()
          ..sort();
    final median =
        lengths.isEmpty ? targetEdgeLength : lengths[lengths.length ~/ 2];
    final scale = (targetEdgeLength / median).clamp(.45, 1.8);
    final axisScale = meshConstellationAxisScale(canvasSize);
    final anchor = _graphCenter(graph);
    for (final node in graph.nodes) {
      final delta = _nodeCenter(node) - anchor;
      final normalizedCenter =
          anchor +
          Offset(
            delta.dx * scale * axisScale.dx,
            delta.dy * scale * axisScale.dy,
          );
      node.position =
          normalizedCenter - Offset(node.width / 2, node.height / 2);
    }

    final bounds = graph.calculateGraphBounds();
    final translation = canvasSize.center(Offset.zero) - bounds.center;
    for (final node in graph.nodes) {
      node.position += translation;
    }
  }

  Offset _nodeCenter(gv.Node node) =>
      node.position + Offset(node.width / 2, node.height / 2);

  Offset _graphCenter(gv.Graph graph) {
    final anchor =
        graph.nodes
            .where((node) => node.key?.value == anchorNodeId)
            .firstOrNull;
    return anchor == null
        ? graph.calculateGraphBounds().center
        : _nodeCenter(anchor);
  }
}

class _ObservedRouteRenderer extends gv.EdgeRenderer {
  final Map<String, bool> forwardedByEdge;
  final Color color;

  _ObservedRouteRenderer({required this.forwardedByEdge, required this.color});

  @override
  void renderEdge(Canvas canvas, gv.Edge edge, Paint paint) {
    final start = getNodeCenter(edge.source);
    final end = getNodeCenter(edge.destination);
    final routePaint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..strokeCap = StrokeCap.round
          ..color = color;
    final key =
        edge.key is ValueKey ? (edge.key as ValueKey).value as String : '';
    if (forwardedByEdge[key] == true) {
      drawDashedLine(canvas, start, end, routePaint, .58);
    } else {
      canvas.drawLine(start, end, routePaint);
    }
  }
}

class _ConstellationNode extends StatelessWidget {
  final MeshConstellationNode node;
  final bool dense;
  final VoidCallback onTap;

  const _ConstellationNode({
    super.key,
    required this.node,
    required this.dense,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final glyphSize = dense ? 36.0 : 42.0;
    final width = dense ? 104.0 : 120.0;
    return Semantics(
      button: true,
      label:
          '${node.name}, ${node.isLocal
              ? LocaleKeys.rooms_this_device.tr()
              : node.isRelay
              ? LocaleKeys.rooms_forwarding_peer.tr()
              : LocaleKeys.rooms_mesh_peer.tr()}',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: width,
          height: dense ? 62 : 70,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _NodeGlyph(node: node, size: glyphSize),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  node.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: dense ? 9 : 10,
                    fontWeight:
                        node.isLocal ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ),
            ],
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
    if (!node.isRelay) {
      return MeshPeerBadge(
        username: node.name,
        ip: node.ip,
        size: size,
        isLocal: node.isLocal,
      );
    }

    return Container(
      width: size * 1.16,
      height: size * .82,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          colorScheme.tertiary.withValues(alpha: .16),
          colorScheme.surface,
        ),
        border: Border.all(color: colorScheme.tertiary, width: 1.4),
        borderRadius: BorderRadius.circular(size * .2),
      ),
      child: Icon(
        Icons.dns_rounded,
        size: size * .48,
        color: colorScheme.tertiary,
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
    return IgnorePointer(
      child: Container(
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
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StarField extends StatelessWidget {
  const _StarField();

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _StarFieldPainter(Theme.of(context).colorScheme.outlineVariant),
  );
}

class _StarFieldPainter extends CustomPainter {
  final Color color;

  const _StarFieldPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color.withValues(alpha: .5);
    final seed = math.Random(47);
    for (var i = 0; i < 90; i++) {
      canvas.drawCircle(
        Offset(seed.nextDouble() * size.width, seed.nextDouble() * size.height),
        i % 11 == 0 ? 1.2 : .65,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_StarFieldPainter oldDelegate) =>
      oldDelegate.color != color;
}

String _topologyFingerprint(MeshConstellationModel model) {
  final nodes =
      model.nodes
          .map(
            (node) =>
                '${node.id}:${node.name}:${node.emoji}:${node.isLocal}:${node.isRelay}',
          )
          .toList()
        ..sort();
  final edges =
      model.edges.map((edge) => '${edge.key}:${edge.forwarded}').toList()
        ..sort();
  return '${nodes.join(',')}|${edges.join(',')}';
}

int _stableHash(String source) {
  var hash = 2166136261;
  for (final unit in source.codeUnits) {
    hash ^= unit;
    hash = (hash * 16777619) & 0x7fffffff;
  }
  return hash;
}
