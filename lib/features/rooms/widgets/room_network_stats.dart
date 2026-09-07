import 'package:enmesh/generated/locale_keys.g.dart';
import 'package:enmesh/shared/utils/network/node_utils.dart';
import 'package:enmesh/src/rust/api/simple.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class RoomNetworkStats {
  final int peerCount;
  final int directPeerCount;
  final int forwardedPeerCount;
  final double? medianLatencyMs;
  final double? medianRecentLoss;

  const RoomNetworkStats({
    required this.peerCount,
    required this.directPeerCount,
    required this.forwardedPeerCount,
    required this.medianLatencyMs,
    required this.medianRecentLoss,
  });

  factory RoomNetworkStats.fromNetwork(
    List<KVNodeInfo> nodes, {
    required String localIp,
  }) {
    final peers =
        nodes
            .where(
              (node) =>
                  node.ipv4 != localIp && node.cost > 0 && !isServerNode(node),
            )
            .toList();
    final latencies = [
      for (final peer in peers)
        if (peer.latencyMs.isFinite && peer.latencyMs > 0) peer.latencyMs,
    ];
    final losses = [
      for (final peer in peers)
        if (peer.lossRate.isFinite && peer.lossRate >= 0)
          peer.lossRate.toDouble(),
    ];

    return RoomNetworkStats(
      peerCount: peers.length,
      directPeerCount: peers.where((peer) => peer.cost == 1).length,
      forwardedPeerCount: peers.where((peer) => peer.cost >= 2).length,
      medianLatencyMs: _median(latencies),
      medianRecentLoss: _median(losses),
    );
  }
}

class RoomNetworkStatsPanel extends StatelessWidget {
  final RoomNetworkStats stats;

  const RoomNetworkStatsPanel({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final cells = [
      _NetworkStatCell(
        key: const ValueKey('room_stats_peers'),
        icon: Icons.people_alt_outlined,
        label: LocaleKeys.rooms_stats_peers.tr(),
        value: '${stats.peerCount}',
        caption: LocaleKeys.rooms_stats_direct_forwarded.tr(
          namedArgs: {
            'direct': '${stats.directPeerCount}',
            'forwarded': '${stats.forwardedPeerCount}',
          },
        ),
      ),
      _NetworkStatCell(
        key: const ValueKey('room_stats_latency'),
        icon: Icons.speed_rounded,
        label: LocaleKeys.rooms_stats_latency.tr(),
        value:
            stats.medianLatencyMs == null
                ? '—'
                : '${stats.medianLatencyMs!.round()} ms',
        caption: LocaleKeys.rooms_stats_peer_median.tr(),
      ),
      _NetworkStatCell(
        key: const ValueKey('room_stats_recent_loss'),
        icon: Icons.network_check_rounded,
        label: LocaleKeys.rooms_stats_recent_loss.tr(),
        value:
            stats.medianRecentLoss == null
                ? '—'
                : '${stats.medianRecentLoss!.toStringAsFixed(1)}%',
        caption: LocaleKeys.rooms_stats_peer_median.tr(),
      ),
    ];

    return SizedBox(
      height: 96,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 600;
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: compact ? 4 : 1, child: cells[0]),
                const SizedBox(width: 8),
                Expanded(flex: compact ? 3 : 1, child: cells[1]),
                const SizedBox(width: 8),
                Expanded(flex: compact ? 3 : 1, child: cells[2]),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _NetworkStatCell extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String caption;

  const _NetworkStatCell({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.caption,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Semantics(
      label: '$label: $value, $caption',
      container: true,
      excludeSemantics: true,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 180;
          final details = Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (compact) ...[
                    Icon(icon, size: 14, color: colorScheme.primary),
                    const SizedBox(width: 4),
                  ],
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 1),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              Text(
                caption,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          );
          return Container(
            constraints: const BoxConstraints(minHeight: 78),
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 9 : 12,
              vertical: 9,
            ),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            child:
                compact
                    ? details
                    : Row(
                      children: [
                        Icon(icon, size: 20, color: colorScheme.primary),
                        const SizedBox(width: 9),
                        Expanded(child: details),
                      ],
                    ),
          );
        },
      ),
    );
  }
}

double? _median(List<double> values) {
  if (values.isEmpty) return null;
  values.sort();
  final midpoint = values.length ~/ 2;
  if (values.length.isOdd) return values[midpoint];
  return (values[midpoint - 1] + values[midpoint]) / 2;
}
