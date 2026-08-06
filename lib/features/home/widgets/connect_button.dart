import 'dart:async';

import 'package:astral/core/services/connection_connect_guard.dart';
import 'package:astral/core/services/service_manager.dart';
import 'package:astral/core/states/connection_state.dart';
import 'package:astral/core/ui/app_snack_bars.dart';
import 'package:astral/core/ui/main_tab.dart';
import 'package:astral/features/home/widgets/connect_npcap_guard.dart';
import 'package:astral/generated/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';

/// Primary connection action embedded in the Mission Control hero.
class ConnectButton extends StatelessWidget {
  final bool expanded;

  const ConnectButton({super.key, this.expanded = false});

  Future<void> _handleConnect(BuildContext context) async {
    final targetIssue = ConnectionConnectGuard.connectTargetIssue();
    if (targetIssue != null) {
      final (title, actionLabel, icon, tab) = switch (targetIssue) {
        ConnectTargetIssue.noRoom => (
          LocaleKeys.select_room_first.tr(),
          LocaleKeys.go_select_room.tr(),
          Icons.meeting_room_outlined,
          MainTab.room,
        ),
        ConnectTargetIssue.noneEnabled => (
          LocaleKeys.enable_server_first.tr(),
          LocaleKeys.go_enable.tr(),
          Icons.toggle_on_outlined,
          MainTab.servers,
        ),
        ConnectTargetIssue.noServers => (
          LocaleKeys.add_server_first.tr(),
          LocaleKeys.go_add.tr(),
          Icons.dns_outlined,
          MainTab.servers,
        ),
      };
      if (!context.mounted) return;
      AppSnackBars.show(
        context,
        title: title,
        message: '',
        backgroundColor: Theme.of(context).colorScheme.inverseSurface,
        icon: icon,
        action: SnackBarAction(
          label: actionLabel,
          textColor: Theme.of(context).colorScheme.onInverseSurface,
          onPressed: () => ServiceManager().uiState.goTo(tab),
        ),
      );
      return;
    }

    if (!await ConnectionConnectGuard.isNpcapReady()) {
      if (!context.mounted) return;
      final shouldOpenTutorial = await showNpcapRequiredDialog(context);
      if (shouldOpenTutorial == true && context.mounted) {
        await openNpcapTutorial(context);
      }
      return;
    }

    final success = await ServiceManager().connection.connect(isManual: true);
    if (success == false && context.mounted) {
      AppSnackBars.error(context, '连接失败', '请检查网络后重试，并确认房间与服务器配置无误');
    }
  }

  Future<void> _toggle(BuildContext context, CoState state) async {
    switch (state) {
      case CoState.idle:
        await _handleConnect(context);
      case CoState.connecting:
        await ServiceManager().connection.cancelConnection();
      case CoState.connected:
        await ServiceManager().connection.disconnect();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Watch((context) {
      final state = ServiceManager().connectionState.connectionState.watch(
        context,
      );
      final label = switch (state) {
        CoState.idle => LocaleKeys.mission_connect.tr(),
        CoState.connecting => LocaleKeys.mission_cancel.tr(),
        CoState.connected => LocaleKeys.mission_disconnect.tr(),
      };
      final icon = switch (state) {
        CoState.idle => Icons.power_settings_new_rounded,
        CoState.connecting => Icons.close_rounded,
        CoState.connected => Icons.link_off_rounded,
      };
      final background = switch (state) {
        CoState.idle => colorScheme.primary,
        CoState.connecting => colorScheme.error,
        CoState.connected => colorScheme.tertiary,
      };
      final foreground = switch (state) {
        CoState.idle => colorScheme.onPrimary,
        CoState.connecting => colorScheme.onError,
        CoState.connected => colorScheme.onTertiary,
      };

      final button = FilledButton.icon(
        key: ValueKey(state),
        onPressed: () => unawaited(_toggle(context, state)),
        icon: Icon(icon),
        label: Text(label),
        style: FilledButton.styleFrom(
          minimumSize: const Size(176, 52),
          backgroundColor: background,
          foregroundColor: foreground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      );

      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (state == CoState.connecting) ...[
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
          if (expanded)
            SizedBox(width: double.infinity, child: button)
          else
            button,
        ],
      );
    });
  }
}
