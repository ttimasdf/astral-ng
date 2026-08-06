import 'package:astral/generated/locale_keys.g.dart';
import 'package:astral/features/settings/models/settings_availability.dart';
import 'package:astral/features/settings/widgets/appearance_settings_content.dart';
import 'package:astral/features/settings/widgets/general_settings_content.dart';
import 'package:astral/features/settings/widgets/network_connection_settings_content.dart';
import 'package:astral/features/settings/widgets/permissions_settings_content.dart';
import 'package:astral/features/settings/widgets/update_about_settings_content.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class _SettingsCategory {
  final String titleKey;
  final String descriptionKey;
  final IconData icon;
  final SettingsAvailability availability;

  const _SettingsCategory({
    required this.titleKey,
    required this.descriptionKey,
    required this.icon,
    this.availability = SettingsAvailability.all,
  });
}

class SettingsMainPage extends StatefulWidget {
  const SettingsMainPage({super.key});

  @override
  State<SettingsMainPage> createState() => _SettingsMainPageState();
}

class _SettingsMainPageState extends State<SettingsMainPage> {
  static const _wideBreakpoint = 860.0;
  int _selectedIndex = 0;

  static const _categories = [
    _SettingsCategory(
      titleKey: LocaleKeys.settings_general,
      descriptionKey: LocaleKeys.settings_general_short_desc,
      icon: Icons.tune,
    ),
    _SettingsCategory(
      titleKey: LocaleKeys.settings_appearance,
      descriptionKey: LocaleKeys.settings_appearance_short_desc,
      icon: Icons.palette_outlined,
    ),
    _SettingsCategory(
      titleKey: LocaleKeys.settings_network_connection,
      descriptionKey: LocaleKeys.settings_network_connection_short_desc,
      icon: Icons.hub_outlined,
    ),
    _SettingsCategory(
      titleKey: LocaleKeys.settings_permissions,
      descriptionKey: LocaleKeys.settings_permissions_short_desc,
      icon: Icons.admin_panel_settings_outlined,
      availability: SettingsAvailability.androidOnly,
    ),
    _SettingsCategory(
      titleKey: LocaleKeys.settings_update_about,
      descriptionKey: LocaleKeys.settings_update_about_desc,
      icon: Icons.system_update_alt,
    ),
  ];

  List<int> get _visibleIndices =>
      List.generate(
        _categories.length,
        (index) => index,
      ).where((index) => _categories[index].availability.isVisible).toList();

  Widget _contentFor(int index) {
    return switch (index) {
      0 => const GeneralSettingsContent(),
      1 => const AppearanceSettingsContent(),
      2 => const NetworkConnectionSettingsContent(),
      3 => const PermissionsSettingsContent(),
      _ => const UpdateAboutSettingsContent(),
    };
  }

  Widget _buildCategoryRoute(BuildContext context, int index) {
    final category = _categories[index];
    return Scaffold(
      appBar: AppBar(title: Text(category.titleKey.tr())),
      body: _contentFor(index),
    );
  }

  void _openCategory(BuildContext context, int index, bool wide) {
    if (wide) {
      setState(() => _selectedIndex = index);
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _buildCategoryRoute(context, index),
      ),
    );
  }

  Widget _buildSidebar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final indices = _visibleIndices;

    return Material(
      color: colorScheme.surfaceContainerLowest,
      child: SizedBox(
        width: 270,
        child: ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: indices.length,
          itemBuilder: (context, position) {
            final index = indices[position];
            final category = _categories[index];
            final selected = _selectedIndex == index;

            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: ListTile(
                selected: selected,
                selectedTileColor: colorScheme.primaryContainer,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 5,
                ),
                leading: Icon(
                  category.icon,
                  color:
                      selected
                          ? colorScheme.onPrimaryContainer
                          : colorScheme.onSurfaceVariant,
                ),
                title: Text(
                  category.titleKey.tr(),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  category.descriptionKey.tr(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () => _openCategory(context, index, true),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCompactOverview(BuildContext context) {
    final indices = _visibleIndices;
    final colorScheme = Theme.of(context).colorScheme;

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
      itemCount: indices.length,
      itemBuilder: (context, position) {
        final index = indices[position];
        final category = _categories[index];

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Material(
            color: colorScheme.surfaceContainerLow,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(17),
              side: BorderSide(color: colorScheme.outlineVariant),
            ),
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 9,
              ),
              leading: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  category.icon,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
              title: Text(
                category.titleKey.tr(),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(category.descriptionKey.tr()),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _openCategory(context, index, false),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.locale;

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= _wideBreakpoint;

          if (!wide) return _buildCompactOverview(context);

          return Row(
            children: [
              _buildSidebar(context),
              VerticalDivider(
                width: 1,
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: KeyedSubtree(
                    key: ValueKey((_selectedIndex, locale.languageCode)),
                    child: _contentFor(_selectedIndex),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
