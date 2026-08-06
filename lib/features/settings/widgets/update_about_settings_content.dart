import 'package:astral/core/platform/app_info.dart';
import 'package:astral/core/platform/build_brand.dart';
import 'package:astral/core/services/service_manager.dart';
import 'package:astral/features/settings/pages/general/logs_page.dart';
import 'package:astral/features/settings/widgets/settings_components.dart';
import 'package:astral/features/settings/widgets/update_settings_actions.dart';
import 'package:astral/generated/locale_keys.g.dart';
import 'package:astral/src/rust/api/simple.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:signals_flutter/signals_flutter.dart';

class UpdateAboutSettingsContent extends StatefulWidget {
  const UpdateAboutSettingsContent({super.key});

  @override
  State<UpdateAboutSettingsContent> createState() =>
      _UpdateAboutSettingsContentState();
}

class _UpdateAboutSettingsContentState
    extends State<UpdateAboutSettingsContent> {
  String _kernelVersion = '';

  @override
  void initState() {
    super.initState();
    easytierVersion().then((value) {
      if (mounted) setState(() => _kernelVersion = value);
    });
  }

  void _openLogs(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const LogsPage()));
  }

  @override
  Widget build(BuildContext context) {
    final services = ServiceManager();
    final colorScheme = Theme.of(context).colorScheme;

    return Watch((context) {
      final receiveBetaUpdates = services.updateState.receiveBetaUpdates.watch(
        context,
      );
      final automaticUpdateChecks = services.updateState.automaticUpdateChecks
          .watch(context);
      final logs = services.appSettingsState.logs.watch(context);

      return SettingsContentView(
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.primaryContainer,
                  colorScheme.tertiaryContainer.withValues(alpha: 0.75),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Container(
                  width: 66,
                  height: 66,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.surface.withValues(alpha: 0.88),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Image.asset(BuildBrand.appIcon),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        BuildBrand.appName,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        LocaleKeys.app_tagline.tr(),
                        style: TextStyle(color: colorScheme.onPrimaryContainer),
                      ),
                      const SizedBox(height: 10),
                      SettingsValueChip(
                        label: AppInfoUtil.getVersionDisplay(),
                        color: colorScheme.primary,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SettingsSection(
            title: LocaleKeys.about.tr(),
            description: LocaleKeys.about_versions_desc.tr(),
            icon: Icons.info_outline,
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 18),
                leading: const Icon(Icons.apps_outlined),
                title: Text(LocaleKeys.astralng_version.tr()),
                trailing: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 240),
                  child: Text(
                    AppInfoUtil.getVersionDisplay(),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 18),
                leading: const Icon(Icons.memory_outlined),
                title: Text(LocaleKeys.easytier_version.tr()),
                trailing: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 240),
                  child: Text(
                    _kernelVersion.isEmpty
                        ? LocaleKeys.loading.tr()
                        : _kernelVersion,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
          SettingsSection(
            title: LocaleKeys.update_settings.tr(),
            description: LocaleKeys.update_management_desc.tr(),
            icon: Icons.system_update_alt,
            children: [
              SettingsSegmentedChoice<bool>(
                title: LocaleKeys.receive_beta_updates.tr(),
                description: LocaleKeys.receive_beta_updates_desc.tr(),
                value: receiveBetaUpdates,
                segments: [
                  ButtonSegment(
                    value: false,
                    icon: const Icon(Icons.verified_outlined),
                    label: Text(LocaleKeys.stable_channel.tr()),
                  ),
                  ButtonSegment(
                    value: true,
                    icon: const Icon(Icons.science_outlined),
                    label: Text(LocaleKeys.beta_channel.tr()),
                  ),
                ],
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
                icon: Icons.refresh,
                title: LocaleKeys.check_update.tr(),
                subtitle: LocaleKeys.check_update_available.tr(),
                onTap: () => checkForUpdates(context),
              ),
              SettingsLinkTile(
                icon: Icons.bolt,
                title: LocaleKeys.update_download_source.tr(),
                subtitle: updateDownloadSourceDescription(),
                onTap: () => editUpdateDownloadSource(context),
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
          SettingsSection(
            title: LocaleKeys.support_tools.tr(),
            description: LocaleKeys.support_tools_desc.tr(),
            icon: Icons.support_agent,
            children: [
              SettingsLinkTile(
                icon: Icons.article_outlined,
                title: LocaleKeys.logs.tr(),
                subtitle: LocaleKeys.logs_desc.tr(),
                value: LocaleKeys.log_count.tr(
                  namedArgs: {'count': logs.length.toString()},
                ),
                onTap: () => _openLogs(context),
              ),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 18),
                leading: const Icon(Icons.copy_all_outlined),
                title: Text(LocaleKeys.copy_diagnostics.tr()),
                subtitle: Text(LocaleKeys.copy_diagnostics_desc.tr()),
                trailing: const Icon(Icons.copy_outlined),
                onTap: () async {
                  final details = [
                    '${BuildBrand.appName} ${AppInfoUtil.getVersionDisplay()}',
                    if (_kernelVersion.isNotEmpty) 'EasyTier: $_kernelVersion',
                    'Logs: ${logs.length}',
                  ].join('\n');
                  await Clipboard.setData(ClipboardData(text: details));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(LocaleKeys.diagnostics_copied.tr()),
                      ),
                    );
                  }
                },
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
