import 'package:astral/core/models/mission_control_preferences.dart';
import 'package:astral/src/rust/api/simple.dart';
import 'package:signals_flutter/signals_flutter.dart';

/// 连接状态
enum CoState { idle, connecting, connected }

class ConnectionState {
  // 连接状态
  final connectionState = signal(CoState.idle);

  // 网络状态
  final netStatus = signal<KVNetworkStatus?>(null);

  // 当前 EasyTier 会话实际采用的 Mission Control 偏好。
  final activeMissionPreferences = signal<MissionControlPreferences?>(null);

  // 当前 EasyTier 会话实际采用的流量加密设置。
  final activeTrafficEncryption = signal<bool?>(null);
}
