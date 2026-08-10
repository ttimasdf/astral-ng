import 'package:signals_flutter/signals_flutter.dart';

/// 启动相关状态
class StartupState {
  final launchAtLogin = signal(false);
  final launchToTray = signal(false);
  final connectAfterLaunch = signal(false);

  void setLaunchAtLogin(bool value) {
    launchAtLogin.value = value;
  }

  void setLaunchToTray(bool value) {
    launchToTray.value = value;
  }

  void setConnectAfterLaunch(bool value) {
    connectAfterLaunch.value = value;
  }

  void updateAll({
    required bool launchAtLogin,
    required bool launchToTray,
    required bool connectAfterLaunch,
  }) {
    this.launchAtLogin.value = launchAtLogin;
    this.launchToTray.value = launchToTray;
    this.connectAfterLaunch.value = connectAfterLaunch;
  }
}
