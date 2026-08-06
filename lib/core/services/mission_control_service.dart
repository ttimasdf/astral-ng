import 'package:astral/core/models/mission_control_preferences.dart';
import 'package:astral/core/models/network_config_share.dart';
import 'package:astral/core/models/room.dart';
import 'package:astral/core/repositories/app_settings_repository.dart';
import 'package:astral/core/states/mission_control_state.dart';
import 'package:astral/core/states/network_config_state.dart';

/// Resolves global defaults, room recommendations, and device-local overrides.
class MissionControlService {
  final MissionControlState state;
  final NetworkConfigState networkConfigState;
  final AppSettingsRepository _settingsRepository;

  MissionControlService({
    required this.state,
    required this.networkConfigState,
    required AppSettingsRepository settingsRepository,
  }) : _settingsRepository = settingsRepository;

  Future<void> init() async {
    final settings = await _settingsRepository.get();
    state.replaceAll(
      decodeMissionControlOverrides(settings.missionControlOverridesJson),
    );
  }

  MissionControlPreferences resolve(Room? room) =>
      resolveWithRecommendations(room, roomNetworkRecommendations(room));

  MissionControlPreferences resolveWithRecommendations(
    Room? room,
    NetworkConfigShare? recommendations,
  ) {
    final local = room == null ? null : state.overridesByRoom.value[room.id];

    return resolveMissionControlPreferences(
      globalLatencyFirst: networkConfigState.latencyFirst.value,
      globalRelayOnly: networkConfigState.disableP2p.value,
      globalLanDiscovery: networkConfigState.enableUdpBroadcastRelay.value,
      roomRecommendations: recommendations,
      deviceOverrides: local,
    );
  }

  Future<void> setLatencyFirst(Room room, bool value) async {
    final recommendations = roomNetworkRecommendations(room);
    final base =
        recommendations?.latencyFirst ?? networkConfigState.latencyFirst.value;
    final current = _overridesFor(room);
    await _save(
      room.id,
      current.withLatencyFirst(value == base ? null : value),
    );
  }

  Future<void> setRelayOnly(Room room, bool value) async {
    final recommendations = roomNetworkRecommendations(room);
    final base =
        recommendations?.disableP2p ?? networkConfigState.disableP2p.value;
    final current = _overridesFor(room);
    await _save(room.id, current.withRelayOnly(value == base ? null : value));
  }

  Future<void> setLanDiscovery(Room room, bool value) async {
    final base = networkConfigState.enableUdpBroadcastRelay.value;
    final current = _overridesFor(room);
    await _save(
      room.id,
      current.withLanDiscovery(value == base ? null : value),
    );
  }

  Future<void> clearLatencyFirst(Room room) async {
    await _save(room.id, _overridesFor(room).withLatencyFirst(null));
  }

  Future<void> clearRelayOnly(Room room) async {
    await _save(room.id, _overridesFor(room).withRelayOnly(null));
  }

  Future<void> clearLanDiscovery(Room room) async {
    await _save(room.id, _overridesFor(room).withLanDiscovery(null));
  }

  MissionControlOverrides _overridesFor(Room room) =>
      state.overridesByRoom.value[room.id] ?? const MissionControlOverrides();

  Future<void> _save(int roomId, MissionControlOverrides overrides) async {
    state.setForRoom(roomId, overrides);
    final encoded = encodeMissionControlOverrides(state.overridesByRoom.value);
    await _settingsRepository.update(
      (settings) => settings.missionControlOverridesJson = encoded,
    );
  }
}
