import 'package:pub_semver/pub_semver.dart';

abstract final class VersionUtil {
  static bool hasNewVersion(String currentVersion, String? latestVersion) {
    if (latestVersion == null || latestVersion.trim().isEmpty) return false;

    final current = tryParse(currentVersion);
    final latest = tryParse(latestVersion);
    if (current == null || latest == null) return false;
    return current < latest;
  }

  static Version? tryParse(String value) {
    try {
      return Version.parse(normalize(value));
    } on FormatException {
      return null;
    }
  }

  static String normalize(String value) {
    return value.trim().replaceFirst(RegExp(r'^v'), '');
  }
}
