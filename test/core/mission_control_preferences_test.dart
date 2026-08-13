import 'package:astral/core/models/mission_control_preferences.dart';
import 'package:astral/core/models/network_config_share.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Mission Control preference resolution', () {
    test('device overrides room recommendations and global defaults', () {
      final result = resolveMissionControlPreferences(
        globalLatencyFirst: false,
        globalRelayOnly: true,
        globalLanDiscovery: false,
        roomRecommendations: NetworkConfigShare(
          latencyFirst: true,
          disableP2p: false,
        ),
        deviceOverrides: const MissionControlOverrides(
          relayOnly: true,
          lanDiscovery: true,
        ),
      );

      expect(result.latencyFirst.value, isTrue);
      expect(result.latencyFirst.source, MissionPreferenceSource.room);
      expect(result.relayOnly.value, isTrue);
      expect(result.relayOnly.source, MissionPreferenceSource.device);
      expect(result.lanDiscovery.value, isTrue);
      expect(result.lanDiscovery.source, MissionPreferenceSource.device);
    });

    test('falls back to global defaults without higher-precedence values', () {
      final result = resolveMissionControlPreferences(
        globalLatencyFirst: true,
        globalRelayOnly: false,
        globalLanDiscovery: true,
      );

      expect(result.latencyFirst.source, MissionPreferenceSource.global);
      expect(result.relayOnly.source, MissionPreferenceSource.global);
      expect(result.lanDiscovery.source, MissionPreferenceSource.global);
    });

    test(
      'pending comparison ignores provenance and compares active values',
      () {
        const active = MissionControlPreferences(
          latencyFirst: SourcedMissionPreference(
            true,
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
        const desired = MissionControlPreferences(
          latencyFirst: SourcedMissionPreference(
            true,
            MissionPreferenceSource.device,
          ),
          relayOnly: SourcedMissionPreference(
            false,
            MissionPreferenceSource.room,
          ),
          lanDiscovery: SourcedMissionPreference(
            false,
            MissionPreferenceSource.device,
          ),
        );

        expect(active.hasSameValues(desired), isTrue);
      },
    );
  });

  group('Mission Control override persistence', () {
    test('round trips sparse per-room overrides', () {
      const source = {
        4: MissionControlOverrides(latencyFirst: true),
        9: MissionControlOverrides(relayOnly: true, lanDiscovery: false),
      };

      final decoded = decodeMissionControlOverrides(
        encodeMissionControlOverrides(source),
      );

      expect(decoded[4]?.latencyFirst, isTrue);
      expect(decoded[4]?.relayOnly, isNull);
      expect(decoded[9]?.relayOnly, isTrue);
      expect(decoded[9]?.lanDiscovery, isFalse);
    });

    test('treats malformed persisted data as empty', () {
      expect(decodeMissionControlOverrides('{bad json'), isEmpty);
      expect(decodeMissionControlOverrides('[]'), isEmpty);
    });
  });
}
