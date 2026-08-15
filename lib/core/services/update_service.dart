import 'dart:convert';

import 'package:astral/core/models/update_version.dart';
import 'package:astral/core/platform/app_info.dart';
import 'package:astral/core/services/service_manager.dart';
import 'package:astral/shared/utils/version_util.dart';
import 'package:http/http.dart' as http;

const _defaultUpdateApiBaseUrl = 'https://astral.fan/api/v1';
const updateApiBaseUrl = String.fromEnvironment(
  'UPDATE_API_BASE_URL',
  defaultValue: _defaultUpdateApiBaseUrl,
);

enum UpdateCheckKind { updateAvailable, upToDate, unavailable, failed }

class UpdateCheckResult {
  final UpdateCheckKind kind;
  final UpdateVersion? update;
  final String? currentVersion;

  const UpdateCheckResult({
    required this.kind,
    this.update,
    this.currentVersion,
  });
}

class UpdateChecker {
  static const _requestTimeout = Duration(seconds: 15);

  final http.Client _client;
  final Uri _baseUri;
  final String Function() _channelProvider;
  final String Function() _currentVersionProvider;

  UpdateChecker({
    http.Client? client,
    Uri? baseUri,
    String Function()? channelProvider,
    String Function()? currentVersionProvider,
  }) : _client = client ?? http.Client(),
       _baseUri = baseUri ?? Uri.parse(updateApiBaseUrl),
       _channelProvider =
           channelProvider ??
           (() =>
               ServiceManager().updateState.receiveBetaUpdates.value
                   ? 'beta'
                   : 'stable'),
       _currentVersionProvider =
           currentVersionProvider ?? AppInfoUtil.getSemanticVersion;

  Future<UpdateCheckResult?> check({
    bool showNoUpdateMessage = true,
    bool showFailureMessage = true,
  }) async {
    try {
      final channel = _channelProvider();
      if (channel != 'stable' && channel != 'beta') {
        throw const FormatException('Unsupported update channel');
      }
      final uri = _baseUri.replace(
        path: '${_baseUri.path.replaceFirst(RegExp(r'/$'), '')}/update',
        queryParameters: {'channel': channel},
      );
      final response = await _client
          .get(
            uri,
            headers: const {
              'Accept': 'application/json',
              'User-Agent': 'astral-ng',
            },
          )
          .timeout(_requestTimeout);

      if (response.statusCode == 404 && channel == 'beta') {
        return showFailureMessage
            ? const UpdateCheckResult(kind: UpdateCheckKind.unavailable)
            : null;
      }
      if (response.statusCode != 200) {
        return showFailureMessage
            ? const UpdateCheckResult(kind: UpdateCheckKind.failed)
            : null;
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map || decoded['schemaVersion'] != 1) {
        throw const FormatException('Unsupported update response');
      }
      final data = decoded['data'];
      if (data is! Map) throw const FormatException('Missing update data');
      final update = UpdateVersion.fromJson(Map<String, dynamic>.from(data));
      if (update.channel != channel) {
        throw const FormatException('Update channel mismatch');
      }

      final currentVersion = _currentVersionProvider();
      if (VersionUtil.hasNewVersion(currentVersion, update.version)) {
        return UpdateCheckResult(
          kind: UpdateCheckKind.updateAvailable,
          update: update,
          currentVersion: currentVersion,
        );
      }
      if (!showNoUpdateMessage) return null;
      return UpdateCheckResult(
        kind: UpdateCheckKind.upToDate,
        update: update,
        currentVersion: currentVersion,
      );
    } catch (_) {
      return showFailureMessage
          ? const UpdateCheckResult(kind: UpdateCheckKind.failed)
          : null;
    }
  }
}
