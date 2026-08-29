import 'package:enmesh/features/rooms/widgets/peer_connection_style.dart';
import 'package:enmesh/features/rooms/widgets/player_card_stats.dart';
import 'package:enmesh/generated/locale_keys.g.dart';
import 'package:enmesh/shared/utils/platform_version_parser.dart';
import 'package:enmesh/src/rust/api/simple.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Body sections for [AllUserCardTile].
class AllUserCardBody {
  const AllUserCardBody._();

  static Widget buildConnectionStatsSection(
    KVNodeInfo player,
    ColorScheme colorScheme,
  ) {
    if (player.connections.isEmpty) {
      return Center(
        child: Text(
          LocaleKeys.rooms_no_connection_data.tr(),
          style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.6)),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.wifi, size: 20, color: colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              '${LocaleKeys.rooms_network_data.tr()}:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 90,
          child: PlayerCardStats.buildConnectionStats(
            // Always display the first connection
            player.connections[0],
            colorScheme,
          ),
        ),
      ],
    );
  }

  static Widget buildDetailsSection({
    required BuildContext context,
    required KVNodeInfo player,
    required ColorScheme colorScheme,
    required String natTypeString,
    required Color natTypeColor,
    required IconData natTypeIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (player.ipv4 != '' && player.ipv4 != "0.0.0.0")
          PlayerCardStats.buildInfoRow(
            context,
            Icons.lan_outlined,
            LocaleKeys.rooms_ip_address.tr(),
            player.ipv4,
            colorScheme,
            showCopyButton: true,
          ),
        const SizedBox(height: 8),
        PlayerCardStats.buildInfoRow(
          context,
          PlatformVersionParser.getPlatformIcon(player.version),
          LocaleKeys.rooms_easytier_version.tr(),
          PlatformVersionParser.getVersionNumber(player.version),
          colorScheme,
        ),
        const SizedBox(height: 8),
        PlayerCardStats.buildInfoRow(
          context,
          natTypeIcon,
          LocaleKeys.rooms_nat_type.tr(),
          natTypeString,
          colorScheme,
          valueColor: natTypeColor,
        ),
        if (player.tunnelProto != '') ...[
          const SizedBox(height: 8),
          PlayerCardStats.buildInfoRow(
            context,
            Icons.router,
            LocaleKeys.rooms_tunnel_type.tr(),
            PeerConnectionStyle.formatTunnelProto(player.tunnelProto),
            colorScheme,
          ),
        ],
        if (player.hops.isNotEmpty) ...[
          const SizedBox(height: 8),
          buildHopsInfo(player.hops, colorScheme),
        ],
      ],
    );
  }

  static Widget buildHopsInfo(
    List<NodeHopStats> hops,
    ColorScheme colorScheme,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.route, size: 20, color: colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${LocaleKeys.rooms_connection_path.tr()}:',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              // 改为每行显示一个跃点
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (int i = 0; i < hops.length; i++) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${hops[i].nodeName} '
                        '(${hops[i].latencyMs.toStringAsFixed(0)}ms, '
                        '${hops[i].packetLoss.toStringAsFixed(1)}%)',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                    // 在跃点之间添加间距
                    if (i < hops.length - 1) const SizedBox(height: 4),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
