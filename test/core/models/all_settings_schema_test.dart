import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AllSettings uses current developer-facing property names', () {
    final source = File('lib/core/models/all_settings.dart').readAsStringSync();

    for (final property in {
      'androidVpnRoutes',
      'compactPeerCards',
      'connectionNotificationEnabled',
      'connectionRetryLimit',
      'launchAtLogin',
      'preferAstralAdapter',
      'updateDownloadSource',
    }) {
      expect(source, contains(property));
    }

    for (final legacyProperty in {
      'autoSetMTU',
      'closeMinimize',
      'retryFailedConnections',
      'settingsSchemaVersion',
      'userListSimple',
    }) {
      expect(source, isNot(contains(legacyProperty)));
    }
  });

  test('AppSettingsState does not restore the legacy log list', () {
    final source =
        File('lib/core/states/app_settings_state.dart').readAsStringSync();

    expect(source, isNot(contains('signal<List<String>>')));
    expect(source, isNot(contains('final logs')));
  });

  test('NetConfig stores the SOCKS5 bind scope', () {
    final source = File('lib/core/models/net_config.dart').readAsStringSync();

    expect(source, contains('socks5_listen_all_interfaces'));
    expect(source, contains('bool socks5_listen_all_interfaces = false'));
  });
}
