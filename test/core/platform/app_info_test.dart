import 'package:astral/core/platform/app_info.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppInfoUtil version identity', () {
    test('production uses the release SemVer everywhere', () {
      expect(
        AppInfoUtil.formatFriendlyVersion(
          version: '3.0.0',
          commit: 'abcdef0',
          isCanary: false,
        ),
        '3.0.0',
      );
      expect(
        AppInfoUtil.formatAboutVersion(
          version: '3.0.0',
          commit: 'abcdef0',
          isCanary: false,
        ),
        '3.0.0',
      );
      expect(
        AppInfoUtil.formatSemanticVersion(
          version: '3.0.0',
          commit: 'abcdef0',
          runNumber: 42,
          isCanary: false,
        ),
        '3.0.0',
      );
    });

    test('canary exposes friendly, About, and ordered SemVer forms', () {
      expect(
        AppInfoUtil.formatFriendlyVersion(
          version: '3.0.0',
          commit: 'abcdef0',
          isCanary: true,
        ),
        '3.0.0 Canary abcdef0',
      );
      expect(
        AppInfoUtil.formatAboutVersion(
          version: '3.0.0',
          commit: 'abcdef0',
          isCanary: true,
        ),
        '3.0.0-alpha+abcdef0',
      );
      expect(
        AppInfoUtil.formatSemanticVersion(
          version: '3.0.0',
          commit: 'abcdef0',
          runNumber: 42,
          isCanary: true,
        ),
        '3.0.0-alpha.42+abcdef0',
      );
    });

    test('invalid local identity remains valid SemVer metadata', () {
      expect(
        AppInfoUtil.formatSemanticVersion(
          version: '3.0.0',
          commit: 'dirty worktree',
          runNumber: -1,
          isCanary: true,
        ),
        '3.0.0-alpha.0+local',
      );
    });
  });
}
