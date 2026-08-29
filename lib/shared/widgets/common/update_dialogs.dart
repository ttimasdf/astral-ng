import 'package:enmesh/core/models/update_version.dart';
import 'package:enmesh/generated/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class UpdateDialog extends StatelessWidget {
  final UpdateVersion update;
  final VoidCallback onOpenReleasePage;

  const UpdateDialog({
    super.key,
    required this.update,
    required this.onOpenReleasePage,
  });

  @override
  Widget build(BuildContext context) {
    final highlight = update.highlights?.forLanguage(
      context.locale.languageCode,
    );
    return AlertDialog(
      title: Text(LocaleKeys.update_available_title.tr()),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              update.title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            if (highlight != null && highlight.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(highlight),
            ],
            const SizedBox(height: 12),
            Text(
              LocaleKeys.update_browser_install_notice.tr(),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        FilledButton.icon(
          onPressed: () {
            Navigator.of(context).pop();
            WidgetsBinding.instance.addPostFrameCallback((_) {
              onOpenReleasePage();
            });
          },
          icon: const Icon(Icons.open_in_new),
          label: Text(LocaleKeys.open_release_page.tr()),
        ),
      ],
    );
  }
}
