import 'dart:convert';
import 'package:astral/core/platform/app_info.dart';
import 'package:astral/core/services/service_manager.dart';
import 'package:astral/shared/utils/version_util.dart';
import 'package:http/http.dart' as http;

enum UpdateCheckKind { updateAvailable, upToDate, failed }

class UpdateCheckResult {
  final UpdateCheckKind kind;
  final String version;
  final String releaseNotes;
  final String releasePage;
  final Map<String, dynamic>? releaseInfo;

  const UpdateCheckResult({
    required this.kind,
    required this.version,
    required this.releaseNotes,
    required this.releasePage,
    this.releaseInfo,
  });

  bool get isLatestVersion => kind == UpdateCheckKind.upToDate;
}

/// 应用更新检查（纯 IO / 逻辑，不含 UI）
class UpdateChecker {
  static const _requestTimeout = Duration(seconds: 15);

  final String owner;
  final String repo;
  final String branch;

  UpdateChecker({
    required this.owner,
    required this.repo,
    this.branch = 'main',
  });

  Future<UpdateCheckResult?> check({
    bool showNoUpdateMessage = true,
    bool forceShowDownload = false,
    bool showFailureMessage = true,
  }) async {
    try {
      final releaseInfo = await _fetchLatestRelease(
        includePrereleases:
            ServiceManager().updateState.receiveBetaUpdates.value,
      );
      if (releaseInfo == null) {
        if (!showFailureMessage) return null;
        return UpdateCheckResult(
          kind: UpdateCheckKind.failed,
          version: '检查更新失败',
          releaseNotes: '无法获取最新版本信息',
          releasePage: _releasesPage,
        );
      }

      final currentVersion = await _getCurrentVersion();
      final latestVersion = _extractString(releaseInfo, 'tag_name');
      if (latestVersion.isEmpty) {
        if (!showFailureMessage) return null;
        return UpdateCheckResult(
          kind: UpdateCheckKind.failed,
          version: '检查更新失败',
          releaseNotes: '无法解析版本号',
          releasePage: _releasesPage,
        );
      }

      await ServiceManager().appSettings.updateLatestVersion(latestVersion);

      final releaseNotes = _extractString(
        releaseInfo,
        'body',
        fallback: '新版本已发布',
      );
      final releasePage = _extractString(
        releaseInfo,
        'html_url',
        fallback: _releasesPage,
      );

      if (VersionUtil.hasNewVersion(currentVersion, latestVersion) ||
          forceShowDownload) {
        return UpdateCheckResult(
          kind: UpdateCheckKind.updateAvailable,
          version: latestVersion,
          releaseNotes: releaseNotes,
          releasePage: releasePage,
          releaseInfo: releaseInfo,
        );
      }

      if (!showNoUpdateMessage) return null;
      return UpdateCheckResult(
        kind: UpdateCheckKind.upToDate,
        version: '当前已是最新版本',
        releaseNotes: '当前版本为: $currentVersion',
        releasePage: _releasesPage,
      );
    } catch (e) {
      if (!showFailureMessage) return null;
      return UpdateCheckResult(
        kind: UpdateCheckKind.failed,
        version: '更新检查失败',
        releaseNotes: '检查更新时发生错误: $e',
        releasePage: _releasesPage,
      );
    }
  }

  String get _releasesPage => 'https://github.com/$owner/$repo/releases';

  Future<Map<String, dynamic>?> _fetchLatestRelease({
    bool includePrereleases = false,
  }) async {
    try {
      final apiUrl =
          'https://api.github.com/repos/$owner/$repo/releases?per_page=20';

      final response = await http
          .get(
            Uri.parse(apiUrl),
            headers: {
              'Accept': 'application/vnd.github.v3+json',
              'User-Agent': 'astral',
            },
          )
          .timeout(_requestTimeout);

      if (response.statusCode != 200) {
        return null;
      }

      final decoded = json.decode(response.body);
      if (decoded is! List) {
        return null;
      }

      for (final item in decoded) {
        if (item is! Map) {
          continue;
        }
        final release = Map<String, dynamic>.from(item);
        final isDraft = release['draft'] == true;
        final isPrerelease = release['prerelease'] == true;
        if (isDraft) continue;
        if (!includePrereleases && isPrerelease) continue;
        return release;
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  Future<String> _getCurrentVersion() async {
    try {
      return AppInfoUtil.getSemanticVersion();
    } catch (_) {
      return '0.0.0';
    }
  }

  String _extractString(
    Map<String, dynamic> source,
    String key, {
    String fallback = '',
  }) {
    final value = source[key];
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    return fallback;
  }
}
