import 'package:astral/core/platform/app_info.dart';
import 'package:astral/core/services/service_manager.dart';
import 'package:astral/generated/locale_keys.g.dart';
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
        title: LocaleKeys.settings_updates.tr(),
        description: LocaleKeys.settings_updates_desc.tr(),
        children: [
          SettingsSection(
            title: LocaleKeys.update_channel.tr(),
            description: LocaleKeys.update_channel_desc.tr(),
            icon: Icons.rocket_launch_outlined,
            children: [
              SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 18),
                title: Text(LocaleKeys.join_beta.tr()),
                subtitle: Text(LocaleKeys.join_beta_desc.tr()),
                value: beta,
                onChanged: services.appSettings.setBeta,
              ),
              SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 18),
                title: Text(LocaleKeys.auto_update.tr()),
                subtitle: Text(
                  beta
                      ? LocaleKeys.auto_update_beta_desc.tr()
                      : LocaleKeys.auto_update_desc.tr(),
                ),
                value: beta || automatic,
                onChanged:
                    beta ? null : services.appSettings.setAutoCheckUpdate,
              ),
              SettingsLinkTile(
                icon: Icons.bolt,
                title: LocaleKeys.download_acceleration.tr(),
                subtitle: downloadAccelerateDescription(),
                onTap: () => editDownloadAccelerate(context),
              ),
            ],
          ),
          SettingsSection(
            title: LocaleKeys.update_operations.tr(),
            description: LocaleKeys.update_operations_desc.tr(),
            icon: Icons.system_update_alt,
            children: [
              SettingsLinkTile(
                icon: Icons.refresh,
                title: LocaleKeys.check_update.tr(),
                subtitle: LocaleKeys.check_update_available.tr(),
                onTap: () => checkForUpdates(context),
              ),
              SettingsLinkTile(
                icon: Icons.info_outline,
                title: LocaleKeys.version_info.tr(),
                subtitle: LocaleKeys.version_info_desc.tr(),
                value: AppInfoUtil.getVersionDisplay(),
                onTap: () => showVersionInfo(context),
              ),
              SettingsLinkTile(
                icon: Icons.history,
                title: LocaleKeys.history_versions.tr(),
                subtitle: LocaleKeys.history_versions_desc.tr(),
                onTap: () => navigateToHistoryVersions(context),
              ),
              SettingsLinkTile(
                icon: Icons.cloud_download_outlined,
                title: LocaleKeys.redownload_update.tr(),
                subtitle: LocaleKeys.redownload_update_desc.tr(),
                onTap: () => redownloadUpdate(context),
              ),
            ],
          ),
          SettingsNotice(
            icon: beta ? Icons.science_outlined : Icons.verified_outlined,
            message:
                beta
                    ? LocaleKeys.beta_version_desc.tr()
                    : LocaleKeys.stable_channel_desc.tr(),
          ),
        ],
      );
    });
  }
}
