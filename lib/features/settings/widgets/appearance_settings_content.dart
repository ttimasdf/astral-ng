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
        children: [
          SettingsSection(
            title: LocaleKeys.settings_theme.tr(),
            description: LocaleKeys.settings_theme_desc.tr(),
            icon: Icons.palette_outlined,
            children: [
              SettingsSegmentedChoice<ThemeMode>(
                title: LocaleKeys.theme_mode.tr(),
                description: LocaleKeys.theme_mode_desc.tr(),
                value: themeMode,
                segments: [
                  ButtonSegment(
                    value: ThemeMode.system,
                    icon: const Icon(Icons.brightness_auto),
                    label: Text(_themeModeLabel(ThemeMode.system)),
                  ),
                  ButtonSegment(
                    value: ThemeMode.light,
                    icon: const Icon(Icons.light_mode),
                    label: Text(_themeModeLabel(ThemeMode.light)),
                  ),
                  ButtonSegment(
                    value: ThemeMode.dark,
                    icon: const Icon(Icons.dark_mode),
                    label: Text(_themeModeLabel(ThemeMode.dark)),
                  ),
                ],
                onChanged: services.theme.updateThemeMode,
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
