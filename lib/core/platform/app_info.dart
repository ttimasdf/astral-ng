import 'package:astral/core/platform/build_brand.dart';
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

    return formatVersionDisplay(
      version: packageInfo.version,
      buildNumber: packageInfo.buildNumber,
      isCanary: BuildBrand.isCanary,
    );
  }

  static String formatVersionDisplay({
    required String version,
    required String buildNumber,
    required bool isCanary,
  }) {
    if (!isCanary) return version;

    final parsedBuildNumber = int.tryParse(buildNumber);
    if (parsedBuildNumber != null && parsedBuildNumber >= 1000000000) {
      return '$version Canary · build $parsedBuildNumber';
    }
    return '$version Canary';
  }
}
