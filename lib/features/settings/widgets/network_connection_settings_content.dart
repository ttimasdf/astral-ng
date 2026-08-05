import 'package:astral/core/services/service_manager.dart';
import 'package:astral/core/states/connection_state.dart';
import 'package:astral/generated/locale_keys.g.dart';
import 'package:astral/features/settings/pages/network/listen_list_page.dart';
import 'package:astral/features/settings/pages/network/port_whitelist_page.dart';
import 'package:astral/features/settings/pages/network/vpn_segment_page.dart';
import 'package:astral/features/settings/models/settings_availability.dart';
import 'package:astral/features/settings/widgets/network_settings_sections.dart';
import 'package:astral/features/settings/widgets/settings_components.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';

class NetworkConnectionSettingsContent extends StatelessWidget {
  const NetworkConnectionSettingsContent({super.key});

  Future<void> _editSocks5Port(BuildContext context, int currentPort) async {
    final controller = TextEditingController(text: currentPort.toString());
    String? error;
    final selected = await showDialog<int>(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  title: Text(LocaleKeys.socks5_listen_port.tr()),
                  content: TextField(
                    controller: controller,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: LocaleKeys.socks5_listen_port.tr(),
                      helperText: LocaleKeys.socks5_port_range.tr(),
                      errorText: error,
                      border: const OutlineInputBorder(),
                    ),
                    onSubmitted: (_) {
                      final value = int.tryParse(controller.text);
                      if (value != null && value > 0 && value <= 65535) {
                        Navigator.pop(context, value);
                      } else {
                        setState(
                          () => error = LocaleKeys.socks5_port_invalid.tr(),
                        );
                      }
                    },
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(LocaleKeys.cancel.tr()),
                    ),
                    FilledButton(
                      onPressed: () {
                        final value = int.tryParse(controller.text);
                        if (value != null && value > 0 && value <= 65535) {
                          Navigator.pop(context, value);
                        } else {
                          setState(
                            () => error = LocaleKeys.socks5_port_invalid.tr(),
                          );
                        }
                      },
                      child: Text(LocaleKeys.save.tr()),
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
            title: Text(LocaleKeys.traffic_compression.tr()),
            children: [
              ListTile(
                selected: current == 1,
                leading: const Icon(Icons.speed),
                title: Text(LocaleKeys.compression_none.tr()),
                trailing: current == 1 ? const Icon(Icons.check) : null,
                onTap: () => Navigator.pop(context, 1),
              ),
              ListTile(
                selected: current == 2,
                leading: const Icon(Icons.compress),
                title: Text(LocaleKeys.compression_zstd.tr()),
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
    const androidVpnRoutesAvailability =
        SettingsAvailability.androidOnlyDiscoverable;

    return Watch((context) {
      final network = services.networkConfigState;
      final app = services.appSettingsState;
      final isConnected =
          services.connectionState.connectionState.watch(context) !=
          CoState.idle;
      final retryFailedConnections = app.retryFailedConnections.watch(context);
      final connectionRetryLimit = app.connectionRetryLimit.watch(context);
      final protocol =
          network.defaultProtocol.watch(context).isEmpty
              ? 'tcp'
              : network.defaultProtocol.watch(context);
      final encryption = network.enableEncryption.watch(context);
      final latencyFirst = network.latencyFirst.watch(context);
      final disableP2p = network.disableP2p.watch(context);
      final disableTunAdapter = network.noTun.watch(context);
      final localSocks5ProxyEnabled = network.enableSocks5.watch(context);
      final socks5ListenPort = network.socks5Port.watch(context);
      final preferAstralAdapter = network.preferAstralAdapter.watch(context);
      final compression = network.dataCompressAlgo.watch(context);
      final disableUdp = network.disableUdpHolePunching.watch(context);
      final disableTcp = network.disableTcpHolePunching.watch(context);
      final disableSym = network.disableSymHolePunching.watch(context);
      final kcp = network.enableKcpProxy.watch(context);
      final bindDevice = network.bindDevice.watch(context);
      final listenCount = services.playerState.listenList.watch(context).length;
      final vpnCount = services.vpnState.androidVpnRoutes.watch(context).length;
      final tcpWhitelist = network.tcpWhitelist.watch(context);
      final udpWhitelist = network.udpWhitelist.watch(context);

      return SettingsContentView(
        title: LocaleKeys.settings_network_connection.tr(),
        description: LocaleKeys.settings_network_connection_desc.tr(),
        children: [
          if (isConnected)
            SettingsNotice(
              icon: Icons.info_outline,
              message: LocaleKeys.network_changes_next_connection.tr(),
            ),
          SettingsSection(
            title: LocaleKeys.connection_behavior.tr(),
            description: LocaleKeys.connection_behavior_desc.tr(),
            icon: Icons.sync,
            children: [
              SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 18),
                title: Text(LocaleKeys.retry_failed_connections.tr()),
                subtitle: Text(LocaleKeys.retry_failed_connections_desc.tr()),
                value: retryFailedConnections,
                onChanged: services.appSettings.setRetryFailedConnections,
              ),
              ListTile(
                enabled: retryFailedConnections,
                contentPadding: const EdgeInsets.symmetric(horizontal: 18),
                title: Text(LocaleKeys.connection_retry_limit.tr()),
                subtitle: Text(
                  retryFailedConnections
                      ? LocaleKeys.connection_retry_limit_value.tr(
                        namedArgs: {'count': connectionRetryLimit.toString()},
                      )
                      : LocaleKeys.connection_retry_limit_disabled.tr(),
                ),
                trailing: DropdownButton<int>(
                  value: connectionRetryLimit,
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
                      retryFailedConnections
                          ? (value) {
                            if (value != null) {
                              services.appSettings.setConnectionRetryLimit(
                                value,
                              );
                            }
                          }
                          : null,
                ),
              ),
            ],
          ),
          SettingsSection(
            title: LocaleKeys.core_network.tr(),
            description: LocaleKeys.core_network_desc.tr(),
            icon: Icons.hub_outlined,
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 18),
                title: Text(LocaleKeys.preferred_peer_protocol.tr()),
                subtitle: Text(LocaleKeys.preferred_peer_protocol_desc.tr()),
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
                title: Text(LocaleKeys.encrypt_peer_traffic.tr()),
                subtitle: Text(LocaleKeys.encrypt_peer_traffic_desc.tr()),
                value: encryption,
                onChanged: services.networkConfig.updateEnableEncryption,
              ),
              SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 18),
                title: Text(LocaleKeys.latency_first.tr()),
                subtitle: Text(LocaleKeys.latency_first_desc.tr()),
                value: latencyFirst,
                onChanged: services.networkConfig.updateLatencyFirst,
              ),
              SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 18),
                title: Text(LocaleKeys.force_relay.tr()),
                subtitle: Text(LocaleKeys.force_relay_desc.tr()),
                value: disableP2p,
                onChanged: services.networkConfig.updateDisableP2p,
              ),
            ],
          ),
          SettingsSection(
            title: LocaleKeys.network_access.tr(),
            description: LocaleKeys.network_access_desc.tr(),
            icon: Icons.route_outlined,
            children: [
              SettingsLinkTile(
                icon: Icons.sensors,
                title: LocaleKeys.listen_list.tr(),
                subtitle: LocaleKeys.listen_list_desc.tr(),
                value: LocaleKeys.item_count.tr(
                  namedArgs: {'count': listenCount.toString()},
                ),
                onTap: () => _open(context, const ListenListPage()),
              ),
              if (androidVpnRoutesAvailability.isVisible)
                SettingsLinkTile(
                  icon: Icons.vpn_lock_outlined,
                  title: LocaleKeys.android_vpn_routes.tr(),
                  subtitle:
                      androidVpnRoutesAvailability.currentUnavailableReasonKey
                          ?.tr() ??
                      LocaleKeys.android_vpn_routes_desc.tr(),
                  value:
                      androidVpnRoutesAvailability.isEnabled
                          ? LocaleKeys.item_count.tr(
                            namedArgs: {'count': vpnCount.toString()},
                          )
                          : null,
                  enabled: androidVpnRoutesAvailability.isEnabled,
                  onTap: () => _open(context, const VpnSegmentPage()),
                ),
              SettingsLinkTile(
                icon: Icons.security_outlined,
                title: LocaleKeys.allowed_virtual_network_ports.tr(),
                subtitle: LocaleKeys.allowed_virtual_network_ports_desc.tr(),
                value:
                    tcpWhitelist.isEmpty && udpWhitelist.isEmpty
                        ? LocaleKeys.not_configured.tr()
                        : LocaleKeys.configured.tr(),
                onTap: () => _open(context, const PortWhitelistPage()),
              ),
            ],
          ),
          SettingsSection(
            title: LocaleKeys.adapter_proxy.tr(),
            description: LocaleKeys.adapter_proxy_desc.tr(),
            icon: Icons.settings_input_component_outlined,
            children: [
              SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 18),
                title: Text(LocaleKeys.disable_tun_adapter.tr()),
                subtitle: Text(LocaleKeys.disable_tun_adapter_desc.tr()),
                value: disableTunAdapter,
                onChanged: services.networkConfig.updateNoTun,
              ),
              SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 18),
                title: Text(LocaleKeys.local_socks5_proxy.tr()),
                subtitle: Text(
                  disableTunAdapter
                      ? LocaleKeys.local_socks5_proxy_desc.tr()
                      : LocaleKeys.socks5_recommends_no_tun.tr(),
                ),
                value: localSocks5ProxyEnabled,
                onChanged: services.networkConfig.updateEnableSocks5,
              ),
              SettingsLinkTile(
                icon: Icons.numbers,
                title: LocaleKeys.socks5_listen_port.tr(),
                subtitle: LocaleKeys.socks5_listen_address.tr(
                  namedArgs: {'port': socks5ListenPort.toString()},
                ),
                value: socks5ListenPort.toString(),
                enabled: localSocks5ProxyEnabled,
                onTap: () => _editSocks5Port(context, socks5ListenPort),
              ),
              if (SettingsAvailability.windowsOnly.isVisible)
                SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 18),
                  title: Text(LocaleKeys.prefer_astral_adapter.tr()),
                  subtitle: Text(LocaleKeys.prefer_astral_adapter_desc.tr()),
                  value: preferAstralAdapter,
                  onChanged: services.networkConfig.setPreferAstralAdapter,
                ),
              if (SettingsAvailability.windowsOnly.isVisible)
                SettingsLinkTile(
                  icon: Icons.format_list_numbered,
                  title: LocaleKeys.view_adapter_priorities.tr(),
                  subtitle: LocaleKeys.view_adapter_priorities_desc.tr(),
                  onTap: () => showAdapterPriorities(context),
                ),
            ],
          ),
          SettingsSection(
            title: LocaleKeys.advanced_network.tr(),
            description: LocaleKeys.advanced_network_warning.tr(),
            icon: Icons.tune,
            children: [
              SettingsLinkTile(
                icon: Icons.compress,
                title: LocaleKeys.traffic_compression.tr(),
                subtitle: LocaleKeys.traffic_compression_desc.tr(),
                value:
                    compression == 1
                        ? LocaleKeys.compression_none.tr()
                        : 'Zstd',
                onTap: () => _selectCompression(context, compression),
              ),
              SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 18),
                title: Text(LocaleKeys.disable_udp_hole_punching.tr()),
                subtitle: Text(LocaleKeys.disable_udp_hole_punching_desc.tr()),
                value: disableUdp,
                onChanged: services.networkConfig.updateDisableUdpHolePunching,
              ),
              SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 18),
                title: Text(LocaleKeys.disable_tcp_hole_punching.tr()),
                subtitle: Text(LocaleKeys.disable_tcp_hole_punching_desc.tr()),
                value: disableTcp,
                onChanged: services.networkConfig.updateDisableTcpHolePunching,
              ),
              SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 18),
                title: Text(LocaleKeys.disable_sym_hole_punching.tr()),
                subtitle: Text(LocaleKeys.disable_sym_hole_punching_desc.tr()),
                value: disableSym,
                onChanged: services.networkConfig.updateDisableSymHolePunching,
              ),
              SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 18),
                title: Text(LocaleKeys.kcp_for_tcp_streams.tr()),
                subtitle: Text(LocaleKeys.kcp_for_tcp_streams_desc.tr()),
                value: kcp,
                onChanged: services.networkConfig.updateEnableKcpProxy,
              ),
              SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 18),
                title: Text(LocaleKeys.physical_interfaces_only.tr()),
                subtitle: Text(LocaleKeys.physical_interfaces_only_desc.tr()),
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
