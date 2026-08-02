import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:astral/generated/locale_keys.g.dart';
import 'package:astral/features/settings/models/history_version.dart';
import 'package:astral/core/ui/app_snack_bars.dart';
import 'package:astral/core/ui/base_settings_page.dart';

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
  String get title => LocaleKeys.history_versions.tr();

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.refresh),
        onPressed: _loadVersions,
        tooltip: 'refresh'.tr(),
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    _loadVersions();
  }

  Future<void> _loadVersions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http.get(
        Uri.parse('https://astral.fan/downloads.json'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        setState(() {
          _versions =
              jsonList.map((json) => HistoryVersion.fromJson(json)).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'load_failed'.tr(
            namedArgs: {'error': 'HTTP ${response.statusCode}'},
          );
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'load_failed'.tr(namedArgs: {'error': e.toString()});
        _isLoading = false;
      });
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        AppSnackBars.error(context, 'unable_open_link'.tr(), url);
      }
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
            Text(
              _errorMessage!,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadVersions,
              icon: const Icon(Icons.refresh),
              label: Text('retry'.tr()),
            ),
          ],
        ),
      );
    }

    if (_versions.isEmpty) {
      return Center(
        child: Text(
          'no_previous_versions'.tr(),
          style: const TextStyle(fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _versions.length,
      itemBuilder: (context, index) {
        final version = _versions[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              child: Text(
                '${index + 1}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(
              version.version,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            subtitle: Text(version.date),
            trailing: const Icon(Icons.download),
            onTap: () => _launchUrl(version.url),
          ),
        );
      },
    );
  }
}
