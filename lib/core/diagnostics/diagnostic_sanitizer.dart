final class DiagnosticSanitizer {
  const DiagnosticSanitizer();

  static const int maxMessageLength = 4096;
  static const int maxFieldLength = 1024;
  static const int maxStackLength = 32768;

  String text(Object? value, {int maxLength = maxMessageLength}) {
    if (value == null) return '';
    var result = value.toString();
    result = result.replaceAll(RegExp(r'\x1B\[[0-?]*[ -/]*[@-~]'), '');
    result = result.replaceAll(RegExp(r'\x1B\][\s\S]*?(?:\x07|\x1B\\)'), '');
    if (_sensitiveAssignment.hasMatch(result)) {
      return '<redacted-sensitive-text>';
    }
    result = result.replaceAll(
      RegExp(r'astral://room\?[^\s]*', caseSensitive: false),
      '<redacted-room-link>',
    );
    result = result.replaceAllMapped(
      RegExp(r'(^|[^A-Za-z0-9_-])(H4sI[A-Za-z0-9_-]{44,})(?=$|[^A-Za-z0-9_-])'),
      (match) => '${match.group(1)}<redacted-room-payload>',
    );
    result = result.replaceAll(
      RegExp(
        r'(?:file:/{2,3}[^\s]+|(?<![A-Za-z0-9/:])(?:[A-Za-z]:[\\/]|/)(?:[^\\/\s]+[\\/])*[^\\/\s]+)',
      ),
      '<redacted-path>',
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

  static final RegExp _sensitiveAssignment = RegExp(
    r'''[a-z0-9_-]*(?:password|token|authorization|cookie|private[_-]?key|secret|credential)[a-z0-9_-]*["']?\s*[:=]''',
    caseSensitive: false,
  );

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
