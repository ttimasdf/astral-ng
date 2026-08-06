import 'dart:io';

import 'package:astral/core/diagnostics/diagnostic_modules.dart';
import 'package:astral/core/diagnostics/diagnostics_runtime.dart';

const _startupRunKey =
    'HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Run';
const _startupValueName = 'Astral';

final _log = Diagnostics.logger(DiagnosticModules.appLinks);

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
  } catch (e, stack) {
    _log.warning(
      'startup.legacy-shortcut.remove.failed',
      'Failed to remove legacy startup shortcut',
      error: e,
      stackTrace: stack,
    );
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
    if (result.exitCode != 0) {
      _log.warning(
        'startup.registration.failed',
        'Failed to enable launch at startup',
        fields: {'exit_code': result.exitCode},
      );
    }
  } else {
    final result = await Process.run('reg', [
      'delete',
      _startupRunKey,
      '/v',
      _startupValueName,
      '/f',
    ]);
    if (result.exitCode != 0) {
      _log.warning(
        'startup.unregistration.failed',
        'Failed to disable launch at startup',
        fields: {'exit_code': result.exitCode},
      );
    }
  }
}

class UrlSchemeRegistrar {
  /// 注册 URL scheme 到 Windows 注册表
  static Future<bool> registerUrlScheme() async {
    if (!Platform.isWindows) return true;

    try {
      final executablePath = Platform.resolvedExecutable;

      final commands = [
        [
          'add',
          'HKEY_CURRENT_USER\\Software\\Classes\\astral',
          '/ve',
          '/d',
          'URL:Astral Protocol',
          '/f',
        ],
        [
          'add',
          'HKEY_CURRENT_USER\\Software\\Classes\\astral',
          '/v',
          'URL Protocol',
          '/d',
          '',
          '/f',
        ],
        [
          'add',
          'HKEY_CURRENT_USER\\Software\\Classes\\astral\\DefaultIcon',
          '/ve',
          '/d',
          '"$executablePath",1',
          '/f',
        ],
        [
          'add',
          'HKEY_CURRENT_USER\\Software\\Classes\\astral\\shell\\open\\command',
          '/ve',
          '/d',
          '"$executablePath" "%1"',
          '/f',
        ],
      ];

      for (var index = 0; index < commands.length; index++) {
        final result = await Process.run('reg', commands[index]);
        if (result.exitCode != 0) {
          _log.warning(
            'app-links.scheme.registration.failed',
            'Failed to register the Windows URL scheme',
            fields: {'step': index, 'exit_code': result.exitCode},
          );
          return false;
        }
      }

      return true;
    } catch (e, stack) {
      _log.warning(
        'app-links.scheme.registration.failed',
        'Windows URL scheme registration threw an exception',
        error: e,
        stackTrace: stack,
      );
      return false;
    }
  }
}
