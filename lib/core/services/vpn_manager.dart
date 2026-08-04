import 'dart:async';
import 'dart:io';

import 'package:astral/core/diagnostics/diagnostic_modules.dart';
import 'package:astral/core/diagnostics/diagnostics_runtime.dart';
import 'package:astral/core/diagnostics/log_policy.dart';
import 'package:astral/core/diagnostics/log_severity.dart';
import 'package:astral/core/platform/build_brand.dart';
import 'package:astral/core/services/service_manager.dart';
import 'package:astral/shared/utils/network/ip_utils.dart';
import 'package:vpn_service_plugin/vpn_service_plugin.dart';
import 'package:astral/src/rust/api/simple.dart';

/// VPN 管理器（仅 Android）
class VpnManager {
  static VpnManager? _instance;
  final VpnServicePlugin? _plugin;
  StreamSubscription<dynamic>? _vpnStartedSub;
  StreamSubscription<dynamic>? _vpnStoppedSub;
  StreamSubscription<dynamic>? _vpnErrorSub;
  StreamSubscription<dynamic>? _diagnosticSub;
  bool _androidHooksInitialized = false;
  bool _handlingSystemRevocation = false;

  VpnManager._() : _plugin = Platform.isAndroid ? VpnServicePlugin() : null;

  /// 获取单例实例
  static VpnManager get instance {
    _instance ??= VpnManager._();
    return _instance!;
  }

  /// 获取 VPN 插件实例
  VpnServicePlugin? get plugin => _plugin;

  /// Android 通知 + VPN TUN fd 监听（应用级一次初始化）
  Future<void> initAndroidHooks() async {
    if (!Platform.isAndroid || _androidHooksInitialized) return;

    final services = ServiceManager();
    final plugin = _plugin!;
    final diagnostics = Diagnostics.runtime;
    final log = diagnostics.logger(DiagnosticModules.vpn);
    await services.notifications.initialize();
    await plugin.configureLogging(
      minimumLevel: _nativeMinimumLevel(diagnostics.policy.value),
    );

    await _vpnStartedSub?.cancel();
    _vpnStartedSub = plugin.onVpnServiceStarted.listen((data) {
      if (services.networkConfigState.noTun.value) return;
      final fd = data['fd'];
      if (fd is int) {
        configureTunFd(fd);
      }
    });

    await _vpnStoppedSub?.cancel();
    _vpnStoppedSub = plugin.onVpnServiceStopped.listen((data) {
      if (data['reason'] == 'revoked') {
        unawaited(_handleSystemRevocation());
      }
    });

    await _vpnErrorSub?.cancel();
    _vpnErrorSub = plugin.onVpnServiceError.listen((data) {
      log.error(
        'vpn.service.failed',
        'Android VPN service reported a failure',
        fields: {
          'reason': data['reason']?.toString() ?? 'unknown',
          if (data['errorType'] != null)
            'native_error_type': data['errorType'].toString(),
        },
      );
    });

    await _diagnosticSub?.cancel();
    _diagnosticSub = plugin.onDiagnosticEvent.listen(_ingestNativeDiagnostic);
    diagnostics.policy.addListener(_syncNativePolicy);
    _androidHooksInitialized = true;
    log.info('vpn.hooks.ready', 'Android VPN diagnostic hooks initialized');
  }

  Future<void> _handleSystemRevocation() async {
    if (_handlingSystemRevocation) return;
    _handlingSystemRevocation = true;

    try {
      Diagnostics.logger(DiagnosticModules.vpn).warning(
        'vpn.revocation.disconnect',
        'Disconnecting after Android revoked VPN permission',
      );
      await ServiceManager().connection.disconnect();
    } finally {
      _handlingSystemRevocation = false;
    }
  }

  void _ingestNativeDiagnostic(dynamic data) {
    if (data is! Map) return;
    final event = Map<String, dynamic>.from(data);
    final timestamp = event['timestampMillis'];
    final sourceSequence = event['sourceSequence'];
    final rawFields = event['fields'];
    final fields =
        rawFields is Map
            ? Map<String, Object?>.from(rawFields)
            : const <String, Object?>{};
    Diagnostics.runtime.ingestExternal(
      sourceTimestampUtc: DateTime.fromMillisecondsSinceEpoch(
        timestamp is num
            ? timestamp.toInt()
            : DateTime.now().millisecondsSinceEpoch,
        isUtc: true,
      ),
      sourceSequence: sourceSequence is num ? sourceSequence.toInt() : null,
      origin: 'android',
      module: event['module']?.toString() ?? DiagnosticModules.vpnAndroid,
      rawTarget: 'android.vpn',
      level: _parseNativeLevel(event['level']?.toString()),
      eventCode: event['eventCode']?.toString(),
      message: event['message']?.toString() ?? 'Android VPN event',
      fields: fields,
      connectionAttemptId: fields['connection_attempt_id']?.toString(),
      errorType: event['errorType']?.toString(),
      errorMessage: event['errorMessage']?.toString(),
      stackTrace: event['stackTrace']?.toString(),
      consoleAlreadyReported: event['consoleAlreadyReported'] == true,
    );
  }

  void _syncNativePolicy() {
    unawaited(_applyNativePolicy());
  }

  Future<void> _applyNativePolicy() async {
    final plugin = _plugin;
    if (plugin == null) return;
    try {
      await plugin.configureLogging(
        minimumLevel: _nativeMinimumLevel(Diagnostics.runtime.policy.value),
      );
    } catch (error, stack) {
      Diagnostics.logger(DiagnosticModules.vpn).warning(
        'vpn.logging.configure.failed',
        'Failed to update Android VPN log policy',
        error: error,
        stackTrace: stack,
      );
    }
  }

  String _nativeMinimumLevel(LogPolicy policy) {
    LogSeverity? minimum;
    for (final destination in DiagnosticDestination.values) {
      final candidate = policy.minimumLevel(
        DiagnosticModules.vpnAndroid,
        destination,
      );
      if (candidate != null &&
          (minimum == null || candidate.index < minimum.index)) {
        minimum = candidate;
      }
    }
    return minimum?.name ?? 'info';
  }

  LogSeverity _parseNativeLevel(String? value) => switch (value) {
    'trace' => LogSeverity.trace,
    'debug' => LogSeverity.debug,
    'warning' || 'warn' => LogSeverity.warning,
    'error' => LogSeverity.error,
    'fatal' => LogSeverity.fatal,
    _ => LogSeverity.info,
  };

  /// 准备 VPN 服务（请求权限）
  Future<void> prepare() async {
    final plugin = _plugin;
    if (plugin == null) return;
    await plugin.prepareVpn();
  }

  /// 启动 VPN 服务
  Future<void> start({
    required String ipv4Addr,
    int mtu = 1300,
    List<String> disallowedApplications = const [BuildBrand.packageId],
    List<String> proxyCidrs = const [],
    String? connectionAttemptId,
  }) async {
    final plugin = _plugin;
    if (plugin == null) return;
    if (ipv4Addr.isEmpty) return;

    String finalIpv4 = ipv4Addr;
    if (!ipv4Addr.contains('/')) {
      finalIpv4 = '$ipv4Addr/24';
    }

    final customRoutes =
        ServiceManager().vpnState.customVpn.value
            .where((route) => isValidCIDR(route))
            .toList();

    final routes = [
      ...customRoutes,
      ...proxyCidrs.where((route) => isValidCIDR(route)),
    ];

    await plugin.startVpn(
      ipv4Addr: finalIpv4,
      mtu: mtu,
      routes: routes,
      disallowedApplications: disallowedApplications,
      connectionAttemptId: connectionAttemptId,
    );
  }

  /// 停止 VPN 服务
  Future<void> stop() async {
    final plugin = _plugin;
    if (plugin == null) return;
    await plugin.stopVpn();
  }

  /// 将 TUN fd 传递给 Rust 层
  Future<void> configureTunFd(int fd) async {
    await setTunFd(fd: fd);
  }
}
