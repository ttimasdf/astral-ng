import 'package:astral/features/settings/models/settings_availability.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('settings platform availability', () {
    test('desktop options are hidden on mobile platforms', () {
      const availability = SettingsAvailability.desktopOnly;

      expect(availability.supports(SettingsPlatform.linux), isTrue);
      expect(availability.supports(SettingsPlatform.macos), isTrue);
      expect(availability.supports(SettingsPlatform.windows), isTrue);
      expect(availability.isVisibleOn(SettingsPlatform.android), isFalse);
      expect(availability.isVisibleOn(SettingsPlatform.ios), isFalse);
    });

    test('mobile notices support Android and iOS only', () {
      const availability = SettingsAvailability.mobileOnly;

      expect(availability.supports(SettingsPlatform.android), isTrue);
      expect(availability.supports(SettingsPlatform.ios), isTrue);
      expect(availability.isVisibleOn(SettingsPlatform.linux), isFalse);
    });

    test('Windows adapter options are hidden on other desktops', () {
      const availability = SettingsAvailability.windowsOnly;

      expect(availability.supports(SettingsPlatform.windows), isTrue);
      expect(availability.isVisibleOn(SettingsPlatform.linux), isFalse);
      expect(availability.isVisibleOn(SettingsPlatform.macos), isFalse);
    });

    test(
      'discoverable Android options stay visible but disabled elsewhere',
      () {
        const availability = SettingsAvailability.androidOnlyDiscoverable;

        expect(availability.supports(SettingsPlatform.android), isTrue);
        expect(availability.isVisibleOn(SettingsPlatform.android), isTrue);
        expect(availability.supports(SettingsPlatform.windows), isFalse);
        expect(availability.isVisibleOn(SettingsPlatform.windows), isTrue);
        expect(
          availability.unavailableReasonKey,
          'settings_available_android_only',
        );
      },
    );
  });
}
