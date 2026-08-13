import 'package:astral/generated/locale_keys.g.dart';
import 'package:flutter/material.dart';

/// 节点连接展示共用样式（All / Mini 用户卡共用）
class PeerConnectionStyle {
  const PeerConnectionStyle._();

  static String formatTunnelProto(String proto) {
    return proto
        .split(',')
        .map((p) {
          final trimmed = p.trim();
          if (RegExp(r'^tcp$').hasMatch(trimmed)) return 'tcp4';
          if (RegExp(r'^udp$').hasMatch(trimmed)) return 'udp4';
          return trimmed;
        })
        .join(',');
  }

  static Color getConnectionTypeColor(
    String connectionType,
    ColorScheme colorScheme,
  ) {
    return switch (connectionType) {
      LocaleKeys.rooms_connection_server => Colors.deepPurple,
      LocaleKeys.rooms_connection_direct => Colors.green,
      LocaleKeys.rooms_connection_relay => Colors.orange,
      LocaleKeys.rooms_connection_local => colorScheme.primary,
      _ => Colors.grey,
    };
  }

  static String mapConnectionType(int connType, String ip, String thisip) {
    if (ip == '0.0.0.0') return LocaleKeys.rooms_connection_server;
    if (thisip.isNotEmpty && ip == thisip) {
      return LocaleKeys.rooms_connection_local;
    }
    if (connType == 1) return LocaleKeys.rooms_connection_direct;
    if (connType >= 2) return LocaleKeys.rooms_connection_relay;
    return LocaleKeys.rooms_connection_unknown;
  }

  static IconData getConnectionIcon(String connectionType) {
    return switch (connectionType) {
      LocaleKeys.rooms_connection_server => Icons.dns,
      LocaleKeys.rooms_connection_direct => Icons.link,
      LocaleKeys.rooms_connection_relay => Icons.swap_horiz,
      LocaleKeys.rooms_connection_local => Icons.computer,
      _ => Icons.device_unknown,
    };
  }

  static Color getLatencyColor(double latency) {
    if (latency < 50) return Colors.green;
    if (latency < 100) return Colors.orange;
    return Colors.red;
  }

  static Color getPacketLossColor(double lossRate) {
    if (lossRate < 1.0) return Colors.green;
    if (lossRate < 5.0) return Colors.orange;
    return Colors.red;
  }
}
