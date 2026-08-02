/// Compile-time branding selected by CI with
/// `--dart-define=BUILD_CHANNEL=canary|production`.
abstract final class BuildBrand {
  static const channel = String.fromEnvironment(
    'BUILD_CHANNEL',
    defaultValue: 'production',
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
