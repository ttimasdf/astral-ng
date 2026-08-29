import 'package:enmesh/core/models/update_version.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses normalized update metadata and localizes highlights', () {
    final update = UpdateVersion.fromJson({
      'channel': 'stable',
      'stage': 'stable',
      'version': '3.0.0',
      'title': 'Release v3.0.0',
      'highlights': {'en': 'Safer updates.', 'zh': '更安全的更新。'},
      'publishedAt': '2026-08-14T00:00:00Z',
      'expiresAt': null,
      'pageUrl': 'https://github.com/example/app/releases/tag/v3.0.0',
    });

    expect(update.stage, 'stable');
    expect(update.highlights?.forLanguage('en'), 'Safer updates.');
    expect(update.highlights?.forLanguage('zh_CN'), '更安全的更新。');
    expect(update.expiresAt, isNull);
  });

  test('infers the stage for schema-compatible older responses', () {
    final update = UpdateVersion.fromJson({
      'channel': 'beta',
      'version': '3.1.0-rc.1',
      'title': 'Release candidate v3.1.0-rc.1',
      'highlights': null,
      'publishedAt': '2026-08-14T00:00:00Z',
      'expiresAt': null,
      'pageUrl': 'https://github.com/example/app/releases/tag/v3.1.0-rc.1',
    });
    expect(update.stage, 'rc');
  });

  test('falls back to English when Chinese highlight is absent', () {
    const highlights = UpdateHighlights(english: 'Commit subject');
    expect(highlights.forLanguage('zh'), 'Commit subject');
  });

  test('rejects an untrusted release page URL', () {
    expect(
      () => UpdateVersion.fromJson({
        'channel': 'stable',
        'version': '3.0.0',
        'title': 'Release v3.0.0',
        'highlights': {'en': 'Safer updates.'},
        'publishedAt': '2026-08-14T00:00:00Z',
        'expiresAt': null,
        'pageUrl': 'https://example.invalid/release',
      }),
      throwsFormatException,
    );
  });

  test('rejects malformed required metadata', () {
    expect(
      () => UpdateVersion.fromJson({
        'channel': 'stable',
        'version': '3.0.0',
        'title': 'Release v3.0.0',
        'highlights': {'zh': '缺少英文亮点。'},
        'publishedAt': '2026-08-14T00:00:00Z',
        'expiresAt': null,
        'pageUrl': 'https://github.com/example/app/releases/tag/v3.0.0',
      }),
      throwsFormatException,
    );
  });
}
