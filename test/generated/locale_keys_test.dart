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
      'copy_diagnostics',
      'copy_diagnostics_desc',
      'custom_vpn_segment',
      'diagnostics_copied',
      'disable_tun_adapter',
      'download_acceleration',
      'installed_version',
      'local_socks5_proxy',
      'no_settings_found',
      'no_settings_found_desc',
      'player_list_card',
      'port_whitelist',
      'search_settings',
      'settings_general_desc',
      'settings_appearance_desc',
      'settings_network_connection_desc',
      'settings_permissions_desc',
      'settings_support_about',
      'settings_support_about_desc',
      'settings_title',
      'settings_title_desc',
      'settings_support_about_short_desc',
      'settings_updates',
      'settings_updates_desc',
      'settings_updates_short_desc',
      'update_channel',
      'update_channel_desc',
      'update_download_source',
      'update_download_source_desc',
      'redownload_update',
      'install_update_permission',
      'install_permission_explanation',
      'permission_install_success',
      'update_operations',
      'update_operations_desc',
      'version_info',
      'version_info_desc',
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
        'copy_support_bundle',
        'copy_support_bundle_warning',
        'enable_tun_adapter',
        'launch_at_login',
        'prefer_astral_adapter',
        'socks5_listen_all_interfaces',
        'settings_language',
        'settings_update_about',
        'update_available_title',
        'update_browser_install_notice',
        'open_release_page',
        'socks5_proxy',
        'support_bundle_copied',
        'update_management_desc',
        'update_check_failed',
        'app_up_to_date',
        'current_version_value',
        'release_channel',
        'alpha_channel',
        'preview_unavailable',
        'preview_unavailable_desc',
        'update_check_failed_desc',
        'virtual_network_access',
      }),
    );
  });
}

Set<String> _translationKeys(String path) {
  final translations = jsonDecode(File(path).readAsStringSync());
  return (translations as Map<String, dynamic>).keys.toSet();
}
