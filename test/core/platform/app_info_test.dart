import 'package:astral/core/platform/app_info.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppInfoUtil.formatVersionDisplay', () {
    test('shows only the version for production builds', () {
      expect(
        AppInfoUtil.formatVersionDisplay(
          version: '3.0.0',
          buildNumber: '10288',
          isCanary: false,
        ),
        '3.0.0',
      );
    });

    test('labels local canary builds without a CI build number', () {
      expect(
        AppInfoUtil.formatVersionDisplay(
          version: '3.0.0',
          buildNumber: '10288',
          isCanary: true,
        ),
        '3.0.0 Canary',
      );
    });

    test('includes the CI build number for canary artifacts', () {
      expect(
        AppInfoUtil.formatVersionDisplay(
          version: '3.0.0',
          buildNumber: '1000000123',
          isCanary: true,
        ),
        '3.0.0 Canary · build 1000000123',
      );
    });
  });
}
