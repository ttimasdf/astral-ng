import 'package:astral/core/ui/base_settings_page.dart';
import 'package:astral/features/settings/widgets/update_settings_actions.dart';
import 'package:astral/features/settings/widgets/update_settings_content.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class UpdateSettingsPage extends BaseSettingsPage {
  const UpdateSettingsPage({super.key});

  @override
  String get title => 'settings_updates'.tr();

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.refresh),
        onPressed: () => checkForUpdates(context),
        tooltip: 'check_update'.tr(),
      ),
    ];
  }

  @override
  Widget buildContent(BuildContext context) {
    return const UpdateSettingsContent();
  }
}
