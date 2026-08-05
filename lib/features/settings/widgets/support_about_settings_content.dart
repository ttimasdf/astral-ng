import 'package:astral/core/platform/app_info.dart';
import 'package:astral/core/platform/build_brand.dart';
import 'package:astral/core/services/service_manager.dart';
import 'package:astral/generated/locale_keys.g.dart';
import 'package:astral/features/settings/pages/general/logs_page.dart';
import 'package:astral/features/settings/widgets/settings_components.dart';
import 'package:astral/features/settings/widgets/update_settings_actions.dart';
import 'package:astral/src/rust/api/simple.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:signals_flutter/signals_flutter.dart';

class SupportAboutSettingsContent extends StatefulWidget {
  const SupportAboutSettingsContent({super.key});

  @override
  State<SupportAboutSettingsContent> createState() =>
      _SupportAboutSettingsContentState();
}

class _SupportAboutSettingsContentState
    extends State<SupportAboutSettingsContent> {
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
    final colorScheme = Theme.of(context).colorScheme;

    return Watch((context) {
      final logs = ServiceManager().appSettingsState.logs.watch(context);

      return SettingsContentView(
        title: LocaleKeys.settings_support_about.tr(),
        description: LocaleKeys.settings_support_about_desc.tr(),
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
              SettingsLinkTile(
                icon: Icons.fact_check_outlined,
                title: LocaleKeys.version_info.tr(),
                subtitle: LocaleKeys.version_info_desc.tr(),
                onTap: () => showVersionInfo(context),
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
              SettingsLinkTile(
                icon: Icons.refresh,
                title: LocaleKeys.check_update.tr(),
                subtitle: LocaleKeys.check_update_available.tr(),
                onTap: () => checkForUpdates(context),
              ),
            ],
          ),
        ],
      );
    });
  }
}
