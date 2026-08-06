import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:astral/generated/locale_keys.g.dart';
import 'package:astral/core/services/service_manager.dart';
import 'package:astral/core/ui/base_settings_page.dart';

class StartupPage extends BaseSettingsPage {
  const StartupPage({super.key});

  @override
  String get title => LocaleKeys.settings_startup.tr();

  @override
  Widget buildContent(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        buildSettingsCard(
          context: context,
          children: [
            SwitchListTile(
              title: Text(LocaleKeys.launch_at_login.tr()),
              subtitle: Text(LocaleKeys.launch_at_login_desc.tr()),
              value: ServiceManager().startupState.launchAtLogin.value,
              onChanged: (value) async {
                await ServiceManager().appSettings.setLaunchAtLogin(value);
              },
            ),
            SwitchListTile(
              title: Text(LocaleKeys.launch_to_tray.tr()),
              subtitle: Text(LocaleKeys.launch_to_tray_desc.tr()),
              value: ServiceManager().startupState.launchToTray.value,
              onChanged: (value) {
                ServiceManager().appSettings.setLaunchToTray(value);
              },
            ),
            SwitchListTile(
              title: Text(LocaleKeys.connect_after_launch.tr()),
              subtitle: Text(LocaleKeys.connect_after_launch_desc.tr()),
              value: ServiceManager().startupState.connectAfterLaunch.value,
              onChanged: (value) {
                ServiceManager().appSettings.setConnectAfterLaunch(value);
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        buildSettingsCard(
          context: context,
          header: LocaleKeys.settings_startup_desc.tr(),
          children: [
            ListTile(
              title: Text(LocaleKeys.launch_at_login.tr()),
              subtitle: Text(LocaleKeys.launch_at_login_desc.tr()),
              leading: const Icon(Icons.power_settings_new),
            ),
            buildDivider(),
            ListTile(
              title: Text(LocaleKeys.launch_to_tray.tr()),
              subtitle: Text(LocaleKeys.launch_to_tray_desc.tr()),
              leading: const Icon(Icons.minimize),
            ),
            buildDivider(),
            ListTile(
              title: Text(LocaleKeys.connect_after_launch.tr()),
              subtitle: Text(LocaleKeys.connect_after_launch_desc.tr()),
              leading: const Icon(Icons.play_arrow),
            ),
          ],
        ),
      ],
    );
  }
}
