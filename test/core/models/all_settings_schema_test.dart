import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AllSettings uses current developer-facing property names', () {
    final source = File('lib/core/models/all_settings.dart').readAsStringSync();

    for (final property in {
      'androidVpnRoutes',
      'compactPeerCards',
      'connectionNotificationEnabled',
      'launchAtLogin',
      'preferAstralAdapter',
      'updateDownloadSource',
    }) {
      expect(source, contains(property));
    }

    for (final legacyProperty in {
      'autoSetMTU',
      'closeMinimize',
      'settingsSchemaVersion',
      'userListSimple',
    }) {
      expect(source, isNot(contains(legacyProperty)));
    }
  });
}
