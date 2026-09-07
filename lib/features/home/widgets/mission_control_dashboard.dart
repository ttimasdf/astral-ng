import 'package:enmesh/core/models/mission_control_preferences.dart';
import 'package:enmesh/core/models/room.dart';
import 'package:enmesh/core/states/connection_state.dart';
import 'package:enmesh/core/room/room_mode.dart';
import 'package:enmesh/features/home/widgets/connect_button.dart';
import 'package:enmesh/features/home/widgets/mission_connection_dialog.dart';
import 'package:enmesh/features/home/widgets/mission_mesh_preview.dart';
import 'package:enmesh/features/home/widgets/mission_quick_controls.dart';
import 'package:enmesh/generated/locale_keys.g.dart';
import 'package:enmesh/shared/utils/network/node_utils.dart';
import 'package:enmesh/shared/widgets/network/mesh_peer_badge.dart';
import 'package:enmesh/src/rust/api/simple.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class MissionControlDashboard extends StatelessWidget {
  final CoState connectionState;
  final KVNetworkStatus? networkStatus;
  final Room? room;
  final String username;
  final String virtualIp;
  final bool automaticIp;
  final bool encryptedTraffic;
  final bool reduceMotion;
  final MissionControlPreferences effectivePreferences;
  final MissionControlPreferences? activePreferences;

  const MissionControlDashboard({
    super.key,
    required this.connectionState,
    required this.networkStatus,
    required this.room,
    required this.username,
    required this.virtualIp,
    required this.automaticIp,
    required this.encryptedTraffic,
    required this.reduceMotion,
    required this.effectivePreferences,
    required this.activePreferences,
  });

  @override
  Widget build(BuildContext context) {
    final summary = _MissionSummary.fromStatus(networkStatus, virtualIp);

    return LayoutBuilder(
      builder: (context, constraints) {
        final desktop = constraints.maxWidth >= 840;
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            desktop ? 28 : 16,
            desktop ? 26 : 16,
            desktop ? 28 : 16,
            28 + MediaQuery.paddingOf(context).bottom,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1180),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (desktop)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 6,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _MissionHero(
                                connectionState: connectionState,
                                room: room,
                                username: username,
                                virtualIp: virtualIp,
                                automaticIp: automaticIp,
                                wide: true,
                              ),
                              const SizedBox(height: 18),
                              _MissionMeshCard(
                                summary: summary,
                                connectionState: connectionState,
                                networkStatus: networkStatus,
                                username: username,
                                virtualIp: virtualIp,
                                reduceMotion: reduceMotion,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          flex: 5,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              MissionQuickControls(
                                room: room,
                                connectionState: connectionState,
                                effective: effectivePreferences,
                                active: activePreferences,
                              ),
                              const SizedBox(height: 18),
                              _SessionCard(
                                room: room,
                                username: username,
                                virtualIp: virtualIp,
                                automaticIp: automaticIp,
                                encryptedTraffic: encryptedTraffic,
                                connectionState: connectionState,
                                summary: summary,
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  else ...[
                    _MissionHero(
                      connectionState: connectionState,
                      room: room,
                      username: username,
                      virtualIp: virtualIp,
                      automaticIp: automaticIp,
                      wide: false,
                    ),
                    const SizedBox(height: 18),
                    MissionQuickControls(
                      room: room,
                      connectionState: connectionState,
                      effective: effectivePreferences,
                      active: activePreferences,
                    ),
                    const SizedBox(height: 18),
                    _MissionMeshCard(
                      summary: summary,
                      connectionState: connectionState,
                      networkStatus: networkStatus,
                      username: username,
                      virtualIp: virtualIp,
                      reduceMotion: reduceMotion,
                    ),
                    const SizedBox(height: 18),
                    _SessionCard(
                      room: room,
                      username: username,
                      virtualIp: virtualIp,
                      automaticIp: automaticIp,
                      encryptedTraffic: encryptedTraffic,
                      connectionState: connectionState,
                      summary: summary,
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MissionHero extends StatelessWidget {
  final CoState connectionState;
  final Room? room;
  final String username;
  final String virtualIp;
  final bool automaticIp;
  final bool wide;

  const _MissionHero({
    required this.connectionState,
    required this.room,
    required this.username,
    required this.virtualIp,
    required this.automaticIp,
    required this.wide,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final statusColor = switch (connectionState) {
      CoState.idle => colorScheme.primary,
      CoState.connecting => colorScheme.tertiary,
      CoState.connected => const Color(0xff19a974),
    };
    final title = switch (connectionState) {
      CoState.idle =>
        room == null
            ? LocaleKeys.mission_needs_room.tr()
            : LocaleKeys.mission_ready_title.tr(),
      CoState.connecting => LocaleKeys.mission_connecting_title.tr(),
      CoState.connected => LocaleKeys.mission_connected_title.tr(),
    };
    final subtitle = switch (connectionState) {
      CoState.idle =>
        room == null
            ? LocaleKeys.mission_needs_room_desc.tr()
            : LocaleKeys.mission_ready_desc.tr(),
      CoState.connecting => LocaleKeys.mission_connecting_desc.tr(),
      CoState.connected => LocaleKeys.mission_connected_desc.tr(
        namedArgs: {'room': room?.name ?? '—'},
      ),
    };

    final content = Padding(
      padding: EdgeInsets.all(wide ? 28 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _StatusBeacon(
                color: statusColor,
                active: connectionState != CoState.idle,
              ),
              const SizedBox(width: 9),
              Text(
                _statusLabel(connectionState),
                style: TextStyle(
                  color: statusColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -.8,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoPill(
                icon: Icons.hub_outlined,
                label: room?.name ?? LocaleKeys.select_room.tr(),
              ),
              _InfoPill(
                leading: MeshPeerBadge(
                  username: username,
                  ip: virtualIp,
                  size: 20,
                  framed: false,
                ),
                label: username,
              ),
              _InfoPill(
                icon: Icons.lan_outlined,
                label:
                    automaticIp
                        ? LocaleKeys.mission_ip_automatic.tr()
                        : virtualIp.isEmpty
                        ? '—'
                        : virtualIp,
              ),
            ],
          ),
          const SizedBox(height: 22),
          LayoutBuilder(
            builder: (context, constraints) {
              final showFullEditLabel = wide;
              final showShortEditLabel = wide || constraints.maxWidth >= 274;
              final editButton =
                  showShortEditLabel
                      ? OutlinedButton.icon(
                        onPressed:
                            connectionState == CoState.idle
                                ? () => MissionConnectionDialog.show(context)
                                : null,
                        icon: const Icon(Icons.edit_outlined),
                        label: Text(
                          showFullEditLabel
                              ? LocaleKeys.mission_edit_setup.tr()
                              : LocaleKeys.mission_edit_short.tr(),
                        ),
                        style: OutlinedButton.styleFrom(
                          minimumSize: Size(showFullEditLabel ? 150 : 88, 52),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      )
                      : Tooltip(
                        message: LocaleKeys.mission_edit_setup.tr(),
                        child: IconButton(
                          onPressed:
                              connectionState == CoState.idle
                                  ? () => MissionConnectionDialog.show(context)
                                  : null,
                          icon: const Icon(Icons.edit_outlined),
                          constraints: const BoxConstraints.tightFor(
                            width: 52,
                            height: 52,
                          ),
                          style: IconButton.styleFrom(
                            side: BorderSide(color: colorScheme.outline),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      );

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (connectionState == CoState.connecting) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        minHeight: 3,
                        color: colorScheme.tertiary,
                        backgroundColor: colorScheme.surfaceContainerHighest,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  Row(
                    children: [
                      editButton,
                      const SizedBox(width: 10),
                      const Expanded(
                        child: ConnectButton(
                          expanded: true,
                          showProgress: false,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: .08),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _HeroGridPainter(
                  colorScheme.outlineVariant.withValues(alpha: .25),
                ),
              ),
            ),
            content,
          ],
        ),
      ),
    );
  }

  String _statusLabel(CoState state) => switch (state) {
    CoState.idle => LocaleKeys.mission_standing_by.tr().toUpperCase(),
    CoState.connecting => LocaleKeys.mission_connecting.tr().toUpperCase(),
    CoState.connected => LocaleKeys.mission_mesh_online.tr().toUpperCase(),
  };
}

class _MissionMeshCard extends StatelessWidget {
  final _MissionSummary summary;
  final CoState connectionState;
  final KVNetworkStatus? networkStatus;
  final String username;
  final String virtualIp;
  final bool reduceMotion;

  const _MissionMeshCard({
    required this.summary,
    required this.connectionState,
    required this.networkStatus,
    required this.username,
    required this.virtualIp,
    required this.reduceMotion,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: colorScheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: SizedBox(
        height: 292,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Stack(
            children: [
              Positioned.fill(
                child: MissionMeshPreview(
                  nodes: networkStatus?.nodes ?? const [],
                  username: username,
                  localIp: virtualIp,
                  connected: connectionState == CoState.connected,
                  connecting: connectionState == CoState.connecting,
                  reduceMotion: reduceMotion,
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: _HeroMetrics(summary: summary, state: connectionState),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroMetrics extends StatelessWidget {
  final _MissionSummary summary;
  final CoState state;

  const _HeroMetrics({required this.summary, required this.state});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final connected = state == CoState.connected;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: .88),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Expanded(
            child: _Metric(
              label: LocaleKeys.mission_peers.tr(),
              value: connected ? '${summary.peerCount}' : '—',
            ),
          ),
          _MetricDivider(color: colorScheme.outlineVariant),
          Expanded(
            child: _Metric(
              label: LocaleKeys.mission_direct.tr(),
              value: connected ? '${summary.directCount}' : '—',
            ),
          ),
          _MetricDivider(color: colorScheme.outlineVariant),
          Expanded(
            child: _Metric(
              label: LocaleKeys.mission_forwarded.tr(),
              value: connected ? '${summary.forwardedCount}' : '—',
            ),
          ),
          _MetricDivider(color: colorScheme.outlineVariant),
          Expanded(
            child: _Metric(
              label: LocaleKeys.mission_latency.tr(),
              value:
                  connected && summary.averageLatency != null
                      ? '${summary.averageLatency} ms'
                      : '—',
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  final Room? room;
  final String username;
  final String virtualIp;
  final bool automaticIp;
  final bool encryptedTraffic;
  final CoState connectionState;
  final _MissionSummary summary;

  const _SessionCard({
    required this.room,
    required this.username,
    required this.virtualIp,
    required this.automaticIp,
    required this.encryptedTraffic,
    required this.connectionState,
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              LocaleKeys.mission_session_details.tr(),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 18),
            _DetailRow(
              icon: Icons.meeting_room_outlined,
              label: LocaleKeys.select_room.tr(),
              value: room?.name ?? '—',
            ),
            _DetailRow(
              icon:
                  room?.simpleMode == true
                      ? Icons.auto_awesome_outlined
                      : Icons.tune_rounded,
              label: LocaleKeys.room_mode.tr(),
              value: room == null ? '—' : RoomMode.label(room!.simpleMode),
            ),
            _DetailRow(
              leading: MeshPeerBadge(
                username: username,
                ip: virtualIp,
                size: 22,
                framed: false,
              ),
              label: LocaleKeys.username.tr(),
              value: username,
            ),
            _DetailRow(
              icon: Icons.lan_outlined,
              label: LocaleKeys.virtual_network_ip.tr(),
              value:
                  automaticIp
                      ? LocaleKeys.mission_ip_automatic.tr()
                      : virtualIp.isEmpty
                      ? '—'
                      : virtualIp,
            ),
            _DetailRow(
              icon: encryptedTraffic ? Icons.lock_outline : Icons.lock_open,
              label: LocaleKeys.mission_transport_security.tr(),
              value:
                  encryptedTraffic
                      ? LocaleKeys.mission_encrypted.tr()
                      : LocaleKeys.mission_not_encrypted.tr(),
              valueColor:
                  encryptedTraffic
                      ? const Color(0xff158765)
                      : colorScheme.error,
            ),
            if (connectionState == CoState.connected)
              _DetailRow(
                icon: Icons.swap_vert_rounded,
                label: LocaleKeys.mission_session_traffic.tr(),
                value: _formatBytes(summary.totalTraffic),
              ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData? icon;
  final Widget? leading;
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow({
    this.icon,
    this.leading,
    required this.label,
    required this.value,
    this.valueColor,
  }) : assert(icon != null || leading != null);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          leading ?? Icon(icon, size: 18, color: colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: valueColor ?? colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData? icon;
  final Widget? leading;
  final String label;

  const _InfoPill({this.icon, this.leading, required this.label})
    : assert(icon != null || leading != null);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          leading ?? Icon(icon, size: 15, color: colorScheme.primary),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}

class _StatusBeacon extends StatelessWidget {
  final Color color;
  final bool active;

  const _StatusBeacon({required this.color, required this.active});

  @override
  Widget build(BuildContext context) => Container(
    width: 10,
    height: 10,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: color,
      boxShadow:
          active
              ? [BoxShadow(color: color.withValues(alpha: .4), blurRadius: 9)]
              : null,
    ),
  );
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;

  const _Metric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 7),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 8,
              fontWeight: FontWeight.w700,
              letterSpacing: .6,
            ),
          ),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _MetricDivider extends StatelessWidget {
  final Color color;

  const _MetricDivider({required this.color});

  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 30, color: color);
}

class _HeroGridPainter extends CustomPainter {
  final Color color;

  const _HeroGridPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    const spacing = 28.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), .7, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_HeroGridPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _MissionSummary {
  final int peerCount;
  final int directCount;
  final int forwardedCount;
  final int? averageLatency;
  final BigInt totalTraffic;

  const _MissionSummary({
    required this.peerCount,
    required this.directCount,
    required this.forwardedCount,
    required this.averageLatency,
    required this.totalTraffic,
  });

  factory _MissionSummary.fromStatus(KVNetworkStatus? status, String localIp) {
    if (status == null) {
      return _MissionSummary(
        peerCount: 0,
        directCount: 0,
        forwardedCount: 0,
        averageLatency: null,
        totalTraffic: BigInt.zero,
      );
    }

    final peers =
        status.nodes.where((node) {
          final isLocal = localIp.isNotEmpty && node.ipv4 == localIp;
          return !isLocal && !isServerNode(node);
        }).toList();
    final direct = peers.where((node) => node.cost == 1).length;
    final forwarded = peers.where((node) => node.cost >= 2).length;
    final measured = peers.where((node) => node.latencyMs > 0).toList();
    final latency =
        measured.isEmpty
            ? null
            : (measured.fold<double>(0, (sum, node) => sum + node.latencyMs) /
                    measured.length)
                .round();
    final traffic = peers.fold<BigInt>(
      BigInt.zero,
      (sum, node) => sum + node.rxBytes + node.txBytes,
    );

    return _MissionSummary(
      peerCount: peers.length,
      directCount: direct,
      forwardedCount: forwarded,
      averageLatency: latency,
      totalTraffic: traffic,
    );
  }
}

String _formatBytes(BigInt bytes) {
  const units = ['B', 'KB', 'MB', 'GB', 'TB'];
  var value = bytes.toDouble();
  var unit = 0;
  while (value >= 1024 && unit < units.length - 1) {
    value /= 1024;
    unit++;
  }
  final digits = value >= 100 || unit == 0 ? 0 : 1;
  return '${value.toStringAsFixed(digits)} ${units[unit]}';
}
