import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('English, Chinese, and generated locale keys stay synchronized', () {
    final english = _translationKeys('assets/translations/en.json');
    final chinese = _translationKeys('assets/translations/zh.json');
    final generated =
        RegExp(r"static const \w+\s*=\s*'([^']+)';")
            .allMatches(
              File('lib/generated/locale_keys.g.dart').readAsStringSync(),
            )
            .map((match) => match.group(1)!)
            .toSet();

    expect(chinese, english, reason: 'English and Chinese keys differ');
    expect(
      generated,
      english,
      reason: 'Regenerate lib/generated/locale_keys.g.dart',
    );
  });

  test('settings translations do not retain misleading legacy keys', () {
    final keys = _translationKeys('assets/translations/en.json');

    const legacyKeys = {
      'adapter_proxy',
      'auto_retry_on_failure',
      'auto_set_hop',
      'auto_set_mtu',
      'custom_vpn_segment',
      'disable_tun_adapter',
      'download_acceleration',
      'local_socks5_proxy',
      'player_list_card',
      'port_whitelist',
      'software_version',
      'startup_on_boot',
    };
    expect(keys.intersection(legacyKeys), isEmpty);
    expect(
      keys,
      containsAll({
        'allowed_virtual_network_ports',
        'android_vpn_routes',
        'astralng_version',
        'compact_peer_cards',
        'enable_tun_adapter',
        'launch_at_login',
        'prefer_astral_adapter',
        'socks5_listen_all_interfaces',
        'socks5_proxy',
        'update_download_source',
        'virtual_network_access',
      }),
    );
  });
}

Set<String> _translationKeys(String path) {
  final translations = jsonDecode(File(path).readAsStringSync());
  return (translations as Map<String, dynamic>).keys.toSet();
}
