import 'package:package_info_plus/package_info_plus.dart';

/// 应用包信息工具
class AppInfoUtil {
  static PackageInfo? _packageInfo;

  /// 初始化应用信息
  static Future<void> init() async {
    _packageInfo = await PackageInfo.fromPlatform();
  }

  /// 获取应用版本号 (例如: 1.0.0).
  static String getVersion() => _packageInfo?.version ?? '';

  static String getBuildNumber() => _packageInfo?.buildNumber ?? '';

  /// Human-readable version, including the CI canary channel when applicable.
  static String getVersionDisplay() {
    final packageInfo = _packageInfo;
    if (packageInfo == null) return '';

    final buildNumber = int.tryParse(packageInfo.buildNumber);
    if (buildNumber != null && buildNumber >= 1000000000) {
      return '${packageInfo.version} (canary $buildNumber)';
    }
    return packageInfo.version;
  }
}
