import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:astral/generated/locale_keys.g.dart';
import 'package:astral/core/services/service_manager.dart';
import 'package:astral/shared/utils/github_proxy_selector.dart';
import 'package:astral/core/services/update_service.dart';
import 'package:astral/shared/widgets/common/update_check_ui.dart';
import 'package:astral/features/settings/pages/general/history_versions_page.dart';

void checkForUpdates(BuildContext context) {
  final checker = UpdateChecker(owner: 'ldoubil', repo: 'astral');
  if (context.mounted) {
    UpdateCheckUi.checkAndPresent(context, checker);
  }
}

void navigateToHistoryVersions(BuildContext context) {
  Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => const HistoryVersionsPage()));
}

void redownloadUpdate(BuildContext context) {
  final checker = UpdateChecker(owner: 'ldoubil', repo: 'astral');
  if (context.mounted) {
    UpdateCheckUi.checkAndPresent(context, checker, forceShowDownload: true);
  }
}

String updateDownloadSourceDescription() {
  final setting = ServiceManager().updateState.updateDownloadSource.value;
  if (!GitHubProxySelector.isAccelerationEnabled(setting)) {
    return LocaleKeys.update_download_source_direct.tr();
  }
  if (GitHubProxySelector.isAutoMode(setting)) {
    final resolved =
        ServiceManager().updateState.resolvedUpdateDownloadSource.value;
    if (resolved != null && resolved.isNotEmpty) {
      return LocaleKeys.update_download_source_automatic_current.tr(
        namedArgs: {'mirror': resolved},
      );
    }
    return LocaleKeys.update_download_source_automatic_pending.tr();
  }
  return setting;
}

void editUpdateDownloadSource(BuildContext context) {
  final current = ServiceManager().updateState.updateDownloadSource.value;
  var mode =
      GitHubProxySelector.isAccelerationEnabled(current)
          ? (GitHubProxySelector.isAutoMode(current) ? 'auto' : 'manual')
          : 'off';
  final controller = TextEditingController(
    text: GitHubProxySelector.isAutoMode(current) ? '' : current,
  );
  var probing = false;
  String? probeResult;

  showDialog(
    context: context,
    builder:
        (dialogContext) => StatefulBuilder(
          builder: (dialogContext, setState) {
            Future<void> runProbe() async {
              setState(() {
                probing = true;
                probeResult = null;
              });
              GitHubProxySelector.invalidateCache();
              final prefix = await GitHubProxySelector.selectFastest(
                forceRefresh: true,
              );
              if (!dialogContext.mounted) return;
              setState(() {
                probing = false;
                probeResult =
                    prefix ??
                    LocaleKeys.update_download_source_unavailable.tr();
              });
              if (prefix != null) {
                ServiceManager().updateState.setResolvedUpdateDownloadSource(
                  prefix,
                );
              }
            }

            return AlertDialog(
              title: Text(LocaleKeys.update_download_source.tr()),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(LocaleKeys.update_download_source_desc.tr()),
                    const SizedBox(height: 12),
                    RadioGroup<String>(
                      groupValue: mode,
                      onChanged: (value) {
                        if (value != null) setState(() => mode = value);
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          RadioListTile<String>(
                            title: Text(
                              LocaleKeys.update_download_source_automatic.tr(),
                            ),
                            subtitle: Text(
                              GitHubProxySelector.builtInMirrors.join('\n'),
                              style: const TextStyle(fontSize: 12),
                            ),
                            value: 'auto',
                          ),
                          RadioListTile<String>(
                            title: Text(
                              LocaleKeys.update_download_source_custom.tr(),
                            ),
                            value: 'manual',
                          ),
                          if (mode == 'manual')
                            TextField(
                              controller: controller,
                              decoration: InputDecoration(
                                hintText:
                                    LocaleKeys
                                        .update_download_source_custom_hint
                                        .tr(),
                                border: const OutlineInputBorder(),
                              ),
                            ),
                          RadioListTile<String>(
                            title: Text(
                              LocaleKeys.update_download_source_direct.tr(),
                            ),
                            value: 'off',
                          ),
                        ],
                      ),
                    ),
                    if (mode == 'auto') ...[
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: probing ? null : runProbe,
                        icon:
                            probing
                                ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                                : const Icon(Icons.speed),
                        label: Text(
                          probing
                              ? LocaleKeys.update_download_source_benchmarking
                                  .tr()
                              : LocaleKeys.update_download_source_benchmark
                                  .tr(),
                        ),
                      ),
                      if (probeResult != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          probeResult!,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(LocaleKeys.cancel.tr()),
                ),
                ElevatedButton(
                  onPressed: () async {
                    switch (mode) {
                      case 'auto':
                        await ServiceManager().appSettings
                            .setUpdateDownloadSource(
                              GitHubProxySelector.autoMode,
                            );
                        break;
                      case 'manual':
                        final value = controller.text.trim();
                        final normalized = GitHubProxySelector.normalizePrefix(
                          value.isEmpty
                              ? GitHubProxySelector.builtInMirrors.first
                              : value,
                        );
                        await ServiceManager().appSettings
                            .setUpdateDownloadSource(normalized);
                        break;
                      case 'off':
                        await ServiceManager().appSettings
                            .setUpdateDownloadSource('');
                        GitHubProxySelector.invalidateCache();
                        ServiceManager().updateState
                            .setResolvedUpdateDownloadSource(null);
                        break;
                    }
                    if (dialogContext.mounted) {
                      Navigator.of(dialogContext).pop();
                    }
                  },
                  child: Text(LocaleKeys.save.tr()),
                ),
              ],
            );
          },
        ),
  ).then((_) => controller.dispose());
}
