import 'package:astral/core/services/service_manager.dart';
import 'package:astral/generated/locale_keys.g.dart';
import 'package:astral/core/states/window_state.dart';
import 'package:astral/features/settings/models/settings_availability.dart';
import 'package:astral/features/settings/widgets/settings_components.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';

class GeneralSettingsContent extends StatelessWidget {
  const GeneralSettingsContent({super.key});

  @override
  Widget build(BuildContext context) {
    final services = ServiceManager();

    return Watch((context) {
      final startup = services.startupState.startup.watch(context);
      final startupMinimize = services.startupState.startupMinimize.watch(
        context,
      );
      final startupAutoConnect = services.startupState.startupAutoConnect.watch(
        context,
      );
      final closeBehavior = services.windowState.closeBehavior.watch(context);

      return SettingsContentView(
        title: LocaleKeys.settings_general.tr(),
        description: LocaleKeys.settings_general_desc.tr(),
        children: [
          if (SettingsAvailability.desktopOnly.isVisible)
            SettingsSection(
              title: LocaleKeys.settings_startup.tr(),
              description: LocaleKeys.settings_startup_desc.tr(),
              icon: Icons.power_settings_new,
              children: [
                SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 18),
                  title: Text(LocaleKeys.startup_on_boot.tr()),
                  subtitle: Text(LocaleKeys.startup_on_boot_desc.tr()),
                  value: startup,
                  onChanged: services.appSettings.setStartup,
                ),
                SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 18),
                  title: Text(LocaleKeys.startup_minimize.tr()),
                  subtitle: Text(
                    startup
                        ? LocaleKeys.startup_minimize_desc.tr()
                        : LocaleKeys.settings_requires_startup.tr(),
                  ),
                  value: startupMinimize,
                  onChanged:
                      startup ? services.appSettings.setStartupMinimize : null,
                ),
                SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 18),
                  title: Text(LocaleKeys.startup_auto_connect.tr()),
                  subtitle: Text(LocaleKeys.startup_auto_connect_desc.tr()),
                  value: startupAutoConnect,
                  onChanged: services.appSettings.setStartupAutoConnect,
                ),
              ],
            ),
          if (SettingsAvailability.desktopOnly.isVisible)
            SettingsSection(
              title: LocaleKeys.settings_window_behavior.tr(),
              description: LocaleKeys.settings_window_behavior_desc.tr(),
              icon: Icons.web_asset_outlined,
              children: [
                SettingsSegmentedChoice<WindowCloseBehavior>(
                  title: LocaleKeys.settings_close_behavior.tr(),
                  description:
                      closeBehavior == WindowCloseBehavior.closeToTray
                          ? LocaleKeys.settings_close_to_tray_desc.tr()
                          : LocaleKeys.settings_exit_program_desc.tr(),
                  value: closeBehavior,
                  segments: [
                    ButtonSegment(
                      value: WindowCloseBehavior.closeToTray,
                      icon: const Icon(Icons.move_to_inbox_outlined),
                      label: Text(LocaleKeys.settings_close_to_tray.tr()),
                    ),
                    ButtonSegment(
                      value: WindowCloseBehavior.exitProgram,
                      icon: const Icon(Icons.logout),
                      label: Text(LocaleKeys.settings_exit_program.tr()),
                    ),
                  ],
                  onChanged: services.appSettings.updateWindowCloseBehavior,
                ),
              ],
            ),
          if (SettingsAvailability.mobileOnly.isVisible)
            SettingsNotice(
              icon: Icons.phone_android,
              message: LocaleKeys.settings_mobile_general_notice.tr(),
            ),
        ],
      );
    });
  }
}
