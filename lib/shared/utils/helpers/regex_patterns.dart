import 'dart:io';
import 'package:flutter/foundation.dart';

const _startupRunKey =
    'HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Run';
const _startupValueName = 'Astral';

Future<void> _removeLegacyStartupShortcut() async {
  if (!Platform.isWindows) return;

  try {
    final startupFolder =
        '${Platform.environment['APPDATA']}\\Microsoft\\Windows\\Start Menu\\Programs\\Startup';
    final shortcutPath = '$startupFolder\\Astral.lnk';
    final shortcut = File(shortcutPath);
    if (await shortcut.exists()) {
      await shortcut.delete();
    }
  } catch (e) {
    if (kDebugMode) {
      debugPrint('Failed to remove legacy startup shortcut: $e');
    }
  }
}

Future<void> handleStartupSetting(bool enable) async {
  if (!Platform.isWindows) return;

  final executablePath = Platform.resolvedExecutable;
  final command = '"$executablePath" --autostart';

  await _removeLegacyStartupShortcut();

  if (enable) {
    final result = await Process.run('reg', [
      'add',
      _startupRunKey,
      '/v',
      _startupValueName,
      '/t',
      'REG_SZ',
      '/d',
      command,
      '/f',
    ]);
    if (result.exitCode != 0 && kDebugMode) {
      debugPrint('Failed to register startup: ${result.stderr}');
    }
  } else {
    final result = await Process.run('reg', [
      'delete',
      _startupRunKey,
      '/v',
      _startupValueName,
      '/f',
    ]);
    if (result.exitCode != 0 && kDebugMode) {
      debugPrint('Failed to unregister startup: ${result.stderr}');
    }
  }
}

class UrlSchemeRegistrar {
  /// 注册URL scheme到Windows注册表
  static Future<bool> registerUrlScheme() async {
    if (!Platform.isWindows) return true;
    
    try {
      final executablePath = Platform.resolvedExecutable;
      
      // 使用用户级别的注册表，避免权限问题
      final commands = [
        // 注册主键
        ['add', 'HKEY_CURRENT_USER\\Software\\Classes\\astral', '/ve', '/d', 'URL:Astral Protocol', '/f'],
        ['add', 'HKEY_CURRENT_USER\\Software\\Classes\\astral', '/v', 'URL Protocol', '/d', '', '/f'],
        
        // 注册图标
        ['add', 'HKEY_CURRENT_USER\\Software\\Classes\\astral\\DefaultIcon', '/ve', '/d', '"$executablePath",1', '/f'],
        
        // 注册命令
        ['add', 'HKEY_CURRENT_USER\\Software\\Classes\\astral\\shell\\open\\command', '/ve', '/d', '"$executablePath" "%1"', '/f'],
      ];
      
      // 执行所有注册表命令
      for (final command in commands) {
        final result = await Process.run('reg', command);
        if (result.exitCode != 0) {
          if (kDebugMode) {
           debugPrint('Failed to execute reg command: ${command.join(' ')}');
           debugPrint('Error: ${result.stderr}');
          }
          return false;
        }
      }
      
      if (kDebugMode) {
       debugPrint('URL scheme registered successfully');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
       debugPrint('Error registering URL scheme: $e');
      }
      return false;
    }
  }
  
  /// 检查URL scheme是否已注册
  static Future<bool> isUrlSchemeRegistered() async {
    if (!Platform.isWindows) return true;
    
    try {
      final result = await Process.run('reg', [
        'query',
        'HKEY_CURRENT_USER\\Software\\Classes\\astral',
        '/ve'
      ]);
      
      return result.exitCode == 0 && 
             result.stdout.toString().contains('URL:Astral Protocol');
    } catch (e) {
      if (kDebugMode) {
       debugPrint('Error checking URL scheme registration: $e');
      }
      return false;
    }
  }
  
  /// 卸载URL scheme注册
  static Future<bool> unregisterUrlScheme() async {
    if (!Platform.isWindows) return true;
    
    try {
      final result = await Process.run('reg', [
        'delete',
        'HKEY_CLASSES_ROOT\\astral',
        '/f'
      ]);
      
      if (result.exitCode == 0) {
        if (kDebugMode) {
         debugPrint('URL scheme unregistered successfully');
        }
        return true;
      } else {
        if (kDebugMode) {
         debugPrint('Failed to unregister URL scheme: ${result.stderr}');
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
       debugPrint('Error unregistering URL scheme: $e');
      }
      return false;
    }
  }
  
  /// 更新URL scheme注册（当exe路径改变时）
  static Future<bool> updateUrlSchemeRegistration() async {
    if (!Platform.isWindows) return true;
    
    try {
      // 检查是否已注册
      final isRegistered = await isUrlSchemeRegistered();
      
      if (isRegistered) {
        // 如果已注册，重新注册以更新路径
        return await registerUrlScheme();
      } else {
        // 如果未注册，直接注册
        return await registerUrlScheme();
      }
    } catch (e) {
      if (kDebugMode) {
       debugPrint('Error updating URL scheme registration: $e');
      }
      return false;
    }
  }
}
