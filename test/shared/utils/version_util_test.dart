import 'package:astral/shared/utils/version_util.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('VersionUtil', () {
    test('orders prereleases before the matching production release', () {
      expect(
        VersionUtil.hasNewVersion('3.0.0-alpha.42+abcdef0', 'v3.0.0'),
        isTrue,
      );
    });

    test('orders numeric prerelease identifiers numerically', () {
      expect(
        VersionUtil.hasNewVersion(
          '3.0.0-alpha.9+abcdef0',
          '3.0.0-alpha.10+1234567',
        ),
        isTrue,
      );
    });

    test('ignores build metadata when comparing precedence', () {
      expect(
        VersionUtil.hasNewVersion(
          '3.0.0-alpha.42+abcdef0',
          '3.0.0-alpha.42+1234567',
        ),
        isFalse,
      );
    });

    test('rejects invalid versions instead of guessing numeric parts', () {
      expect(VersionUtil.hasNewVersion('3.0.0', 'latest'), isFalse);
    });
  });
}
