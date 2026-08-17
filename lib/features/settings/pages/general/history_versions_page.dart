import 'dart:convert';

import 'package:astral/core/models/update_version.dart';
import 'package:astral/core/services/service_manager.dart';
import 'package:astral/core/services/update_service.dart';
import 'package:astral/core/ui/app_snack_bars.dart';
import 'package:astral/core/ui/base_settings_page.dart';
import 'package:astral/features/settings/models/history_version.dart';
import 'package:astral/generated/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class HistoryVersionsPage extends BaseStatefulSettingsPage {
  const HistoryVersionsPage({super.key});

  @override
  BaseStatefulSettingsPageState<HistoryVersionsPage> createState() =>
      _HistoryVersionsPageState();
}

class _HistoryVersionsPageState
    extends BaseStatefulSettingsPageState<HistoryVersionsPage> {
  List<HistoryVersion> _versions = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  String get title => LocaleKeys.previous_versions.tr();

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.refresh),
        onPressed: _loadVersions,
        tooltip: LocaleKeys.refresh.tr(),
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    _loadVersions();
  }

  Future<void> _loadVersions() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final channel = ServiceManager().updateState.channel.value.name;
      final baseUri = Uri.parse(updateApiBaseUrl);
      final uri = baseUri.replace(
        path: '${baseUri.path.replaceFirst(RegExp(r'/$'), '')}/versions',
        queryParameters: {'channel': channel, 'limit': '30'},
      );
      final response = await http
          .get(uri, headers: const {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map || decoded['schemaVersion'] != 1) {
        throw const FormatException('Unsupported version response');
      }
      final data = decoded['data'];
      if (data is! List) throw const FormatException('Missing version list');
      final versions =
          data
              .map(
                (item) => HistoryVersion.fromUpdateVersion(
                  UpdateVersion.fromJson(
                    Map<String, dynamic>.from(item as Map),
                  ),
                ),
              )
              .toList();
      if (!mounted) return;
      setState(() {
        _versions = versions;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = LocaleKeys.load_failed.tr(
          namedArgs: {'error': error.toString()},
        );
        _isLoading = false;
      });
    }
  }

  Future<void> _openVersionPage(Uri uri) async {
    if (await canLaunchUrl(uri) &&
        await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      return;
    }
    if (mounted) {
      AppSnackBars.error(
        context,
        LocaleKeys.unable_open_link.tr(),
        uri.toString(),
      );
    }
  }

  @override
  Widget buildContent(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(_errorMessage!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _loadVersions,
              icon: const Icon(Icons.refresh),
              label: Text(LocaleKeys.retry.tr()),
            ),
          ],
        ),
      );
    }
    if (_versions.isEmpty) {
      return Center(child: Text(LocaleKeys.no_previous_versions.tr()));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _versions.length,
      itemBuilder: (context, index) {
        final version = _versions[index];
        final highlight = version.highlightForLanguage(
          context.locale.languageCode,
        );
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: const CircleAvatar(
              child: Icon(Icons.new_releases_outlined),
            ),
            title: Text(
              version.title,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  MaterialLocalizations.of(
                    context,
                  ).formatMediumDate(version.publishedAt.toLocal()),
                ),
                if (highlight != null) Text(highlight),
              ],
            ),
            trailing: const Icon(Icons.open_in_new),
            onTap: () => _openVersionPage(version.pageUrl),
          ),
        );
      },
    );
  }
}
