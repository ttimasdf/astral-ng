import 'package:enmesh/core/services/update_service.dart';
import 'package:enmesh/features/settings/pages/general/history_versions_page.dart';
import 'package:enmesh/shared/widgets/common/update_check_ui.dart';
import 'package:flutter/material.dart';

void checkForUpdates(BuildContext context) {
  if (context.mounted) {
    UpdateCheckUi.checkAndPresent(context, UpdateChecker());
  }
}

void navigateToHistoryVersions(BuildContext context) {
  Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => const HistoryVersionsPage()));
}
