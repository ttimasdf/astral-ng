import 'dart:io';

enum SettingsPlatform {
  android,
  ios,
  linux,
  macos,
  windows,
  other;

  static SettingsPlatform get current {
    if (Platform.isAndroid) return SettingsPlatform.android;
    if (Platform.isIOS) return SettingsPlatform.ios;
    if (Platform.isLinux) return SettingsPlatform.linux;
    if (Platform.isMacOS) return SettingsPlatform.macos;
    if (Platform.isWindows) return SettingsPlatform.windows;
    return SettingsPlatform.other;
  }
}

enum UnsupportedSettingsPresentation { hidden, disabled }

class SettingsAvailability {
  final Set<SettingsPlatform> platforms;
  final UnsupportedSettingsPresentation unsupportedPresentation;
  final String? unavailableReasonKey;

  const SettingsAvailability({
    required this.platforms,
    this.unsupportedPresentation = UnsupportedSettingsPresentation.hidden,
    this.unavailableReasonKey,
  });

  static const all = SettingsAvailability(
    platforms: {
      SettingsPlatform.android,
      SettingsPlatform.ios,
      SettingsPlatform.linux,
      SettingsPlatform.macos,
      SettingsPlatform.windows,
      SettingsPlatform.other,
    },
  );

  static const desktopOnly = SettingsAvailability(
    platforms: {
      SettingsPlatform.linux,
      SettingsPlatform.macos,
      SettingsPlatform.windows,
    },
  );

  static const mobileOnly = SettingsAvailability(
    platforms: {SettingsPlatform.android, SettingsPlatform.ios},
  );

  static const androidOnly = SettingsAvailability(
    platforms: {SettingsPlatform.android},
  );

  static const windowsOnly = SettingsAvailability(
    platforms: {SettingsPlatform.windows},
  );

  static const androidOnlyDiscoverable = SettingsAvailability(
    platforms: {SettingsPlatform.android},
    unsupportedPresentation: UnsupportedSettingsPresentation.disabled,
    unavailableReasonKey: 'settings_available_android_only',
  );

  bool supports(SettingsPlatform platform) => platforms.contains(platform);

  bool isVisibleOn(SettingsPlatform platform) =>
      supports(platform) ||
      unsupportedPresentation == UnsupportedSettingsPresentation.disabled;

  bool get isSupported => supports(SettingsPlatform.current);

  bool get isVisible => isVisibleOn(SettingsPlatform.current);

  bool get isEnabled => isSupported;

  String? get currentUnavailableReasonKey =>
      isSupported ? null : unavailableReasonKey;
}
