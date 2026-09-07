import 'package:enmesh/features/rooms/widgets/nat_visual_style.dart';
import 'package:enmesh/features/rooms/widgets/peer_connection_style.dart';
import 'package:enmesh/core/ui/app_snack_bars.dart';
import 'package:enmesh/generated/locale_keys.g.dart';
import 'package:enmesh/shared/utils/platform_version_parser.dart';
import 'package:enmesh/src/rust/api/simple.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// 将列表项卡片抽取为独立的StatefulWidget
class MiniUserCard extends StatefulWidget {
  final KVNodeInfo player;
  final ColorScheme colorScheme;
  final String? localIPv4;

  const MiniUserCard({
    super.key,
    required this.player,
    required this.colorScheme,
    required this.localIPv4,
  });

  @override
  State<MiniUserCard> createState() => _MiniUserCardState();
}

class _MiniUserCardState extends State<MiniUserCard> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    final localIPv4 = widget.localIPv4 ?? '';
    final player = widget.player;
    final colorScheme = widget.colorScheme;
    final displayName =
        player.hostname.startsWith('PublicServer_')
            ? player.hostname.substring('PublicServer_'.length)
            : player.hostname;
    final connectionType = PeerConnectionStyle.mapConnectionType(
      player.cost,
      player.ipv4,
      localIPv4,
    );
    final connectionTypeColor = PeerConnectionStyle.getConnectionTypeColor(
      connectionType,
      colorScheme,
    );
    final latencyColor = PeerConnectionStyle.getLatencyColor(player.latencyMs);
    final lossColor = PeerConnectionStyle.getPacketLossColor(player.lossRate);
    final natStyle = NatVisualStyle.resolve(player.nat, colorScheme);

    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: isHovered ? colorScheme.primary : Colors.transparent,
            width: 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            // 复制IP地址到剪贴板
            Clipboard.setData(ClipboardData(text: player.ipv4));
            AppSnackBars.success(
              context,
              LocaleKeys.rooms_copied.tr(),
              LocaleKeys.rooms_ip_copied.tr(namedArgs: {'ip': player.ipv4}),
              duration: const Duration(seconds: 2),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 第一行：名称 类型 延迟 丢包
                Row(
                  children: [
                    Icon(Icons.person, color: colorScheme.primary, size: 18),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Tooltip(
                        message: displayName,
                        child: Text(
                          displayName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: null, // Plus用户高亮
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: connectionTypeColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        connectionType.tr(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    // 只有不是本机时才显示延迟和丢包
                    if (connectionType !=
                        LocaleKeys.rooms_connection_local) ...[
                      const SizedBox(width: 10),
                      Icon(Icons.timer_outlined, size: 16, color: latencyColor),
                      Text(
                        '${player.latencyMs.toStringAsFixed(0)}ms',
                        style: TextStyle(
                          color: latencyColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Icon(Icons.error_outline, size: 16, color: lossColor),
                      Text(
                        '${player.lossRate.toStringAsFixed(1)}%',
                        style: TextStyle(
                          color: lossColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                // 第二行：IP地址 ET版本 打洞难易
                Row(
                  children: [
                    if (player.ipv4 != '' && player.ipv4 != "0.0.0.0")
                      Icon(
                        Icons.lan_outlined,
                        size: 16,
                        color: colorScheme.primary,
                      ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Tooltip(
                        message: player.ipv4,
                        child: Text(
                          (player.ipv4 != '' && player.ipv4 != "0.0.0.0")
                              ? player.ipv4
                              : "",
                          style: TextStyle(
                            color: colorScheme.secondary,
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Icon(
                      PlatformVersionParser.getPlatformIcon(player.version),
                      size: 16,
                      color: colorScheme.primary,
                    ),
                    Text(
                      PlatformVersionParser.getVersionNumber(player.version),
                      style: TextStyle(
                        color: colorScheme.secondary,
                        fontSize: 13,
                      ),
                    ),
                    if (connectionType !=
                        LocaleKeys.rooms_connection_local) ...[
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: natStyle.background,
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(color: natStyle.border),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              natStyle.icon,
                              size: 14,
                              color: natStyle.foreground,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              natStyle.labelKey.tr(),
                              style: TextStyle(
                                color: natStyle.foreground,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (player.tunnelProto != '') ...[
                      const SizedBox(width: 10),
                      Icon(Icons.router, size: 16, color: colorScheme.primary),
                      Text(
                        PeerConnectionStyle.formatTunnelProto(
                          player.tunnelProto,
                        ),
                        style: TextStyle(
                          color: colorScheme.secondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
