import 'package:astral/core/services/service_manager.dart';
import 'package:astral/features/settings/widgets/settings_components.dart';
import 'package:astral/generated/locale_keys.g.dart';
import 'package:astral/shared/widgets/common/theme_selector.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';

class AppearanceSettingsContent extends StatelessWidget {
  const AppearanceSettingsContent({super.key});

  String _themeModeLabel(ThemeMode mode) {
    return switch (mode) {
      ThemeMode.system => LocaleKeys.theme_system.tr(),
      ThemeMode.light => LocaleKeys.theme_light.tr(),
      ThemeMode.dark => LocaleKeys.theme_dark.tr(),
    };
  }

  Future<void> _selectThemeMode(BuildContext context) async {
    final current = ServiceManager().themeState.themeMode.value;
    final selected = await showDialog<ThemeMode>(
      context: context,
      builder:
          (context) => SimpleDialog(
            title: Text(LocaleKeys.theme_mode.tr()),
            children: [
              for (final mode in ThemeMode.values)
                ListTile(
                  selected: mode == current,
                  title: Text(_themeModeLabel(mode)),
                  leading: Icon(switch (mode) {
                    ThemeMode.system => Icons.brightness_auto,
                    ThemeMode.light => Icons.light_mode,
                    ThemeMode.dark => Icons.dark_mode,
                  }),
                  trailing: mode == current ? const Icon(Icons.check) : null,
                  onTap: () => Navigator.pop(context, mode),
                ),
            ],
          ),
    );

    if (selected != null) {
      await ServiceManager().theme.updateThemeMode(selected);
    }
  }

  Future<void> _selectLanguage(BuildContext context) async {
    final current = context.locale;
    final selected = await showDialog<Locale>(
      context: context,
      builder:
          (context) => SimpleDialog(
            title: Text(LocaleKeys.language.tr()),
            children: [
              ListTile(
                selected: current.languageCode == 'zh',
                title: const Text('简体中文'),
                leading: const Text('🇨🇳', style: TextStyle(fontSize: 22)),
                trailing:
                    current.languageCode == 'zh'
                        ? const Icon(Icons.check)
                        : null,
                onTap: () => Navigator.pop(context, const Locale('zh')),
              ),
              ListTile(
                selected: current.languageCode == 'en',
                title: const Text('English'),
                leading: const Text('🇺🇸', style: TextStyle(fontSize: 22)),
                trailing:
                    current.languageCode == 'en'
                        ? const Icon(Icons.check)
                        : null,
                onTap: () => Navigator.pop(context, const Locale('en')),
              ),
            ],
          ),
    );

    if (selected != null && context.mounted) {
      await context.setLocale(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final services = ServiceManager();

    return Watch((context) {
      final themeMode = services.themeState.themeMode.watch(context);
      final themeColor = services.themeState.themeColor.watch(context);
      final compactPeerCards = services.displayState.compactPeerCards.watch(
        context,
      );
      final reduceTopologyAnimations = services
          .appSettingsState
          .reduceTopologyAnimations
          .watch(context);

      return SettingsContentView(
        title: LocaleKeys.settings_appearance.tr(),
        description: LocaleKeys.settings_appearance_desc.tr(),
        children: [
          SettingsSection(
            title: LocaleKeys.settings_theme.tr(),
            description: LocaleKeys.settings_theme_desc.tr(),
            icon: Icons.palette_outlined,
            children: [
              SettingsLinkTile(
                icon: Icons.contrast,
                title: LocaleKeys.theme_mode.tr(),
                subtitle: LocaleKeys.theme_mode_desc.tr(),
                value: _themeModeLabel(themeMode),
                onTap: () => _selectThemeMode(context),
              ),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 5,
                ),
                leading: const Icon(Icons.color_lens_outlined),
                title: Text(LocaleKeys.theme_color.tr()),
                subtitle: Text(LocaleKeys.theme_color_desc.tr()),
                trailing: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: themeColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline,
                      width: 2,
                    ),
                  ),
                ),
                onTap: () => showThemeColorPicker(context),
              ),
              SettingsLinkTile(
                icon: Icons.language,
                title: LocaleKeys.language.tr(),
                subtitle: LocaleKeys.language_desc.tr(),
                value: context.locale.languageCode == 'zh' ? '简体中文' : 'English',
                onTap: () => _selectLanguage(context),
              ),
            ],
          ),
          SettingsSection(
            title: LocaleKeys.settings_display.tr(),
            description: LocaleKeys.settings_display_desc.tr(),
            icon: Icons.view_compact_outlined,
            children: [
              SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 18),
                title: Text(LocaleKeys.compact_peer_cards.tr()),
                subtitle: Text(LocaleKeys.compact_peer_cards_desc.tr()),
                value: compactPeerCards,
                onChanged: services.appSettings.setCompactPeerCards,
              ),
              SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 18),
                title: Text(LocaleKeys.reduce_animation_updates.tr()),
                subtitle: Text(LocaleKeys.reduce_animation_updates_desc.tr()),
                value: reduceTopologyAnimations,
                onChanged: services.appSettings.setReduceTopologyAnimations,
              ),
            ],
          ),
        ],
      );
    });
  }
}
