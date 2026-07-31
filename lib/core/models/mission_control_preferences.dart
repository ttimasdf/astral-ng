import 'dart:convert';

import 'package:astral/core/models/network_config_share.dart';
import 'package:astral/core/models/room.dart';

/// Where an effective Mission Control preference came from.
enum MissionPreferenceSource { global, room, device }

/// One effective setting and the layer that supplied it.
class SourcedMissionPreference {
  final bool value;
  final MissionPreferenceSource source;

  const SourcedMissionPreference(this.value, this.source);
}

/// The three outcome-oriented preferences exposed by Mission Control.
class MissionControlPreferences {
  final SourcedMissionPreference latencyFirst;
  final SourcedMissionPreference relayOnly;
  final SourcedMissionPreference lanDiscovery;

  const MissionControlPreferences({
    required this.latencyFirst,
    required this.relayOnly,
    required this.lanDiscovery,
  });

  bool hasSameValues(MissionControlPreferences other) =>
      latencyFirst.value == other.latencyFirst.value &&
      relayOnly.value == other.relayOnly.value &&
      lanDiscovery.value == other.lanDiscovery.value;
}

/// Optional per-room choices made on this device.
class MissionControlOverrides {
  final bool? latencyFirst;
  final bool? relayOnly;
  final bool? lanDiscovery;

  const MissionControlOverrides({
    this.latencyFirst,
    this.relayOnly,
    this.lanDiscovery,
  });

  bool get isEmpty =>
      latencyFirst == null && relayOnly == null && lanDiscovery == null;

  MissionControlOverrides withLatencyFirst(bool? value) =>
      MissionControlOverrides(
        latencyFirst: value,
        relayOnly: relayOnly,
        lanDiscovery: lanDiscovery,
      );

  MissionControlOverrides withRelayOnly(bool? value) => MissionControlOverrides(
    latencyFirst: latencyFirst,
    relayOnly: value,
    lanDiscovery: lanDiscovery,
  );

  MissionControlOverrides withLanDiscovery(bool? value) =>
      MissionControlOverrides(
        latencyFirst: latencyFirst,
        relayOnly: relayOnly,
        lanDiscovery: value,
      );

  Map<String, dynamic> toJson() => {
    if (latencyFirst != null) 'latencyFirst': latencyFirst,
    if (relayOnly != null) 'relayOnly': relayOnly,
    if (lanDiscovery != null) 'lanDiscovery': lanDiscovery,
  };

  factory MissionControlOverrides.fromJson(Map<String, dynamic> json) =>
      MissionControlOverrides(
        latencyFirst: json['latencyFirst'] as bool?,
        relayOnly: json['relayOnly'] as bool?,
        lanDiscovery: json['lanDiscovery'] as bool?,
      );
}

MissionControlPreferences resolveMissionControlPreferences({
  required bool globalLatencyFirst,
  required bool globalRelayOnly,
  required bool globalLanDiscovery,
  NetworkConfigShare? roomRecommendations,
  MissionControlOverrides? deviceOverrides,
}) {
  SourcedMissionPreference resolve(bool? device, bool? room, bool global) {
    if (device != null) {
      return SourcedMissionPreference(device, MissionPreferenceSource.device);
    }
    if (room != null) {
      return SourcedMissionPreference(room, MissionPreferenceSource.room);
    }
    return SourcedMissionPreference(global, MissionPreferenceSource.global);
  }

  return MissionControlPreferences(
    latencyFirst: resolve(
      deviceOverrides?.latencyFirst,
      roomRecommendations?.latencyFirst,
      globalLatencyFirst,
    ),
    relayOnly: resolve(
      deviceOverrides?.relayOnly,
      roomRecommendations?.disableP2p,
      globalRelayOnly,
    ),
    lanDiscovery: resolve(
      deviceOverrides?.lanDiscovery,
      null,
      globalLanDiscovery,
    ),
  );
}

/// Decodes room recommendations without making the UI depend on share-code data.
NetworkConfigShare? roomNetworkRecommendations(Room? room) {
  if (room == null || room.networkConfigJson.isEmpty) return null;
  return NetworkConfigShare.fromJsonString(room.networkConfigJson);
}

Map<int, MissionControlOverrides> decodeMissionControlOverrides(String source) {
  if (source.trim().isEmpty) return {};

  try {
    final decoded = jsonDecode(source);
    if (decoded is! Map<String, dynamic>) return {};

    final result = <int, MissionControlOverrides>{};
    for (final entry in decoded.entries) {
      final roomId = int.tryParse(entry.key);
      final value = entry.value;
      if (roomId == null || value is! Map<String, dynamic>) continue;
      final overrides = MissionControlOverrides.fromJson(value);
      if (!overrides.isEmpty) result[roomId] = overrides;
    }
    return result;
  } catch (_) {
    return {};
  }
}

String encodeMissionControlOverrides(
  Map<int, MissionControlOverrides> overrides,
) => jsonEncode({
  for (final entry in overrides.entries)
    if (!entry.value.isEmpty) entry.key.toString(): entry.value.toJson(),
});
