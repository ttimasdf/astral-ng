import 'dart:async';
import 'dart:io';

import 'package:astral/core/models/mission_control_preferences.dart';
import 'package:astral/core/models/room.dart';
import 'package:astral/core/services/service_manager.dart';
import 'package:astral/core/states/connection_state.dart';
import 'package:astral/core/ui/main_tab.dart';
import 'package:astral/generated/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class MissionQuickControls extends StatelessWidget {
  final Room? room;
  final CoState connectionState;
  final MissionControlPreferences effective;
  final MissionControlPreferences? active;

  const MissionQuickControls({
    super.key,
    required this.room,
    required this.connectionState,
    required this.effective,
    required this.active,
  });

  bool get _pending =>
      connectionState == CoState.connected &&
      active != null &&
      !active!.hasSameValues(effective);

  Future<void> _reconnect() async {
    final manager = ServiceManager().connection;
    await manager.disconnect();
    await manager.connect(isManual: true);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final canEdit = room != null && connectionState != CoState.connecting;

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
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.tune_rounded,
                    color: colorScheme.onPrimaryContainer,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        LocaleKeys.mission_quick_controls.tr(),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        LocaleKeys.mission_quick_controls_desc.tr(),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_pending)
                  _PendingBadge(label: LocaleKeys.mission_pending_changes.tr()),
              ],
            ),
            const SizedBox(height: 22),
            _PreferenceRow(
              icon: Icons.route_rounded,
              title: LocaleKeys.mission_path_priority.tr(),
              description: LocaleKeys.mission_path_priority_desc.tr(),
              source: effective.latencyFirst.source,
              canEdit: canEdit,
              onReset:
                  effective.latencyFirst.source ==
                          MissionPreferenceSource.device
                      ? () => unawaited(
                        ServiceManager().missionControl.clearLatencyFirst(
                          room!,
                        ),
                      )
                      : null,
              control: SegmentedButton<bool>(
                segments: [
                  ButtonSegment(
                    value: false,
                    icon: const Icon(Icons.balance_rounded, size: 17),
                    label: Text(LocaleKeys.mission_balanced.tr()),
                  ),
                  ButtonSegment(
                    value: true,
                    icon: const Icon(Icons.speed_rounded, size: 17),
                    label: Text(LocaleKeys.mission_lowest_latency.tr()),
                  ),
                ],
                selected: {effective.latencyFirst.value},
                onSelectionChanged:
                    canEdit
                        ? (values) => unawaited(
                          ServiceManager().missionControl.setLatencyFirst(
                            room!,
                            values.first,
                          ),
                        )
                        : null,
                showSelectedIcon: false,
              ),
            ),
            const Divider(height: 32),
            _PreferenceRow(
              icon: Icons.device_hub_rounded,
              title: LocaleKeys.mission_peer_connectivity.tr(),
              description: LocaleKeys.mission_peer_connectivity_desc.tr(),
              source: effective.relayOnly.source,
              canEdit: canEdit,
              onReset:
                  effective.relayOnly.source == MissionPreferenceSource.device
                      ? () => unawaited(
                        ServiceManager().missionControl.clearRelayOnly(room!),
                      )
                      : null,
              control: SegmentedButton<bool>(
                segments: [
                  ButtonSegment(
                    value: false,
                    icon: const Icon(Icons.hub_outlined, size: 17),
                    label: Text(LocaleKeys.mission_adaptive_mesh.tr()),
                  ),
                  ButtonSegment(
                    value: true,
                    icon: const Icon(Icons.alt_route_rounded, size: 17),
                    label: Text(LocaleKeys.mission_relay_only.tr()),
                  ),
                ],
                selected: {effective.relayOnly.value},
                onSelectionChanged:
                    canEdit
                        ? (values) => unawaited(
                          ServiceManager().missionControl.setRelayOnly(
                            room!,
                            values.first,
                          ),
                        )
                        : null,
                showSelectedIcon: false,
              ),
            ),
            if (Platform.isWindows) ...[
              const Divider(height: 32),
              _PreferenceRow(
                icon: Icons.settings_input_antenna_rounded,
                title: LocaleKeys.mission_lan_discovery.tr(),
                description: LocaleKeys.mission_lan_discovery_desc.tr(),
                source: effective.lanDiscovery.source,
                canEdit: canEdit,
                onReset:
                    effective.lanDiscovery.source ==
                            MissionPreferenceSource.device
                        ? () => unawaited(
                          ServiceManager().missionControl.clearLanDiscovery(
                            room!,
                          ),
                        )
                        : null,
                control: Switch(
                  value: effective.lanDiscovery.value,
                  onChanged:
                      canEdit
                          ? (value) => unawaited(
                            ServiceManager().missionControl.setLanDiscovery(
                              room!,
                              value,
                            ),
                          )
                          : null,
                ),
              ),
            ],
            const SizedBox(height: 16),
            if (_pending) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.tertiaryContainer.withValues(alpha: .55),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.pending_actions_rounded,
                      color: colorScheme.onTertiaryContainer,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        LocaleKeys.mission_reconnect_notice.tr(),
                        style: TextStyle(
                          color: colorScheme.onTertiaryContainer,
                        ),
                      ),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: () => unawaited(_reconnect()),
                      icon: const Icon(Icons.refresh_rounded),
                      label: Text(LocaleKeys.mission_reconnect_apply.tr()),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed:
                    () => ServiceManager().uiState.goTo(MainTab.settings),
                icon: const Icon(Icons.settings_outlined, size: 18),
                label: Text(LocaleKeys.mission_more_network_settings.tr()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreferenceRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final MissionPreferenceSource source;
  final bool canEdit;
  final VoidCallback? onReset;
  final Widget control;

  const _PreferenceRow({
    required this.icon,
    required this.title,
    required this.description,
    required this.source,
    required this.canEdit,
    required this.onReset,
    required this.control,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 560;
        final text = Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: colorScheme.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _SourceBadge(source: source, onReset: onReset),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              text,
              const SizedBox(height: 12),
              Opacity(opacity: canEdit ? 1 : .62, child: control),
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: text),
            const SizedBox(width: 18),
            Opacity(opacity: canEdit ? 1 : .62, child: control),
          ],
        );
      },
    );
  }
}

class _SourceBadge extends StatelessWidget {
  final MissionPreferenceSource source;
  final VoidCallback? onReset;

  const _SourceBadge({required this.source, this.onReset});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final label = switch (source) {
      MissionPreferenceSource.global => LocaleKeys.mission_global_default.tr(),
      MissionPreferenceSource.room => LocaleKeys.mission_room_default.tr(),
      MissionPreferenceSource.device => LocaleKeys.mission_this_device.tr(),
    };
    return Tooltip(
      message: onReset == null ? label : LocaleKeys.mission_reset_default.tr(),
      child: InkWell(
        borderRadius: BorderRadius.circular(99),
        onTap: onReset,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color:
                source == MissionPreferenceSource.device
                    ? colorScheme.secondaryContainer
                    : colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(99),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: const TextStyle(fontSize: 10)),
              if (onReset != null) ...[
                const SizedBox(width: 3),
                const Icon(Icons.close_rounded, size: 11),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PendingBadge extends StatelessWidget {
  final String label;

  const _PendingBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: colorScheme.onTertiaryContainer,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
