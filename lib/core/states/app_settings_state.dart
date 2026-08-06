import 'package:astral/core/platform/build_brand.dart';
import 'package:signals_flutter/signals_flutter.dart';

/// 应用设置状态
class AppSettingsState {
  // 应用名称
  final appName = signal(BuildBrand.appName);

  // 显示 Android 后台连接通知
  final connectionNotificationEnabled = signal(true);

  // 连接失败后的重试次数，0 表示禁用
  final connectionRetryLimit = signal(3);

  // 降低拓扑动画与刷新频率
  final reduceTopologyAnimations = signal(false);

  // 日志列表
  final logs = signal<List<String>>([]);

  void setConnectionNotificationEnabled(bool value) {
    connectionNotificationEnabled.value = value;
  }

  void setConnectionRetryLimit(int value) {
    connectionRetryLimit.value = value.clamp(0, 10).toInt();
  }

  void setReduceTopologyAnimations(bool value) {
    reduceTopologyAnimations.value = value;
  }
}
