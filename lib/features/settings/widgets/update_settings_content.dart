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
      final receiveBetaUpdates = services.updateState.receiveBetaUpdates.watch(
        context,
      );
      final automaticUpdateChecks = services.updateState.automaticUpdateChecks
          .watch(context);

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
                title: Text(LocaleKeys.receive_beta_updates.tr()),
                subtitle: Text(LocaleKeys.receive_beta_updates_desc.tr()),
                value: receiveBetaUpdates,
                onChanged: services.appSettings.setReceiveBetaUpdates,
              ),
              SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 18),
                title: Text(LocaleKeys.automatic_update_checks.tr()),
                subtitle: Text(
                  receiveBetaUpdates
                      ? LocaleKeys.beta_update_checks_required.tr()
                      : LocaleKeys.automatic_update_checks_desc.tr(),
                ),
                value: receiveBetaUpdates || automaticUpdateChecks,
                onChanged:
                    receiveBetaUpdates
                        ? null
                        : services.appSettings.setAutomaticUpdateChecks,
              ),
              SettingsLinkTile(
                icon: Icons.bolt,
                title: LocaleKeys.update_download_source.tr(),
                subtitle: updateDownloadSourceDescription(),
                onTap: () => editUpdateDownloadSource(context),
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
                title: LocaleKeys.previous_versions.tr(),
                subtitle: LocaleKeys.previous_versions_desc.tr(),
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
            icon:
                receiveBetaUpdates
                    ? Icons.science_outlined
                    : Icons.verified_outlined,
            message:
                receiveBetaUpdates
                    ? LocaleKeys.beta_version_desc.tr()
                    : LocaleKeys.stable_channel_desc.tr(),
          ),
        ],
      );
    });
  }
}
