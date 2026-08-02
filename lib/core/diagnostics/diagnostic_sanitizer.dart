final class DiagnosticSanitizer {
  const DiagnosticSanitizer();

  static const int maxMessageLength = 4096;
  static const int maxFieldLength = 1024;
  static const int maxStackLength = 32768;

  String text(Object? value, {int maxLength = maxMessageLength}) {
    if (value == null) return '';
    var result = value.toString();
    result = result.replaceAllMapped(
      RegExp(
        r'(password|token|authorization|cookie|private[_-]?key)\s*[:=]\s*[^\s,;]+',
        caseSensitive: false,
      ),
      (match) => '${match.group(1)}=<redacted>',
    );
    if (result.length > maxLength) {
      result = '${result.substring(0, maxLength)}…<truncated>';
    }
    return result;
  }

  Map<String, Object?> fields(Map<String, Object?> values) {
    final result = <String, Object?>{};
    for (final entry in values.entries) {
      final key = entry.key;
      if (_isSensitiveKey(key)) {
        result[key] = '<redacted>';
        continue;
      }
      final value = entry.value;
      result[key] = switch (value) {
        null || bool() || num() => value,
        String() => text(value, maxLength: maxFieldLength),
        _ => text(value, maxLength: maxFieldLength),
      };
    }
    return Map.unmodifiable(result);
  }

  bool _isSensitiveKey(String key) {
    final normalized = key.toLowerCase().replaceAll('-', '_');
    return normalized.contains('password') ||
        normalized.contains('token') ||
        normalized.contains('authorization') ||
        normalized.contains('cookie') ||
        normalized.contains('private_key') ||
        normalized.contains('secret') ||
        normalized.contains('credential');
  }
}
