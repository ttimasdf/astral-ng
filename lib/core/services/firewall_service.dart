import 'package:astral/core/diagnostics/diagnostic_modules.dart';
import 'package:astral/core/diagnostics/diagnostics_runtime.dart';
import 'package:astral/core/states/firewall_state.dart';
import 'package:astral/src/rust/api/firewall.dart';

/// 防火墙服务：协调FirewallState和系统API
class FirewallService {
  final FirewallState state;

  FirewallService(this.state);

  // ========== 初始化 ==========

  Future<void> init() async {
    try {
      await updateFirewallStatus();
    } catch (e, stack) {
      // 防火墙服务初始化失败不应该导致应用崩溃
      // 可能的原因：权限不足、系统关机、服务不可用等
      Diagnostics.logger(DiagnosticModules.firewall).warning(
        'firewall.initialize.failed',
        'Firewall service initialization failed',
        error: e,
        stackTrace: stack,
      );
      // 设置默认状态为 false
      state.setFirewallStatus(false);
    }
  }

  // ========== 业务方法 ==========

  Future<void> setFirewall(bool value) async {
    try {
      state.setFirewallStatus(value);
      await setFirewallStatus(profileIndex: 1, enable: value);
      await setFirewallStatus(profileIndex: 2, enable: value);
      await setFirewallStatus(profileIndex: 3, enable: value);
    } catch (e, stack) {
      Diagnostics.logger(DiagnosticModules.firewall).error(
        'firewall.set.failed',
        'Failed to update firewall state',
        fields: {'enabled': value},
        error: e,
        stackTrace: stack,
      );
      // 如果设置失败，回滚状态
      await updateFirewallStatus();
      rethrow;
    }
  }

  Future<void> updateFirewallStatus() async {
    try {
      final status =
          await getFirewallStatus(profileIndex: 1) &&
          await getFirewallStatus(profileIndex: 2) &&
          await getFirewallStatus(profileIndex: 3);

      state.setFirewallStatus(status);
    } catch (e, stack) {
      Diagnostics.logger(DiagnosticModules.firewall).warning(
        'firewall.read.failed',
        'Failed to read firewall state',
        error: e,
        stackTrace: stack,
      );
      // 如果无法获取状态，设置为 false（安全起见）
      state.setFirewallStatus(false);
      // 这里不抛出异常，让应用继续运行
    }
  }
}
