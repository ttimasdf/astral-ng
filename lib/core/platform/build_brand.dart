/// Compile-time branding and release stage selected by CI.
abstract final class BuildBrand {
  static const channel = String.fromEnvironment(
    'BUILD_CHANNEL',
    defaultValue: 'production',
  );

  static const stage = String.fromEnvironment(
    'BUILD_STAGE',
    defaultValue: channel == 'canary' ? 'alpha' : 'stable',
  );
  static const version = String.fromEnvironment('BUILD_VERSION');

  static const commit = String.fromEnvironment(
    'BUILD_COMMIT',
    defaultValue: 'local',
  );
  static const runNumber = int.fromEnvironment(
    'BUILD_RUN_NUMBER',
    defaultValue: 0,
  );

  static const isCanary = channel == 'canary';
  static const appName = isCanary ? 'AstralNG Canary' : 'AstralNG';
  static const packageId =
      isCanary ? 'pw.rabit.astralng.canary' : 'pw.rabit.astralng';
  static const trayIcon =
      isCanary ? 'assets/icon_canary.ico' : 'assets/icon.ico';
  static const appIcon =
      isCanary ? 'assets/logo_canary.png' : 'assets/logo.png';
}
