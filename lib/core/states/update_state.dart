import 'package:signals_flutter/signals_flutter.dart';

import 'package:astral/shared/utils/github_proxy_selector.dart';

/// 更新相关状态
class UpdateState {
  /// 是否接收 Beta 更新
  final receiveBetaUpdates = signal(false);

  /// 是否自动检查更新
  final automaticUpdateChecks = signal(true);

  /// 更新包下载源（`auto` = 自动选择镜像，`''` = 直连 GitHub）
  final updateDownloadSource = signal(GitHubProxySelector.autoMode);

  /// 自动模式下最近一次测速选中的镜像前缀
  final resolvedUpdateDownloadSource = signal<String?>(null);

  /// 最近一次检查到的最新版本号
  final latestVersion = signal<String?>(null);

  void setReceiveBetaUpdates(bool value) {
    receiveBetaUpdates.value = value;
  }

  void setAutomaticUpdateChecks(bool value) {
    automaticUpdateChecks.value = value;
  }

  void setUpdateDownloadSource(String value) {
    updateDownloadSource.value = value;
    if (!GitHubProxySelector.isAutoMode(value)) {
      resolvedUpdateDownloadSource.value = null;
    }
  }

  void setResolvedUpdateDownloadSource(String? value) {
    resolvedUpdateDownloadSource.value = value;
  }

  void setLatestVersion(String? version) {
    latestVersion.value = version;
  }

  /// 仅表示已经拿到可用版本号，不代表一定高于当前版本
  late final hasNewVersion = computed(() {
    final version = latestVersion.value;
    return version != null && version.trim().isNotEmpty;
  });
}
