import 'package:astral/core/platform/app_info.dart';
import 'package:astral/core/services/service_manager.dart';
import 'package:astral/features/settings/widgets/settings_components.dart';
import 'package:astral/features/settings/widgets/update_settings_actions.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';

class UpdateSettingsContent extends StatelessWidget {
  const UpdateSettingsContent({super.key});

  @override
  Widget build(BuildContext context) {
    final services = ServiceManager();

    return Watch((context) {
      final beta = services.updateState.beta.watch(context);
      final automatic = services.updateState.autoCheckUpdate.watch(context);

      return SettingsContentView(
        title: 'settings_updates'.tr(),
        description: 'settings_updates_desc'.tr(),
        children: [
          SettingsSection(
            title: 'update_channel'.tr(),
            description: 'update_channel_desc'.tr(),
            icon: Icons.rocket_launch_outlined,
            children: [
              SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 18),
                title: Text('join_beta'.tr()),
                subtitle: Text('join_beta_desc'.tr()),
                value: beta,
                onChanged: services.appSettings.setBeta,
              ),
              SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 18),
                title: Text('auto_update'.tr()),
                subtitle: Text(
                  beta ? 'auto_update_beta_desc'.tr() : 'auto_update_desc'.tr(),
                ),
                value: beta || automatic,
                onChanged:
                    beta ? null : services.appSettings.setAutoCheckUpdate,
              ),
              SettingsLinkTile(
                icon: Icons.bolt,
                title: 'download_acceleration'.tr(),
                subtitle: downloadAccelerateDescription(),
                onTap: () => editDownloadAccelerate(context),
              ),
            ],
          ),
          SettingsSection(
            title: 'update_operations'.tr(),
            description: 'update_operations_desc'.tr(),
            icon: Icons.system_update_alt,
            children: [
              SettingsLinkTile(
                icon: Icons.refresh,
                title: 'check_update'.tr(),
                subtitle: 'check_update_available'.tr(),
                onTap: () => checkForUpdates(context),
              ),
              SettingsLinkTile(
                icon: Icons.info_outline,
                title: 'version_info'.tr(),
                subtitle: 'version_info_desc'.tr(),
                value: AppInfoUtil.getVersionDisplay(),
                onTap: () => showVersionInfo(context),
              ),
              SettingsLinkTile(
                icon: Icons.history,
                title: 'history_versions'.tr(),
                subtitle: 'history_versions_desc'.tr(),
                onTap: () => navigateToHistoryVersions(context),
              ),
              SettingsLinkTile(
                icon: Icons.cloud_download_outlined,
                title: 'redownload_update'.tr(),
                subtitle: 'redownload_update_desc'.tr(),
                onTap: () => redownloadUpdate(context),
              ),
            ],
          ),
          SettingsNotice(
            icon: beta ? Icons.science_outlined : Icons.verified_outlined,
            message:
                beta ? 'beta_version_desc'.tr() : 'stable_channel_desc'.tr(),
          ),
        ],
      );
    });
  }
}
