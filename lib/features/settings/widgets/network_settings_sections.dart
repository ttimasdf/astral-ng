import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:astral/generated/locale_keys.g.dart';
import 'package:astral/core/services/service_manager.dart';
import 'package:astral/core/ui/app_snack_bars.dart';
import 'package:astral/features/settings/models/settings_availability.dart';
import 'package:astral/features/settings/widgets/settings_components.dart';
import 'package:astral/src/rust/api/hops.dart';
import 'package:signals_flutter/signals_flutter.dart';

Widget _settingsCard({required List<Widget> children}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [Card(child: Column(children: children))],
  );
}

Widget _divider() => const Divider(height: 1);

/// 基础网络设置卡片（协议 / 加密 / 延迟优先 / 禁用 P2P）
class NetworkBasicSettingsCard extends StatelessWidget {
  const NetworkBasicSettingsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return _settingsCard(
      children: [
        SettingsSegmentedChoice<String>(
          title: LocaleKeys.preferred_peer_protocol.tr(),
          description: LocaleKeys.preferred_peer_protocol_desc.tr(),
          value:
              ServiceManager().networkConfigState.defaultProtocol
                      .watch(context)
                      .isEmpty
                  ? 'tcp'
                  : ServiceManager().networkConfigState.defaultProtocol.watch(
                    context,
                  ),
          scrollable: true,
          segments: const [
            ButtonSegment(value: 'tcp', label: Text('TCP')),
            ButtonSegment(value: 'udp', label: Text('UDP')),
            ButtonSegment(value: 'faketcp', label: Text('FakeTCP')),
            ButtonSegment(value: 'ws', label: Text('WS')),
            ButtonSegment(value: 'wss', label: Text('WSS')),
            ButtonSegment(value: 'quic', label: Text('QUIC')),
          ],
          onChanged: ServiceManager().networkConfig.updateDefaultProtocol,
        ),
        _divider(),
        SwitchListTile(
          title: Text(LocaleKeys.encrypt_peer_traffic.tr()),
          subtitle: Text(LocaleKeys.encrypt_peer_traffic_desc.tr()),
          value: ServiceManager().networkConfigState.enableEncryption.watch(
            context,
          ),
          onChanged: (value) {
            ServiceManager().networkConfig.updateEnableEncryption(value);
          },
        ),
        SwitchListTile(
          title: Text(LocaleKeys.latency_first.tr()),
          subtitle: Text(LocaleKeys.latency_first_desc.tr()),
          value: ServiceManager().networkConfigState.latencyFirst.watch(
            context,
          ),
          onChanged: (value) {
            ServiceManager().networkConfig.updateLatencyFirst(value);
          },
        ),
        SwitchListTile(
          title: Text(LocaleKeys.force_relay.tr()),
          subtitle: Text(LocaleKeys.force_relay_desc.tr()),
          value: ServiceManager().networkConfigState.disableP2p.watch(context),
          onChanged: (value) {
            ServiceManager().networkConfig.updateDisableP2p(value);
          },
        ),
      ],
    );
  }
}

/// 高级网络设置卡片
class NetworkAdvancedSettingsCard extends StatelessWidget {
  const NetworkAdvancedSettingsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return _settingsCard(
      children: [
        ListTile(
          title: Text(LocaleKeys.advanced_network.tr()),
          subtitle: Text(LocaleKeys.advanced_network_warning.tr()),
          leading: const Icon(Icons.settings_ethernet),
        ),
        _divider(),
        SwitchListTile(
          title: Text(LocaleKeys.disable_udp_hole_punching.tr()),
          subtitle: Text(LocaleKeys.disable_udp_hole_punching_desc.tr()),
          value: ServiceManager().networkConfigState.disableUdpHolePunching
              .watch(context),
          onChanged: (value) {
            ServiceManager().networkConfig.updateDisableUdpHolePunching(value);
          },
        ),
        SwitchListTile(
          title: Text(LocaleKeys.disable_tcp_hole_punching.tr()),
          subtitle: Text(LocaleKeys.disable_tcp_hole_punching_desc.tr()),
          value: ServiceManager().networkConfigState.disableTcpHolePunching
              .watch(context),
          onChanged: (value) {
            ServiceManager().networkConfig.updateDisableTcpHolePunching(value);
          },
        ),
        SwitchListTile(
          title: Text(LocaleKeys.disable_sym_hole_punching.tr()),
          subtitle: Text(LocaleKeys.disable_sym_hole_punching_desc.tr()),
          value: ServiceManager().networkConfigState.disableSymHolePunching
              .watch(context),
          onChanged: (value) {
            ServiceManager().networkConfig.updateDisableSymHolePunching(value);
          },
        ),
        SettingsSegmentedChoice<int>(
          title: LocaleKeys.traffic_compression.tr(),
          description: LocaleKeys.traffic_compression_desc.tr(),
          value: ServiceManager().networkConfigState.dataCompressAlgo.watch(
            context,
          ),
          segments: [
            ButtonSegment(
              value: 1,
              label: Text(LocaleKeys.compression_none.tr()),
            ),
            ButtonSegment(
              value: 2,
              label: Text(LocaleKeys.compression_zstd.tr()),
            ),
          ],
          onChanged: ServiceManager().networkConfig.updateDataCompressAlgo,
        ),
        SwitchListTile(
          title: Text(LocaleKeys.kcp_for_tcp_streams.tr()),
          subtitle: Text(LocaleKeys.kcp_for_tcp_streams_desc.tr()),
          value: ServiceManager().networkConfigState.enableKcpProxy.watch(
            context,
          ),
          onChanged: (value) {
            ServiceManager().networkConfig.updateEnableKcpProxy(value);
          },
        ),
        SwitchListTile(
          title: Text(LocaleKeys.physical_interfaces_only.tr()),
          subtitle: Text(LocaleKeys.physical_interfaces_only_desc.tr()),
          value: ServiceManager().networkConfigState.bindDevice.watch(context),
          onChanged: (value) {
            ServiceManager().networkConfig.updateBindDevice(value);
          },
        ),
        SwitchListTile(
          title: Text(LocaleKeys.enable_tun_adapter.tr()),
          subtitle: Text(LocaleKeys.enable_tun_adapter_desc.tr()),
          value: !ServiceManager().networkConfigState.noTun.watch(context),
          onChanged: (value) {
            ServiceManager().networkConfig.updateNoTun(!value);
          },
        ),
        SwitchListTile(
          title: Text(LocaleKeys.socks5_proxy.tr()),
          subtitle: Text(LocaleKeys.socks5_proxy_desc.tr()),
          value: ServiceManager().networkConfigState.enableSocks5.watch(
            context,
          ),
          onChanged: (value) {
            ServiceManager().networkConfig.updateEnableSocks5(value);
          },
        ),
        if (ServiceManager().networkConfigState.enableSocks5.watch(
          context,
        )) ...[
          ListTile(
            title: Text(LocaleKeys.socks5_listen_port.tr()),
            subtitle: Text(LocaleKeys.socks5_listen_port_desc.tr()),
            trailing: SizedBox(
              width: 100,
              child: TextFormField(
                key: ValueKey(
                  ServiceManager().networkConfigState.socks5Port.watch(context),
                ),
                initialValue:
                    ServiceManager().networkConfigState.socks5Port
                        .watch(context)
                        .toString(),
                keyboardType: TextInputType.number,
                textAlign: TextAlign.end,
                decoration: const InputDecoration(
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
                onFieldSubmitted: (value) {
                  final port = int.tryParse(value);
                  if (port != null && port > 0 && port <= 65535) {
                    ServiceManager().networkConfig.updateSocks5Port(port);
                  }
                },
              ),
            ),
          ),
          SwitchListTile(
            title: Text(LocaleKeys.socks5_listen_all_interfaces.tr()),
            subtitle: Text(LocaleKeys.socks5_listen_all_interfaces_desc.tr()),
            value: ServiceManager().networkConfigState.socks5ListenAllInterfaces
                .watch(context),
            onChanged:
                ServiceManager().networkConfig.updateSocks5ListenAllInterfaces,
          ),
          ListTile(
            title: Text(
              LocaleKeys.socks5_listen_address.tr(
                namedArgs: {
                  'address':
                      ServiceManager()
                              .networkConfigState
                              .socks5ListenAllInterfaces
                              .watch(context)
                          ? '0.0.0.0'
                          : '127.0.0.1',
                  'port':
                      ServiceManager().networkConfigState.socks5Port
                          .watch(context)
                          .toString(),
                },
              ),
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// MTU / Hop 设置卡片
class NetworkHopSettingsCard extends StatelessWidget {
  const NetworkHopSettingsCard({super.key});

  @override
  Widget build(BuildContext context) {
    if (!SettingsAvailability.windowsOnly.isVisible) {
      return const SizedBox.shrink();
    }

    return _settingsCard(
      children: [
        SwitchListTile(
          title: Text(LocaleKeys.prefer_astral_adapter.tr()),
          subtitle: Text(LocaleKeys.prefer_astral_adapter_desc.tr()),
          value: ServiceManager().networkConfigState.preferAstralAdapter.watch(
            context,
          ),
          onChanged: (value) {
            ServiceManager().networkConfig.setPreferAstralAdapter(value);
          },
        ),
        _divider(),
        ListTile(
          leading: const Icon(Icons.list),
          title: Text(LocaleKeys.view_adapter_priorities.tr()),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => showAdapterPriorities(context),
        ),
      ],
    );
  }
}

Future<void> showAdapterPriorities(BuildContext context) async {
  try {
    final result = await getAllInterfacesMetrics();
    if (!context.mounted) return;

    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(LocaleKeys.windows_adapter_priorities.tr()),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children:
                    result
                        .map(
                          (e) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Text('${e.$1}: ${e.$2}'),
                          ),
                        )
                        .toList(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(LocaleKeys.close.tr()),
              ),
            ],
          ),
    );
  } catch (e) {
    if (!context.mounted) return;
    AppSnackBars.error(
      context,
      LocaleKeys.windows_adapter_priorities.tr(),
      LocaleKeys.load_adapter_priorities_failed.tr(),
    );
  }
}
