import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:uuid/uuid.dart';
import 'package:astral/core/builders/server_config_builder.dart';
import 'package:astral/core/diagnostics/diagnostic_context.dart';
import 'package:astral/core/diagnostics/diagnostic_modules.dart';
import 'package:astral/core/diagnostics/diagnostics_runtime.dart';
import 'package:astral/core/diagnostics/module_logger.dart';
import 'package:astral/core/models/network_config_share.dart';
import 'package:astral/core/services/connection_network_monitor.dart';
import 'package:astral/core/services/connection_status_tracker.dart';
import 'package:astral/core/services/service_manager.dart';
import 'package:astral/core/states/connection_state.dart';
import 'package:astral/core/services/notification_service.dart';
import 'package:astral/src/rust/api/simple.dart';
import 'package:astral/src/rust/api/hops.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:isar_community/isar.dart';

/// 服务器连接管理器
///
/// 负责管理服务器连接、断开、状态监控等核心功能
class ServerConnectionManager {
  static ServerConnectionManager? _instance;

  final _networkMonitor = ConnectionNetworkMonitor();
  late final ConnectionStatusTracker _statusTracker;
  int _currentRetryCount = 0; // 当前重试次数
  Completer<bool>? _connectionCompleter; // 用于取消连接的 Completer
  String? _connectionAttemptId;

  static const int connectionTimeoutSeconds = 15;

  ServerConnectionManager._() {
    _statusTracker = ConnectionStatusTracker();
    _statusTracker.onTimeout = () => disconnect();
    _statusTracker.onConnected = _handleSuccessfulConnection;
  }

  /// 获取单例实例
  static ServerConnectionManager get instance {
    _instance ??= ServerConnectionManager._();
    return _instance!;
  }

  /// 取消当前连接（包括重试）
  Future<void> cancelConnection() async {
    // 完成 Completer（如果存在且未完成）
    if (_connectionCompleter != null && !_connectionCompleter!.isCompleted) {
      _connectionCompleter!.complete(false);
    }

    // 立即断开连接
    await disconnect();
  }

  /// 开始连接流程（手动连接）
  /// 返回值：true=成功, false=失败, null=用户取消
  Future<bool?> connect({bool isManual = true}) async {
    final services = ServiceManager();

    // 检查状态
    if (services.connectionState.connectionState.value != CoState.idle) {
      return false;
    }

    final room = services.roomState.selectedRoom.value;
    if (room == null) return false;

    services.connectionState.activeMissionPreferences.value = null;
    services.connectionState.activeTrafficEncryption.value = null;

    final attemptId = const Uuid().v4().split('-').first.toUpperCase();
    _connectionAttemptId = attemptId;
    return DiagnosticContext.run(
      DiagnosticContext(connectionAttemptId: attemptId),
      () => _runCorrelatedConnectionAttempt(
        services: services,
        room: room,
        isManual: isManual,
        attemptId: attemptId,
      ),
    );
  }

  Future<bool?> _runCorrelatedConnectionAttempt({
    required ServiceManager services,
    required dynamic room,
    required bool isManual,
    required String attemptId,
  }) async {
    final log = Diagnostics.logger(DiagnosticModules.connection);
    final stopwatch = Stopwatch()..start();
    final timeline =
        developer.TimelineTask()..start(
          'connection.attempt',
          arguments: {'attempt': attemptId, 'manual': isManual},
        );
    log.info(
      'connect.start',
      'Connection attempt started',
      fields: {'manual': isManual},
    );
    try {
      final result = await _executeConnectionAttempt(
        services: services,
        room: room,
        isManual: isManual,
        log: log,
      );
      final fields = {
        'duration_ms': stopwatch.elapsedMilliseconds,
        'retries': _currentRetryCount,
      };
      if (result == true) {
        log.info(
          'connect.complete',
          'Connection attempt completed',
          fields: fields,
        );
        _currentRetryCount = 0;
      } else if (result == null) {
        log.info(
          'connect.cancelled',
          'Connection attempt was cancelled',
          fields: fields,
        );
      } else {
        log.warning(
          'connect.failed',
          'Connection attempt failed',
          fields: fields,
        );
      }
      return result;
    } catch (error, stack) {
      log.error(
        'connect.failed',
        'Connection attempt failed unexpectedly',
        fields: {'duration_ms': stopwatch.elapsedMilliseconds},
        error: error,
        stackTrace: stack,
      );
      rethrow;
    } finally {
      timeline.finish(
        arguments: {'duration_ms': stopwatch.elapsedMilliseconds},
      );
    }
  }

  Future<bool?> _executeConnectionAttempt({
    required ServiceManager services,
    required dynamic room,
    required bool isManual,
    required ModuleLogger log,
  }) async {
    // 如果是手动连接，清空重试次数
    if (isManual) {
      _currentRetryCount = 0;
    }

    // 创建 Completer 用于取消
    _connectionCompleter = Completer<bool>();

    // 获取重试设置
    final autoRetry = services.appSettingsState.autoRetryOnFailure.value;
    final maxRetries = services.appSettingsState.maxRetryCount.value;

    bool success = false;

    do {
      _currentRetryCount++;

      if (_currentRetryCount > 1) {
        // 等待一段时间再重试
        await Future.delayed(Duration(seconds: 2));
      }

      try {
        // 检查是否被取消
        if (_connectionCompleter != null && _connectionCompleter!.isCompleted) {
          services.connectionState.connectionState.value = CoState.idle;
          return null; // 用户取消
        }

        // 清理旧连接
        await closeServer();

        // 检查服务器配置
        final enabledServers =
            services.serverState.servers.value
                .where((server) => server.enable)
                .toList();
        final hasRoomServers = room.servers.isNotEmpty;

        if (enabledServers.isEmpty && !hasRoomServers) {
          services.connectionState.connectionState.value = CoState.idle;
          return false;
        }

        // 准备VPN（Android，NO-TUN 模式下由 Clash 等工具接管）
        if (Platform.isAndroid && !services.networkConfigState.noTun.value) {
          await ServiceManager().notifications.initialize();
          await ServiceManager().vpn.prepare();
        } else if (Platform.isAndroid) {
          await ServiceManager().notifications.initialize();
        }

        // 初始化服务器
        await _initializeServer(room);

        // 开始连接流程
        await _beginConnectionProcess();

        // 等待连接结果
        success = await _statusTracker.waitForConnectionResult();

        // 检查是否被取消
        if (_connectionCompleter != null && _connectionCompleter!.isCompleted) {
          await disconnect();
          services.connectionState.connectionState.value = CoState.idle;
          return null; // 用户取消
        }

        if (success) {
          if (_connectionCompleter != null &&
              !_connectionCompleter!.isCompleted) {
            _connectionCompleter!.complete(true);
          }
          _connectionCompleter = null;
          return true;
        }

        // 如果连接失败且不需要重试，则退出
        if (!autoRetry || _currentRetryCount >= maxRetries) {
          services.connectionState.connectionState.value = CoState.idle;
          if (_connectionCompleter != null &&
              !_connectionCompleter!.isCompleted) {
            _connectionCompleter!.complete(false);
          }
          _connectionCompleter = null;
          return false;
        }

        // 断开当前失败的连接
        await disconnect();

        // 检查是否在断开后被取消（Completer 已被清空）
        if (_connectionCompleter == null) {
          services.connectionState.connectionState.value = CoState.idle;
          return null; // 用户取消
        }
      } catch (e, stack) {
        log.warning(
          'connect.retry.failed',
          'Connection attempt iteration failed',
          fields: {'retry': _currentRetryCount},
          error: e,
          stackTrace: stack,
        );

        // 检查是否被取消
        if (_connectionCompleter != null && _connectionCompleter!.isCompleted) {
          services.connectionState.connectionState.value = CoState.idle;
          return null; // 用户取消
        }

        // 如果连接失败且不需要重试，则退出
        if (!autoRetry || _currentRetryCount >= maxRetries) {
          services.connectionState.connectionState.value = CoState.idle;
          if (_connectionCompleter != null &&
              !_connectionCompleter!.isCompleted) {
            _connectionCompleter!.complete(false);
          }
          _connectionCompleter = null;
          return false;
        }

        // 断开当前失败的连接
        await disconnect();

        // 检查是否在断开后被取消（Completer 已被清空）
        if (_connectionCompleter == null) {
          services.connectionState.connectionState.value = CoState.idle;
          return null; // 用户取消
        }
      }
    } while (autoRetry && _currentRetryCount < maxRetries);

    // 完成 Completer（如果存在且未完成）
    if (_connectionCompleter != null && !_connectionCompleter!.isCompleted) {
      _connectionCompleter!.complete(false);
    }
    _connectionCompleter = null;
    services.connectionState.activeMissionPreferences.value = null;
    services.connectionState.activeTrafficEncryption.value = null;
    return false;
  }

  /// 断开连接
  Future<void> disconnect() async {
    final services = ServiceManager();

    // 取消正在进行的连接（如果存在且未完成）
    if (_connectionCompleter != null && !_connectionCompleter!.isCompleted) {
      _connectionCompleter!.complete(false);
    }
    _connectionCompleter = null;

    // 清空重试计数
    _currentRetryCount = 0;

    // 停止VPN
    if (Platform.isAndroid) {
      if (!ServiceManager().networkConfigState.noTun.value) {
        await ServiceManager().vpn.stop();
      }
      await ServiceManager().notifications.cancelConnectionNotification();
    }

    // 取消定时器
    _statusTracker.cancelAll();
    _networkMonitor.stop();

    // 关闭服务器
    await closeServer();

    batch(() {
      services.connectionState.connectionState.value = CoState.idle;
      services.connectionState.netStatus.value = null;
      services.connectionState.activeMissionPreferences.value = null;
      services.connectionState.activeTrafficEncryption.value = null;
      services.serverStatusState.setActiveServers({});
    });
  }

  /// 初始化服务器配置
  Future<void> _initializeServer(dynamic room) async {
    final services = ServiceManager();

    // 解析房间配置（临时覆盖）
    NetworkConfigShare? roomConfig;
    if (room.networkConfigJson.isNotEmpty) {
      try {
        roomConfig = NetworkConfigShare.fromJsonString(room.networkConfigJson);
      } catch (e, stack) {
        Diagnostics.logger(DiagnosticModules.connection).warning(
          'connect.room-config.invalid',
          'Room network configuration could not be parsed',
          fields: {'attempt': _connectionAttemptId ?? 'unknown'},
          error: e,
          stackTrace: stack,
        );
      }
    }

    final missionPreferences = services.missionControl
        .resolveWithRecommendations(room, roomConfig);

    // 使用Builder构建配置
    final config =
        ServerConfigBuilder(services)
            .withPlayerInfo()
            .withRoom(room)
            .withRoomConfig(roomConfig)
            .withServers(room, services.serverState.servers.value)
            .withListeners(services.playerState.listenList.value)
            .withCidrs(services.vpnState.customVpn.value)
            .withFlags(missionPreferences: missionPreferences)
            .build();

    services.connectionState.activeMissionPreferences.value =
        missionPreferences;
    services.connectionState.activeTrafficEncryption.value =
        roomConfig?.enableEncryption ??
        services.networkConfigState.enableEncryption.value;

    // 调用Rust API创建服务器
    await createServer(
      username: config.username,
      enableDhcp: config.enableDhcp,
      specifiedIp: config.specifiedIp,
      roomName: config.roomName,
      roomPassword: config.roomPassword,
      severurl: config.severurl,
      onurl: config.onurl,
      cidrs: config.cidrs,
      forwards: config.forwards,
      flag: config.flag,
      connectionAttemptId: _connectionAttemptId ?? 'unknown',
    );
  }

  /// 开始连接流程
  Future<void> _beginConnectionProcess() async {
    ServiceManager().connectionState.connectionState.value = CoState.connecting;

    // 显示通知（Android）
    if (Platform.isAndroid &&
        ServiceManager().appSettingsState.enableConnectionNotification.value) {
      await ServiceManager().notifications.showConnectionNotification(
        status: '连接中',
        ip: '正在获取...',
        duration: '00:00',
      );
    }

    // 设置超时
    _statusTracker.setupConnectionTimeout(
      timeoutSeconds: connectionTimeoutSeconds,
    );

    // 启动状态检查
    _statusTracker.startConnectionStatusCheck();
  }

  /// 处理连接成功
  Future<void> _handleSuccessfulConnection() async {
    _statusTracker.cancelTimeout();
    _networkMonitor.resetDuration();
    final services = ServiceManager();
    final log = Diagnostics.logger(DiagnosticModules.connection);

    try {
      if (Platform.isAndroid && !services.networkConfigState.noTun.value) {
        // Fetch the assigned address before creating the Android TUN interface.
        List<String> proxyCidrs = [];
        try {
          final netStatus = await getNetworkStatus();
          services.connectionState.netStatus.value = netStatus;
          proxyCidrs = ConnectionNetworkMonitor.extractProxyCidrs();
        } catch (_) {
          proxyCidrs = ConnectionNetworkMonitor.extractProxyCidrs();
        }

        final runningInfo = jsonDecode(await getRunningInfo());
        final ipv4Addr = ConnectionNetworkMonitor.extractIpv4Address(
          Map<String, dynamic>.from(runningInfo as Map),
        );
        if (!ConnectionNetworkMonitor.isValidRuntimeIpv4(ipv4Addr)) {
          throw StateError(
            'EasyTier did not provide a valid IPv4 address for VPN',
          );
        }

        await services.networkConfig.updateIpv4(ipv4Addr);
        await services.vpn.start(
          ipv4Addr: ipv4Addr,
          mtu: services.networkConfigState.mtu.value,
          proxyCidrs: proxyCidrs,
          connectionAttemptId: _connectionAttemptId,
        );

        if (services.appSettingsState.enableConnectionNotification.value) {
          await services.notifications.showConnectionNotification(
            status: '已连接',
            ip: ConnectionNetworkMonitor.notificationDisplayIp(),
            duration: NotificationService.formatDuration(
              _networkMonitor.connectionDuration,
            ),
          );
        }
      }

      batch(() {
        services.connectionState.connectionState.value = CoState.connected;
        _markActiveServers();
      });

      if (Platform.isWindows) {
        setInterfaceMetric(interfaceName: "astral", metric: 0);
      }

      _networkMonitor.start();
    } catch (error, stack) {
      log.error(
        'connect.vpn.failed',
        'Connection reached EasyTier readiness but VPN setup failed',
        error: error,
        stackTrace: stack,
      );
      await disconnect();
    }
  }

  /// Mark active servers.
  void _markActiveServers() {
    final room = ServiceManager().roomState.selectedRoom.value;
    if (room == null) return;

    final activeIds = <Id>{};
    final enabledServers =
        ServiceManager().serverState.servers.value
            .where((server) => server.enable)
            .toList();

    for (var server in enabledServers) {
      activeIds.add(server.id);
    }

    ServiceManager().serverStatusState.setActiveServers(activeIds);
  }

  /// 清理资源
  void dispose() {
    _statusTracker.cancelAll();
    _networkMonitor.stop();

    // 取消正在进行的连接（如果存在且未完成）
    if (_connectionCompleter != null && !_connectionCompleter!.isCompleted) {
      _connectionCompleter!.complete(false);
    }
    _connectionCompleter = null;
    _currentRetryCount = 0;
  }
}
