import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:astral/core/services/service_manager.dart';
import 'package:astral/generated/locale_keys.g.dart';
import 'package:astral/core/ui/base_settings_page.dart';
import 'package:signals_flutter/signals_flutter.dart';

class PortWhitelistPage extends BaseSettingsPage {
  const PortWhitelistPage({super.key});

  @override
  String get title => LocaleKeys.port_whitelist.tr();

  @override
  Widget buildContent(BuildContext context) {
    final tcpWhitelist = ServiceManager().networkConfigState.tcpWhitelist.watch(
      context,
    );
    final udpWhitelist = ServiceManager().networkConfigState.udpWhitelist.watch(
      context,
    );

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        buildSettingsCard(
          context: context,
          children: [
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text(LocaleKeys.port_whitelist_info.tr()),
              subtitle: Text(LocaleKeys.port_whitelist_format_desc.tr()),
            ),
          ],
        ),
        const SizedBox(height: 16),
        buildSettingsCard(
          context: context,
          children: [
            ListTile(
              leading: const Icon(Icons.storage),
              title: Text(LocaleKeys.tcp_allowed_ports.tr()),
              subtitle: Text(
                tcpWhitelist.isEmpty
                    ? LocaleKeys.not_configured.tr()
                    : tcpWhitelist,
                style: TextStyle(
                  color:
                      tcpWhitelist.isEmpty
                          ? Theme.of(context).textTheme.bodySmall?.color
                          : Theme.of(context).colorScheme.primary,
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    tooltip: LocaleKeys.edit.tr(),
                    onPressed:
                        () => _editWhitelist(
                          context,
                          'TCP',
                          tcpWhitelist,
                          (value) => ServiceManager().networkConfig
                              .updateTcpWhitelist(value),
                        ),
                  ),
                  if (tcpWhitelist.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear),
                      tooltip: LocaleKeys.clear.tr(),
                      onPressed:
                          () => _clearWhitelist(
                            context,
                            'TCP',
                            () => ServiceManager().networkConfig
                                .updateTcpWhitelist(''),
                          ),
                    ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        buildSettingsCard(
          context: context,
          children: [
            ListTile(
              leading: const Icon(Icons.wifi),
              title: Text(LocaleKeys.udp_allowed_ports.tr()),
              subtitle: Text(
                udpWhitelist.isEmpty
                    ? LocaleKeys.not_configured.tr()
                    : udpWhitelist,
                style: TextStyle(
                  color:
                      udpWhitelist.isEmpty
                          ? Theme.of(context).textTheme.bodySmall?.color
                          : Theme.of(context).colorScheme.primary,
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    tooltip: LocaleKeys.edit.tr(),
                    onPressed:
                        () => _editWhitelist(
                          context,
                          'UDP',
                          udpWhitelist,
                          (value) => ServiceManager().networkConfig
                              .updateUdpWhitelist(value),
                        ),
                  ),
                  if (udpWhitelist.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear),
                      tooltip: LocaleKeys.clear.tr(),
                      onPressed:
                          () => _clearWhitelist(
                            context,
                            'UDP',
                            () => ServiceManager().networkConfig
                                .updateUdpWhitelist(''),
                          ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _editWhitelist(
    BuildContext context,
    String type,
    String currentValue,
    Future<void> Function(String) onSave,
  ) async {
    final controller = TextEditingController(text: currentValue);
    final result = await showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              LocaleKeys.edit_port_whitelist.tr(namedArgs: {'type': type}),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  LocaleKeys.port_format.tr(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text('• ${LocaleKeys.single_port_example.tr()}'),
                Text('• ${LocaleKeys.port_range_example.tr()}'),
                Text('• ${LocaleKeys.multiple_ports_example.tr()}'),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  autofocus: true,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: LocaleKeys.port_field.tr(
                      namedArgs: {'type': type},
                    ),
                    hintText: LocaleKeys.port_example_hint.tr(),
                    border: const OutlineInputBorder(),
                    helperText: LocaleKeys.empty_allows_all_ports.tr(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(LocaleKeys.cancel.tr()),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, controller.text),
                child: Text(LocaleKeys.save.tr()),
              ),
            ],
          ),
    );

    if (result != null) {
      await onSave(result.trim());
    }
  }

  Future<void> _clearWhitelist(
    BuildContext context,
    String type,
    Future<void> Function() onClear,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              LocaleKeys.confirm_clear_ports.tr(namedArgs: {'type': type}),
            ),
            content: Text(
              LocaleKeys.confirm_clear_ports_desc.tr(namedArgs: {'type': type}),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(LocaleKeys.cancel.tr()),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(LocaleKeys.clear.tr()),
              ),
            ],
          ),
    );

    if (confirm == true) {
      await onClear();
    }
  }
}
