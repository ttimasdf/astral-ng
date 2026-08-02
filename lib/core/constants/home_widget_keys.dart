/// 桌面小部件 SharedPreferences 键名与 Android Provider 类名。
abstract final class HomeWidgetKeys {
  static const statusText = 'status_text';
  static const roomName = 'room_name';
  static const ipText = 'ip_text';
  static const durationText = 'duration_text';
  static const connectionState = 'connection_state';
  static const requiresVpn = 'requires_vpn';

  static const connectionIdle = 'idle';
  static const connectionConnecting = 'connecting';
  static const connectionConnected = 'connected';

  static const themeCard = 'theme_card';
  static const themeCanvas = 'theme_canvas';
  static const themeTextPrimary = 'theme_text_primary';
  static const themeTextSecondary = 'theme_text_secondary';
  static const themeAccent = 'theme_accent';

  // Keep provider class names tied to the Kotlin namespace rather than the
  // channel-specific Android application ID.
  static const widgetProviderPackage = 'pw.rabit.astralng';
  static const widgetSmall = '$widgetProviderPackage.AstralWidgetProvider';
  static const widgetMedium =
      '$widgetProviderPackage.AstralWidgetProviderMedium';
  static const widgetLarge = '$widgetProviderPackage.AstralWidgetProviderLarge';
}
