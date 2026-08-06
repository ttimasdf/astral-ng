import 'package:astral/core/models/mission_control_preferences.dart';
import 'package:astral/core/services/service_manager.dart';
import 'package:astral/core/states/connection_state.dart';
import 'package:astral/features/home/widgets/mission_control_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final services = ServiceManager();

    return Scaffold(
      body: Watch((context) {
        final connectionState = services.connectionState.connectionState.watch(
          context,
        );
        final networkStatus = services.connectionState.netStatus.watch(context);
        final activePreferences = services
            .connectionState
            .activeMissionPreferences
            .watch(context);
        final activeTrafficEncryption = services
            .connectionState
            .activeTrafficEncryption
            .watch(context);
        final room = services.roomState.selectedRoom.watch(context);
        final username = services.playerState.playerName.watch(context);
        final virtualIp = services.networkConfigState.ipv4.watch(context);
        final automaticIp = services.networkConfigState.dhcp.watch(context);
        final globalTrafficEncryption = services
            .networkConfigState
            .enableEncryption
            .watch(context);
        final reduceMotion = services.appSettingsState.reduceAnimationUpdates
            .watch(context);

        // Establish reactive dependencies used by preference resolution.
        services.networkConfigState.latencyFirst.watch(context);
        services.networkConfigState.disableP2p.watch(context);
        services.networkConfigState.enableUdpBroadcastRelay.watch(context);
        services.missionControlState.overridesByRoom.watch(context);
        final effectivePreferences = services.missionControl.resolve(room);
        final desiredTrafficEncryption =
            roomNetworkRecommendations(room)?.enableEncryption ??
            globalTrafficEncryption;
        final encryptedTraffic =
            connectionState == CoState.idle
                ? desiredTrafficEncryption
                : activeTrafficEncryption ?? desiredTrafficEncryption;

        return MissionControlDashboard(
          connectionState: connectionState,
          networkStatus: networkStatus,
          room: room,
          username: username,
          virtualIp: virtualIp,
          automaticIp: automaticIp,
          encryptedTraffic: encryptedTraffic,
          reduceMotion: reduceMotion,
          effectivePreferences: effectivePreferences,
          activePreferences: activePreferences,
        );
      }),
    );
  }
}
