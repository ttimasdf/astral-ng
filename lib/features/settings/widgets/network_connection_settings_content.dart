import 'dart:io';

import 'package:astral/core/services/service_manager.dart';
import 'package:astral/core/states/connection_state.dart';
import 'package:astral/features/settings/pages/network/listen_list_page.dart';
import 'package:astral/features/settings/pages/network/port_whitelist_page.dart';
import 'package:astral/features/settings/pages/network/vpn_segment_page.dart';
import 'package:astral/features/settings/widgets/network_settings_sections.dart';
import 'package:astral/features/settings/widgets/settings_components.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';

class NetworkConnectionSettingsContent extends StatelessWidget {
  final VoidCallback onOpenGeneral;

  const NetworkConnectionSettingsContent({
    super.key,
    required this.onOpenGeneral,
  });

  Future<void> _editSocks5Port(BuildContext context, int currentPort) async {
    final controller = TextEditingController(text: currentPort.toString());
    String? error;
    final selected = await showDialog<int>(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  title: Text('socks5_port'.tr()),
                  content: TextField(
                    controller: controller,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'socks5_port'.tr(),
                      helperText: 'socks5_port_range'.tr(),
                      errorText: error,
                      border: const OutlineInputBorder(),
                    ),
                    onSubmitted: (_) {
                      final value = int.tryParse(controller.text);
                      if (value != null && value > 0 && value <= 65535) {
                        Navigator.pop(context, value);
                      } else {
                        setState(() => error = 'socks5_port_invalid'.tr());
                      }
                    },
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('cancel'.tr()),
                    ),
                    FilledButton(
                      onPressed: () {
                        final value = int.tryParse(controller.text);
                        if (value != null && value > 0 && value <= 65535) {
                          Navigator.pop(context, value);
                        } else {
                          setState(() => error = 'socks5_port_invalid'.tr());
                        }
                      },
                      child: Text('save'.tr()),
                    ),
                  ],
                ),
          ),
    );
    controller.dispose();

    if (selected != null) {
      await ServiceManager().networkConfig.updateSocks5Port(selected);
    }
  }

  Future<void> _selectCompression(BuildContext context, int current) async {
    final selected = await showDialog<int>(
      context: context,
      builder:
          (context) => SimpleDialog(
            title: Text('compression_algorithm'.tr()),
            children: [
              ListTile(
                selected: current == 1,
                leading: const Icon(Icons.speed),
                title: Text('no_compression'.tr()),
                trailing: current == 1 ? const Icon(Icons.check) : null,
                onTap: () => Navigator.pop(context, 1),
              ),
              ListTile(
                selected: current == 2,
                leading: const Icon(Icons.compress),
                title: Text('high_performance_compression'.tr()),
                trailing: current == 2 ? const Icon(Icons.check) : null,
                onTap: () => Navigator.pop(context, 2),
              ),
            ],
          ),
    );

    if (selected != null) {
      await ServiceManager().networkConfig.updateDataCompressAlgo(selected);
    }
  }

  void _open(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final services = ServiceManager();

    return Watch((context) {
      final network = services.networkConfigState;
      final app = services.appSettingsState;
      final isConnected =
          services.connectionState.connectionState.watch(context) !=
          CoState.idle;
      final autoRetry = app.autoRetryOnFailure.watch(context);
      final retryCount = app.maxRetryCount.watch(context);
      final protocol =
          network.defaultProtocol.watch(context).isEmpty
              ? 'tcp'
              : network.defaultProtocol.watch(context);
      final encryption = network.enableEncryption.watch(context);
      final latencyFirst = network.latencyFirst.watch(context);
      final disableP2p = network.disableP2p.watch(context);
      final noTun = network.noTun.watch(context);
      final enableSocks5 = network.enableSocks5.watch(context);
      final socks5Port = network.socks5Port.watch(context);
      final autoSetMtu = network.autoSetMTU.watch(context);
      final compression = network.dataCompressAlgo.watch(context);
      final disableUdp = network.disableUdpHolePunching.watch(context);
      final disableTcp = network.disableTcpHolePunching.watch(context);
      final disableSym = network.disableSymHolePunching.watch(context);
      final kcp = network.enableKcpProxy.watch(context);
      final bindDevice = network.bindDevice.watch(context);
      final listenCount = services.playerState.listenList.watch(context).length;
      final vpnCount = services.vpnState.customVpn.watch(context).length;
      final tcpWhitelist = network.tcpWhitelist.watch(context);
      final udpWhitelist = network.udpWhitelist.watch(context);

      return SettingsContentView(
        title: 'settings_network_connection'.tr(),
        description: 'settings_network_connection_desc'.tr(),
        children: [
          if (isConnected)
            SettingsNotice(
              icon: Icons.info_outline,
              message: 'network_changes_next_connection'.tr(),
            ),
          SettingsSection(
            title: 'connection_behavior'.tr(),
            description: 'connection_behavior_desc'.tr(),
            icon: Icons.sync,
            children: [
              SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 18),
                title: Text('auto_retry_on_failure'.tr()),
                subtitle: Text('auto_retry_on_failure_desc'.tr()),
                value: autoRetry,
                onChanged: services.appSettings.updateAutoRetryOnFailure,
              ),
              ListTile(
                enabled: autoRetry,
                contentPadding: const EdgeInsets.symmetric(horizontal: 18),
                title: Text('max_retry_count'.tr()),
                subtitle: Text(
                  autoRetry
                      ? 'max_retry_count_value'.tr(
                        namedArgs: {'count': retryCount.toString()},
                      )
                      : 'max_retry_count_disabled'.tr(),
                ),
                trailing: DropdownButton<int>(
                  value: retryCount,
                  underline: const SizedBox.shrink(),
                  items:
                      [1, 2, 3, 5, 10]
                          .map(
                            (count) => DropdownMenuItem(
                              value: count,
                              child: Text(count.toString()),
                            ),
                          )
                          .toList(),
                  onChanged:
                      autoRetry
                          ? (value) {
                            if (value != null) {
                              services.appSettings.updateMaxRetryCount(value);
                            }
                          }
                          : null,
                ),
              ),
              SettingsLinkTile(
                icon: Icons.power_settings_new,
                title: 'startup_auto_connect'.tr(),
                subtitle: 'auto_connect_managed_general'.tr(),
                value:
                    services.startupState.startupAutoConnect.watch(context)
                        ? 'enabled'.tr()
                        : 'disabled'.tr(),
                onTap: onOpenGeneral,
              ),
            ],
          ),
          SettingsSection(
            title: 'core_network'.tr(),
            description: 'core_network_desc'.tr(),
            icon: Icons.hub_outlined,
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 18),
                title: Text('preferred_protocol'.tr()),
                subtitle: Text('preferred_protocol_desc'.tr()),
                trailing: DropdownButton<String>(
                  value: protocol,
                  underline: const SizedBox.shrink(),
                  items:
                      const ['tcp', 'udp', 'faketcp', 'ws', 'wss', 'quic']
                          .map(
                            (value) => DropdownMenuItem(
                              value: value,
                              child: Text(value.toUpperCase()),
                            ),
                          )
                          .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      services.networkConfig.updateDefaultProtocol(value);
                    }
                  },
                ),
              ),
              SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 18),
                title: Text('enable_encryption'.tr()),
                subtitle: Text('enable_encryption_desc'.tr()),
                value: encryption,
                onChanged: services.networkConfig.updateEnableEncryption,
              ),
              SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 18),
                title: Text('latency_first'.tr()),
                subtitle: Text('latency_first_desc'.tr()),
                value: latencyFirst,
                onChanged: services.networkConfig.updateLatencyFirst,
              ),
              SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 18),
                title: Text('force_relay'.tr()),
                subtitle: Text('force_relay_desc'.tr()),
                value: disableP2p,
                onChanged: services.networkConfig.updateDisableP2p,
              ),
            ],
          ),
          SettingsSection(
            title: 'network_access'.tr(),
            description: 'network_access_desc'.tr(),
            icon: Icons.route_outlined,
            children: [
              SettingsLinkTile(
                icon: Icons.sensors,
                title: 'listen_list'.tr(),
                subtitle: 'listen_list_desc'.tr(),
                value: 'item_count'.tr(
                  namedArgs: {'count': listenCount.toString()},
                ),
                onTap: () => _open(context, const ListenListPage()),
              ),
              if (Platform.isAndroid)
                SettingsLinkTile(
                  icon: Icons.vpn_lock_outlined,
                  title: 'custom_vpn_segment'.tr(),
                  subtitle: 'custom_vpn_segment_desc'.tr(),
                  value: 'item_count'.tr(
                    namedArgs: {'count': vpnCount.toString()},
                  ),
                  onTap: () => _open(context, const VpnSegmentPage()),
                ),
              SettingsLinkTile(
                icon: Icons.security_outlined,
                title: 'port_whitelist'.tr(),
                subtitle: 'port_whitelist_desc'.tr(),
                value:
                    tcpWhitelist.isEmpty && udpWhitelist.isEmpty
                        ? 'not_configured'.tr()
                        : 'configured'.tr(),
                onTap: () => _open(context, const PortWhitelistPage()),
              ),
            ],
          ),
          SettingsSection(
            title: 'adapter_proxy'.tr(),
            description: 'adapter_proxy_desc'.tr(),
            icon: Icons.settings_input_component_outlined,
            children: [
              SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 18),
                title: Text('tun_device'.tr()),
                subtitle: Text('tun_device_desc'.tr()),
                value: noTun,
                onChanged: services.networkConfig.updateNoTun,
              ),
              SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 18),
                title: Text('enable_socks5'.tr()),
                subtitle: Text(
                  noTun
                      ? 'enable_socks5_desc'.tr()
                      : 'socks5_recommends_no_tun'.tr(),
                ),
                value: enableSocks5,
                onChanged: services.networkConfig.updateEnableSocks5,
              ),
              if (enableSocks5)
                SettingsLinkTile(
                  icon: Icons.numbers,
                  title: 'socks5_port'.tr(),
                  subtitle: 'socks5_address_hint'.tr(
                    namedArgs: {'port': socks5Port.toString()},
                  ),
                  value: socks5Port.toString(),
                  onTap: () => _editSocks5Port(context, socks5Port),
                ),
              SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 18),
                title: Text('auto_set_hop'.tr()),
                subtitle: Text('auto_set_hop_desc'.tr()),
                value: autoSetMtu,
                onChanged: services.networkConfig.setAutoSetMTU,
              ),
              SettingsLinkTile(
                icon: Icons.format_list_numbered,
                title: 'view_hop_list'.tr(),
                subtitle: 'view_hop_list_desc'.tr(),
                onTap: () => showHopList(context),
              ),
            ],
          ),
          SettingsSection(
            title: 'advanced_network'.tr(),
            description: 'advanced_network_warning'.tr(),
            icon: Icons.tune,
            children: [
              SettingsLinkTile(
                icon: Icons.compress,
                title: 'compression_algorithm'.tr(),
                subtitle: 'compression_algorithm_desc'.tr(),
                value: compression == 1 ? 'no_compression'.tr() : 'Zstd',
                onTap: () => _selectCompression(context, compression),
              ),
              SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 18),
                title: Text('disable_udp_hole_punching'.tr()),
                subtitle: Text('disable_udp_hole_punching_desc'.tr()),
                value: disableUdp,
                onChanged: services.networkConfig.updateDisableUdpHolePunching,
              ),
              SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 18),
                title: Text('disable_tcp_hole_punching'.tr()),
                subtitle: Text('disable_tcp_hole_punching_desc'.tr()),
                value: disableTcp,
                onChanged: services.networkConfig.updateDisableTcpHolePunching,
              ),
              SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 18),
                title: Text('disable_sym_hole_punching'.tr()),
                subtitle: Text('disable_sym_hole_punching_desc'.tr()),
                value: disableSym,
                onChanged: services.networkConfig.updateDisableSymHolePunching,
              ),
              SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 18),
                title: Text('enable_kcp_proxy'.tr()),
                subtitle: Text('enable_kcp_proxy_desc'.tr()),
                value: kcp,
                onChanged: services.networkConfig.updateEnableKcpProxy,
              ),
              SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 18),
                title: Text('bind_device'.tr()),
                subtitle: Text('bind_device_desc'.tr()),
                value: bindDevice,
                onChanged: services.networkConfig.updateBindDevice,
              ),
            ],
          ),
        ],
      );
    });
  }
}
