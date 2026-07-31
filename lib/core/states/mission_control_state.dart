import 'package:astral/core/models/mission_control_preferences.dart';
import 'package:signals_flutter/signals_flutter.dart';

/// Device-local per-room overrides for Mission Control.
class MissionControlState {
  final overridesByRoom = signal<Map<int, MissionControlOverrides>>({});

  void replaceAll(Map<int, MissionControlOverrides> overrides) {
    overridesByRoom.value = Map.unmodifiable(overrides);
  }

  void setForRoom(int roomId, MissionControlOverrides overrides) {
    final next = Map<int, MissionControlOverrides>.from(overridesByRoom.value);
    if (overrides.isEmpty) {
      next.remove(roomId);
    } else {
      next[roomId] = overrides;
    }
    overridesByRoom.value = Map.unmodifiable(next);
  }
}
