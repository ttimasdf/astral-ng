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

  static String getFriendlyVersion() {
    final version = getVersion();
    if (version.isEmpty) return '';
    return formatFriendlyVersion(
      version: version,
      commit: BuildBrand.commit,
      isCanary: BuildBrand.isCanary,
    );
  }

  static String getAboutVersion() {
    final version = getVersion();
    if (version.isEmpty) return '';
    return formatAboutVersion(
      version: version,
      commit: BuildBrand.commit,
      isCanary: BuildBrand.isCanary,
    );
  }

  static String getSemanticVersion() {
    final version = getVersion();
    if (version.isEmpty) return '';
    return formatSemanticVersion(
      version: version,
      commit: BuildBrand.commit,
      runNumber: BuildBrand.runNumber,
      isCanary: BuildBrand.isCanary,
    );
  }

  static String formatFriendlyVersion({
    required String version,
    required String commit,
    required bool isCanary,
  }) {
    if (!isCanary) return version;
    return '$version Canary ${_normalizeCommit(commit)}';
  }

  static String formatAboutVersion({
    required String version,
    required String commit,
    required bool isCanary,
  }) {
    if (!isCanary) return version;
    return '$version-alpha+${_normalizeCommit(commit)}';
  }

  static String formatSemanticVersion({
    required String version,
    required String commit,
    required int runNumber,
    required bool isCanary,
  }) {
    if (!isCanary) return version;
    final normalizedRunNumber = runNumber < 0 ? 0 : runNumber;
    return '$version-alpha.$normalizedRunNumber+'
        '${_normalizeCommit(commit)}';
  }

  static String _normalizeCommit(String commit) {
    final normalized = commit.trim().toLowerCase();
    if (RegExp(r'^[0-9a-f]{7}$').hasMatch(normalized)) {
      return normalized;
    }
    return 'local';
  }
}
