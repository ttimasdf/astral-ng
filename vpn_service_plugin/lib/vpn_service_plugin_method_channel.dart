import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'vpn_service_plugin_platform_interface.dart';

class MethodChannelVpnServicePlugin extends VpnServicePluginPlatform {
  @visibleForTesting
  final methodChannel = const MethodChannel('vpn_service');

  @override
  Future<Map<String, dynamic>> prepareVpn() async {
    final result = await methodChannel.invokeMethod<Map<Object?, Object?>>(
      'prepareVpn',
    );
    return Map<String, dynamic>.from(result ?? {});
  }

  @override
  Future<Map<String, dynamic>> startVpn({
    String? ipv4Addr,
    List<String>? routes,
    String? dns,
    List<String>? disallowedApplications,
    int? mtu,
    String? connectionAttemptId,
  }) async {
    final result = await methodChannel
        .invokeMethod<Map<Object?, Object?>>('startVpn', {
          'ipv4Addr': ipv4Addr,
          'routes': routes,
          'dns': dns,
          'disallowedApplications': disallowedApplications,
          'mtu': mtu,
          'connectionAttemptId': connectionAttemptId,
        });
    return Map<String, dynamic>.from(result ?? {});
  }

  @override
  Future<Map<String, dynamic>> stopVpn() async {
    await methodChannel.invokeMethod<void>('stopVpn');
    return {}; // Return an empty map to match the required return type
  }

  @override
  Future<void> configureLogging({required String minimumLevel}) {
    return methodChannel.invokeMethod<void>('configureLogging', {
      'minimumLevel': minimumLevel,
    });
  }
}
