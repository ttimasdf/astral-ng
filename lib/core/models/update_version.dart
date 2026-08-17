class UpdateHighlights {
  final String english;
  final String? chinese;

  const UpdateHighlights({required this.english, this.chinese});

  factory UpdateHighlights.fromJson(Map<String, dynamic> json) {
    return UpdateHighlights(
      english: _requiredString(json, 'en'),
      chinese: _optionalString(json, 'zh'),
    );
  }

  String forLanguage(String languageCode) {
    if (languageCode.toLowerCase().startsWith('zh')) {
      final localized = chinese?.trim();
      if (localized != null && localized.isNotEmpty) return localized;
    }
    return english;
  }
}

class UpdateVersion {
  final String channel;
  final String stage;
  final String version;
  final String title;
  final UpdateHighlights? highlights;
  final DateTime publishedAt;
  final DateTime? expiresAt;
  final Uri pageUrl;

  const UpdateVersion({
    required this.channel,
    required this.stage,
    required this.version,
    required this.title,
    required this.highlights,
    required this.publishedAt,
    required this.expiresAt,
    required this.pageUrl,
  });

  factory UpdateVersion.fromJson(Map<String, dynamic> json) {
    final highlightsJson = json['highlights'];
    return UpdateVersion(
      channel: _requiredString(json, 'channel'),
      stage: _optionalString(json, 'stage') ?? _inferredStage(json),
      version: _requiredString(json, 'version'),
      title: _requiredString(json, 'title'),
      highlights:
          highlightsJson is Map
              ? UpdateHighlights.fromJson(
                Map<String, dynamic>.from(highlightsJson),
              )
              : null,
      publishedAt: DateTime.parse(_requiredString(json, 'publishedAt')),
      expiresAt: _optionalDateTime(json, 'expiresAt'),
      pageUrl: _trustedGitHubPage(_requiredString(json, 'pageUrl')),
    );
  }
}

String _inferredStage(Map<String, dynamic> json) {
  final channel = _requiredString(json, 'channel');
  if (channel == 'stable' || channel == 'alpha') return channel;
  final version = _requiredString(json, 'version');
  return RegExp(r'-(alpha|beta|rc)\.').firstMatch(version)?.group(1) ?? channel;
}

Uri _trustedGitHubPage(String value) {
  final uri = Uri.parse(value);
  if (uri.scheme != 'https' ||
      (uri.host != 'github.com' && uri.host != 'www.github.com')) {
    throw const FormatException('pageUrl must be an HTTPS GitHub URL');
  }
  return uri;
}

String _requiredString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('Missing or invalid $key');
  }
  return value.trim();
}

DateTime? _optionalDateTime(Map<String, dynamic> json, String key) {
  final value = _optionalString(json, key);
  return value == null ? null : DateTime.parse(value);
}

String? _optionalString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) return null;
  if (value is! String) throw FormatException('Invalid $key');
  final normalized = value.trim();
  return normalized.isEmpty ? null : normalized;
}
