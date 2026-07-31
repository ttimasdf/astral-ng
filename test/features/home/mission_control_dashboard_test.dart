import 'package:astral/core/models/mission_control_preferences.dart';
import 'package:astral/core/models/room.dart';
import 'package:astral/core/states/connection_state.dart';
import 'package:astral/features/home/widgets/mission_control_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final size in [const Size(1200, 850), const Size(390, 844)]) {
    testWidgets('Mission Control has no layout errors at $size', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final room = Room(id: 7, name: 'Orion', simpleMode: true);
      const preferences = MissionControlPreferences(
        latencyFirst: SourcedMissionPreference(
          false,
          MissionPreferenceSource.room,
        ),
        relayOnly: SourcedMissionPreference(
          false,
          MissionPreferenceSource.global,
        ),
        lanDiscovery: SourcedMissionPreference(
          false,
          MissionPreferenceSource.global,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            useMaterial3: true,
            colorSchemeSeed: const Color(0xff168c9b),
          ),
          home: Scaffold(
            body: MissionControlDashboard(
              connectionState: CoState.idle,
              networkStatus: null,
              room: room,
              username: 'Alex',
              virtualIp: '10.126.0.4',
              automaticIp: true,
              encryptedTraffic: true,
              reduceMotion: true,
              effectivePreferences: preferences,
              activePreferences: null,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
    });
  }
}
