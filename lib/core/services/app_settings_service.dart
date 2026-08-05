import 'package:astral/core/services/service_manager.dart';
import 'dart:io';

import 'package:astral/core/states/player_state.dart';
import 'package:astral/core/states/display_state.dart';
import 'package:astral/core/states/startup_state.dart';
import 'package:astral/core/states/update_state.dart';
import 'package:astral/core/states/window_state.dart';
import 'package:astral/core/states/vpn_state.dart';
import 'package:astral/core/states/app_settings_state.dart';
import 'package:astral/core/repositories/app_settings_repository.dart';
import 'package:astral/core/database/dao/all_settings_dao.dart';
import 'package:astral/core/platform/startup_url_scheme.dart';

/// 应用设置服务：协调 State 与持久化
class AppSettingsService {
  final PlayerState playerState;
  final DisplayState displayState;
  final StartupState startupState;
  final UpdateState updateState;
  final WindowState windowState;
  final VpnState vpnState;
  final AppSettingsState appSettingsState;
  final AppSettingsRepository _repo;

  AppSettingsService({
    required this.playerState,
    required this.displayState,
    required this.startupState,
    required this.updateState,
    required this.windowState,
    required this.vpnState,
    required this.appSettingsState,
    required AppSettingsRepository repository,
  }) : _repo = repository;

  Future<void> init() async {
    final settings = await _repo.get();
    final listenList = await _repo.getListenList();
    final playerName = await _repo.getPlayerName();

    playerState.updatePlayerName(playerName);
    playerState.setListenList(listenList);

    displayState.setCompactPeerCards(settings.compactPeerCards);
    displayState.setSortOption(
      UserSortOption.fromIndex(settings.peerSortOption),
    );
    displayState.setSortOrder(UserSortOrder.fromIndex(settings.peerSortOrder));
    displayState.setDisplayMode(
      UserDisplayMode.fromIndex(settings.peerDisplayMode),
    );

    startupState.updateAll(
      launchAtLogin: settings.launchAtLogin,
      launchToTray: settings.launchToTray,
      connectAfterLaunch: settings.connectAfterLaunch,
    );

    updateState.setReceiveBetaUpdates(settings.receiveBetaUpdates);
    updateState.setAutomaticUpdateChecks(settings.automaticUpdateChecks);

    updateState.setUpdateDownloadSource(settings.updateDownloadSource);
    updateState.setLatestVersion(settings.latestAvailableVersion);

    appSettingsState.setConnectionNotificationEnabled(
      settings.connectionNotificationEnabled,
    );
    appSettingsState.setReduceTopologyAnimations(
      settings.reduceTopologyAnimations,
    );
    appSettingsState.setRetryFailedConnections(settings.retryFailedConnections);
    appSettingsState.setConnectionRetryLimit(settings.connectionRetryLimit);

    windowState.setCloseBehavior(
      settings.closeToTray
          ? WindowCloseBehavior.closeToTray
          : WindowCloseBehavior.exitProgram,
    );
    vpnState.setAndroidVpnRoutes(List<String>.from(settings.androidVpnRoutes));
  }

  Future<void> updatePlayerName(String name) async {
    playerState.updatePlayerName(name);
    await _repo.update((s) => s.peerName = name);
  }

  Future<void> setListenList(List<String> list) async {
    playerState.setListenList(list);
    await _repo.update((s) => s.peerListeners = list);
  }

  Future<void> addListen(String listen) async {
    playerState.addListen(listen);
    await _repo.update((s) => s.peerListeners = playerState.listenList.value);
  }

  Future<void> deleteListen(int index) async {
    playerState.removeListen(index);
    await _repo.update((s) => s.peerListeners = playerState.listenList.value);
  }

  Future<void> updateListen(int index, String listen) async {
    await _repo.update((s) {
      s.peerListeners ??= List<String>.from(AllSettingsDao.defaultListenList);
      s.peerListeners![index] = listen;
    });
    playerState.setListenList(await _repo.getListenList());
  }

  Future<void> setCompactPeerCards(bool value) async {
    displayState.setCompactPeerCards(value);
    await _repo.update((s) => s.compactPeerCards = value);
  }

  Future<void> setSortOption(UserSortOption option) async {
    displayState.setSortOption(option);
    await _repo.update((s) => s.peerSortOption = option.index);
  }

  Future<void> setSortOrder(UserSortOrder order) async {
    displayState.setSortOrder(order);
    await _repo.update((s) => s.peerSortOrder = order.index);
  }

  Future<void> setDisplayMode(UserDisplayMode mode) async {
    displayState.setDisplayMode(mode);
    await _repo.update((s) => s.peerDisplayMode = mode.index);
  }

  Future<void> setLaunchAtLogin(bool value) async {
    startupState.setLaunchAtLogin(value);
    await _repo.update((s) => s.launchAtLogin = value);
    await handleStartupSetting(value);
  }

  Future<void> setLaunchToTray(bool value) async {
    startupState.setLaunchToTray(value);
    await _repo.update((s) => s.launchToTray = value);
  }

  Future<void> setConnectAfterLaunch(bool value) async {
    startupState.setConnectAfterLaunch(value);
    await _repo.update((s) => s.connectAfterLaunch = value);
  }

  Future<void> setReceiveBetaUpdates(bool value) async {
    updateState.setReceiveBetaUpdates(value);
    await _repo.update((s) => s.receiveBetaUpdates = value);
  }

  Future<void> setAutomaticUpdateChecks(bool value) async {
    updateState.setAutomaticUpdateChecks(value);
    await _repo.update((s) => s.automaticUpdateChecks = value);
  }

  Future<void> setUpdateDownloadSource(String value) async {
    updateState.setUpdateDownloadSource(value);
    await _repo.update((s) => s.updateDownloadSource = value);
  }

  Future<void> updateLatestVersion(String version) async {
    updateState.setLatestVersion(version);
    await _repo.update((s) => s.latestAvailableVersion = version);
  }

  Future<void> setConnectionNotificationEnabled(bool enabled) async {
    appSettingsState.setConnectionNotificationEnabled(enabled);
    await _repo.update((s) => s.connectionNotificationEnabled = enabled);

    if (!enabled && Platform.isAndroid) {
      await ServiceManager().notifications.cancelConnectionNotification();
    }
  }

  Future<void> setReduceTopologyAnimations(bool value) async {
    appSettingsState.setReduceTopologyAnimations(value);
    await _repo.update((s) => s.reduceTopologyAnimations = value);
  }

  Future<void> setRetryFailedConnections(bool value) async {
    appSettingsState.setRetryFailedConnections(value);
    await _repo.update((s) => s.retryFailedConnections = value);
  }

  Future<void> setConnectionRetryLimit(int limit) async {
    appSettingsState.setConnectionRetryLimit(limit);
    await _repo.update((s) => s.connectionRetryLimit = limit);
  }

  Future<void> updateWindowCloseBehavior(WindowCloseBehavior value) async {
    windowState.setCloseBehavior(value);
    await _repo.update(
      (s) => s.closeToTray = value == WindowCloseBehavior.closeToTray,
    );
  }

  Future<void> addAndroidVpnRoute(String route) async {
    vpnState.addAndroidVpnRoute(route);
    await _repo.update(
      (s) => s.androidVpnRoutes = vpnState.androidVpnRoutes.value,
    );
  }

  Future<void> deleteAndroidVpnRoute(int index) async {
    vpnState.removeAndroidVpnRoute(index);
    await _repo.update(
      (s) => s.androidVpnRoutes = vpnState.androidVpnRoutes.value,
    );
  }

  Future<void> updateAndroidVpnRoute(int index, String route) async {
    await _repo.update((s) => s.androidVpnRoutes[index] = route);
    vpnState.setAndroidVpnRoutes(
      List<String>.from((await _repo.get()).androidVpnRoutes),
    );
  }
}
