import 'dart:io';

import 'package:astral/core/services/service_manager.dart';
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
      final closeMinimize = services.windowState.closeMinimize.watch(context);

      return SettingsContentView(
        title: 'settings_general'.tr(),
        description: 'settings_general_desc'.tr(),
        children: [
          if (!Platform.isAndroid)
            SettingsSection(
              title: 'settings_startup'.tr(),
              description: 'settings_startup_desc'.tr(),
              icon: Icons.power_settings_new,
              children: [
                SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 18),
                  title: Text('startup_on_boot'.tr()),
                  subtitle: Text('startup_on_boot_desc'.tr()),
                  value: startup,
                  onChanged: services.appSettings.setStartup,
                ),
                SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 18),
                  title: Text('startup_minimize'.tr()),
                  subtitle: Text(
                    startup
                        ? 'startup_minimize_desc'.tr()
                        : 'settings_requires_startup'.tr(),
                  ),
                  value: startupMinimize,
                  onChanged:
                      startup ? services.appSettings.setStartupMinimize : null,
                ),
                SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 18),
                  title: Text('startup_auto_connect'.tr()),
                  subtitle: Text('startup_auto_connect_desc'.tr()),
                  value: startupAutoConnect,
                  onChanged: services.appSettings.setStartupAutoConnect,
                ),
              ],
            ),
          if (!Platform.isAndroid)
            SettingsSection(
              title: 'settings_window_behavior'.tr(),
              description: 'settings_window_behavior_desc'.tr(),
              icon: Icons.web_asset_outlined,
              children: [
                SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 18),
                  title: Text('minimize'.tr()),
                  subtitle: Text('minimize_desc'.tr()),
                  value: closeMinimize,
                  onChanged: services.appSettings.updateCloseMinimize,
                ),
              ],
            ),
          if (Platform.isAndroid)
            SettingsNotice(
              icon: Icons.phone_android,
              message: 'settings_android_general_notice'.tr(),
            ),
        ],
      );
    });
  }
}
