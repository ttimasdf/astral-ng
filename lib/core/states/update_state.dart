import 'package:signals_flutter/signals_flutter.dart';

/// 更新相关状态
class UpdateState {
  /// 是否接收 Beta 更新
  final receiveBetaUpdates = signal(false);

  /// 是否自动检查更新
  final automaticUpdateChecks = signal(true);

  void setReceiveBetaUpdates(bool value) {
    receiveBetaUpdates.value = value;
  }

  void setAutomaticUpdateChecks(bool value) {
    automaticUpdateChecks.value = value;
  }
}
