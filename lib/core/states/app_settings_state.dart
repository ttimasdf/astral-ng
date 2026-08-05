import 'package:astral/core/platform/build_brand.dart';
import 'package:signals_flutter/signals_flutter.dart';

/// 应用设置状态
class AppSettingsState {
  // 应用名称
  final appName = signal(BuildBrand.appName);

  // 显示 Android 后台连接通知
  final connectionNotificationEnabled = signal(true);

  // 自动重试失败的连接
  final retryFailedConnections = signal(true);

  // 连接重试次数上限
  final connectionRetryLimit = signal(3);

  // 降低拓扑动画与刷新频率
  final reduceTopologyAnimations = signal(false);

  // 日志列表
  final logs = signal<List<String>>([]);

  void setConnectionNotificationEnabled(bool value) {
    connectionNotificationEnabled.value = value;
  }

  void setRetryFailedConnections(bool value) {
    retryFailedConnections.value = value;
  }

  void setConnectionRetryLimit(int value) {
    connectionRetryLimit.value = value;
  }

  void setReduceTopologyAnimations(bool value) {
    reduceTopologyAnimations.value = value;
  }
}
