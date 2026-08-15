import 'package:astral/core/services/update_service.dart';
import 'package:astral/core/ui/app_snack_bars.dart';
import 'package:astral/generated/locale_keys.g.dart';
import 'package:astral/shared/widgets/common/update_dialogs.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateCheckUi {
  const UpdateCheckUi._();

  static Future<void> checkAndPresent(
    BuildContext context,
    UpdateChecker checker, {
    bool showNoUpdateMessage = true,
    bool showFailureMessage = true,
  }) async {
    final result = await checker.check(
      showNoUpdateMessage: showNoUpdateMessage,
      showFailureMessage: showFailureMessage,
    );
    if (!context.mounted || result == null) return;

    switch (result.kind) {
      case UpdateCheckKind.updateAvailable:
        final update = result.update!;
        showDialog<void>(
          context: context,
          builder:
              (dialogContext) => UpdateDialog(
                update: update,
                onOpenReleasePage:
                    () => _openReleasePage(context, update.pageUrl),
              ),
        );
        break;
      case UpdateCheckKind.upToDate:
        AppSnackBars.success(
          context,
          LocaleKeys.app_up_to_date.tr(),
          LocaleKeys.current_version_value.tr(
            namedArgs: {'version': result.currentVersion ?? ''},
          ),
        );
        break;
      case UpdateCheckKind.unavailable:
        AppSnackBars.error(
          context,
          LocaleKeys.beta_unavailable.tr(),
          LocaleKeys.beta_unavailable_desc.tr(),
        );
        break;
      case UpdateCheckKind.failed:
        AppSnackBars.error(
          context,
          LocaleKeys.update_check_failed.tr(),
          LocaleKeys.update_check_failed_desc.tr(),
        );
        break;
    }
  }

  static Future<void> _openReleasePage(
    BuildContext context,
    Uri pageUrl,
  ) async {
    if (await canLaunchUrl(pageUrl) &&
        await launchUrl(pageUrl, mode: LaunchMode.externalApplication)) {
      return;
    }
    if (!context.mounted) return;
    AppSnackBars.error(
      context,
      LocaleKeys.unable_open_link.tr(),
      pageUrl.toString(),
    );
  }
}
