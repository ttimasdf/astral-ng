import 'package:enmesh/core/models/update_version.dart';

class HistoryVersion {
  final String title;
  final String? highlightEnglish;
  final String? highlightChinese;
  final DateTime publishedAt;
  final Uri pageUrl;

  const HistoryVersion({
    required this.title,
    required this.highlightEnglish,
    required this.highlightChinese,
    required this.publishedAt,
    required this.pageUrl,
  });

  factory HistoryVersion.fromUpdateVersion(UpdateVersion update) {
    return HistoryVersion(
      title: update.title,
      highlightEnglish: update.highlights?.english,
      highlightChinese: update.highlights?.chinese,
      publishedAt: update.publishedAt,
      pageUrl: update.pageUrl,
    );
  }

  String? highlightForLanguage(String languageCode) {
    if (languageCode.toLowerCase().startsWith('zh')) {
      final localized = highlightChinese?.trim();
      if (localized != null && localized.isNotEmpty) return localized;
    }
    final fallback = highlightEnglish?.trim();
    return fallback == null || fallback.isEmpty ? null : fallback;
  }
}
