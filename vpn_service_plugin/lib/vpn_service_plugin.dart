import 'dart:async';
import 'package:flutter/services.dart';
import 'vpn_service_plugin_platform_interface.dart';

class VpnServicePlugin {
  static const EventChannel _eventChannel = EventChannel('vpn_service_events');

  // VPN服务事件流
  static Stream<Map<String, dynamic>>? _vpnServiceEvents;

  /// 获取VPN服务事件流
  Stream<Map<String, dynamic>> get onVpnStatusChanged {
    _vpnServiceEvents ??= _eventChannel
        .receiveBroadcastStream()
        .map<Map<String, dynamic>>(
          (event) => Map<String, dynamic>.from(event as Map),
        );
    return _vpnServiceEvents!;
  }

  /// 准备 VPN 服务，获取必要的权限
  Future<Map<String, dynamic>> prepareVpn() {
    return VpnServicePluginPlatform.instance.prepareVpn();
  }

  /// 启动 VPN 服务
  ///
  /// [ipv4Addr] - VPN 的 IPv4 地址，格式如 "10.126.126.1/24"
  /// [routes] - VPN 路由表
  /// [dns] - DNS 服务器地址
  /// [disallowedApplications] - 不允许使用 VPN 的应用包名列表
  /// [mtu] - 最大传输单元
  Future<Map<String, dynamic>> startVpn({
    String? ipv4Addr,
    List<String>? routes,
    String? dns,
    List<String>? disallowedApplications,
    int? mtu,
    String? connectionAttemptId,
  }) {
    return VpnServicePluginPlatform.instance.startVpn(
      ipv4Addr: ipv4Addr,
      routes: routes,
      dns: dns,
      disallowedApplications: disallowedApplications,
      mtu: mtu,
      connectionAttemptId: connectionAttemptId,
    );
  }

  /// 停止 VPN 服务
  Future<void> stopVpn() {
    return VpnServicePluginPlatform.instance.stopVpn();
  }

  /// 监听VPN服务启动事件
  Stream<Map<String, dynamic>> get onVpnServiceStarted {
    return onVpnStatusChanged
        .where((event) => event['event'] == 'vpn_service_start')
        .map((event) => Map<String, dynamic>.from(event['data'] as Map));
  }

  /// 监听VPN服务停止事件
  Stream<Map<String, dynamic>> get onVpnServiceStopped {
    return onVpnStatusChanged
        .where((event) => event['event'] == 'vpn_service_stop')
        .map((event) => Map<String, dynamic>.from(event['data'] as Map));
  }

  Stream<Map<String, dynamic>> get onVpnServiceError {
    return onVpnStatusChanged
        .where((event) => event['event'] == 'vpn_service_error')
        .map((event) => Map<String, dynamic>.from(event['data'] as Map));
  }

  Stream<Map<String, dynamic>> get onDiagnosticEvent {
    return onVpnStatusChanged
        .where((event) => event['event'] == 'diagnostic')
        .map((event) => Map<String, dynamic>.from(event['data'] as Map));
  }

  Future<void> configureLogging({required String minimumLevel}) {
    return VpnServicePluginPlatform.instance.configureLogging(
      minimumLevel: minimumLevel,
    );
  }
}
