import 'package:astral/core/platform/app_info.dart';
import 'package:astral/core/services/service_manager.dart';
import 'package:astral/features/settings/models/settings_availability.dart';
import 'package:astral/features/settings/widgets/appearance_settings_content.dart';
import 'package:astral/features/settings/widgets/general_settings_content.dart';
import 'package:astral/features/settings/widgets/network_connection_settings_content.dart';
import 'package:astral/features/settings/widgets/permissions_settings_content.dart';
import 'package:astral/features/settings/widgets/support_about_settings_content.dart';
import 'package:astral/features/settings/widgets/update_settings_content.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';

class _SettingsCategory {
  final String titleKey;
  final String descriptionKey;
  final IconData icon;
  final List<String> keywords;
  final SettingsAvailability availability;

  const _SettingsCategory({
    required this.titleKey,
    required this.descriptionKey,
    required this.icon,
    required this.keywords,
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
  final _searchController = TextEditingController();
  int _selectedIndex = 0;
  String _query = '';

  static const _categories = [
    _SettingsCategory(
      titleKey: 'settings_general',
      descriptionKey: 'settings_general_short_desc',
      icon: Icons.tune,
      keywords: [
        'startup',
        'boot',
        'sign in',
        'tray',
        'close button',
        'auto connect',
        '启动',
        '登录',
        '托盘',
        '关闭按钮',
      ],
    ),
    _SettingsCategory(
      titleKey: 'settings_appearance',
      descriptionKey: 'settings_appearance_short_desc',
      icon: Icons.palette_outlined,
      keywords: [
        'theme',
        'color',
        'language',
        'compact peer cards',
        'topology animations',
        'display',
        '主题',
        '语言',
        '紧凑节点卡片',
        '拓扑动画',
      ],
    ),
    _SettingsCategory(
      titleKey: 'settings_network_connection',
      descriptionKey: 'settings_network_connection_short_desc',
      icon: Icons.hub_outlined,
      keywords: [
        'network',
        'connection',
        'retry',
        'protocol',
        'encryption',
        'p2p',
        'tun',
        'socks5',
        'local proxy',
        'adapter priority',
        'nat',
        'vpn',
        'listen',
        'port',
        '网络',
        '连接',
        '协议',
      ],
    ),
    _SettingsCategory(
      titleKey: 'settings_updates',
      descriptionKey: 'settings_updates_short_desc',
      icon: Icons.system_update_alt,
      keywords: [
        'update',
        'beta',
        'prerelease',
        'version',
        'download',
        'mirror',
        '更新',
        '测试版',
        '版本',
        '镜像',
      ],
    ),
    _SettingsCategory(
      titleKey: 'settings_permissions',
      descriptionKey: 'settings_permissions_short_desc',
      icon: Icons.admin_panel_settings_outlined,
      keywords: [
        'permission',
        'notification',
        'install',
        'android',
        '权限',
        '通知',
      ],
      availability: SettingsAvailability.androidOnly,
    ),
    _SettingsCategory(
      titleKey: 'settings_support_about',
      descriptionKey: 'settings_support_about_short_desc',
      icon: Icons.support_agent,
      keywords: [
        'support',
        'about',
        'logs',
        'diagnostics',
        'version',
        'build channel',
        '帮助',
        '日志',
      ],
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<int> get _filteredIndices {
    final query = _query.trim().toLowerCase();
    final visibleIndices = List.generate(
      _categories.length,
      (index) => index,
    ).where((index) => _categories[index].availability.isVisible);

    if (query.isEmpty) return visibleIndices.toList();

    return visibleIndices.where((index) {
      final category = _categories[index];
      final searchable =
          [
            category.titleKey.tr(),
            category.descriptionKey.tr(),
            ...category.keywords,
          ].join(' ').toLowerCase();
      return searchable.contains(query);
    }).toList();
  }

  Widget _contentFor(int index) {
    return switch (index) {
      0 => const GeneralSettingsContent(),
      1 => const AppearanceSettingsContent(),
      2 => const NetworkConnectionSettingsContent(),
      3 => const UpdateSettingsContent(),
      4 => const PermissionsSettingsContent(),
      _ => const SupportAboutSettingsContent(),
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

  String _categoryValue(int index) {
    final services = ServiceManager();
    return switch (index) {
      0 =>
        services.startupState.startupAutoConnect.value
            ? 'auto_connect_on'.tr()
            : 'saved_automatically'.tr(),
      1 => switch (services.themeState.themeMode.value) {
        ThemeMode.system => 'theme_system'.tr(),
        ThemeMode.light => 'theme_light'.tr(),
        ThemeMode.dark => 'theme_dark'.tr(),
      },
      2 =>
        services.networkConfigState.defaultProtocol.value.isEmpty
            ? 'TCP'
            : services.networkConfigState.defaultProtocol.value.toUpperCase(),
      3 => services.updateState.beta.value ? 'Beta' : 'Stable',
      4 => 'platform_specific'.tr(),
      _ => AppInfoUtil.getVersionDisplay(),
    };
  }

  Widget _buildHeader(BuildContext context, bool wide) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.fromLTRB(wide ? 28 : 18, 18, wide ? 28 : 18, 16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(bottom: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child:
          wide
              ? Row(
                children: [
                  Expanded(child: _headerTitle(context)),
                  const SizedBox(width: 24),
                  SizedBox(width: 340, child: _searchField(context)),
                ],
              )
              : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _headerTitle(context),
                  const SizedBox(height: 14),
                  _searchField(context),
                ],
              ),
    );
  }

  Widget _headerTitle(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'settings_title'.tr(),
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          'settings_title_desc'.tr(),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _searchField(BuildContext context) {
    return SearchBar(
      controller: _searchController,
      hintText: 'search_settings'.tr(),
      leading: const Icon(Icons.search),
      trailing: [
        if (_query.isNotEmpty)
          IconButton(
            tooltip: 'clear'.tr(),
            icon: const Icon(Icons.close),
            onPressed: () {
              _searchController.clear();
              setState(() => _query = '');
            },
          ),
      ],
      elevation: const WidgetStatePropertyAll(0),
      backgroundColor: WidgetStatePropertyAll(
        Theme.of(context).colorScheme.surfaceContainerHigh,
      ),
      onChanged: (value) => setState(() => _query = value),
    );
  }

  Widget _buildSidebar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final indices = _filteredIndices;

    return Material(
      color: colorScheme.surfaceContainerLowest,
      child: SizedBox(
        width: 270,
        child:
            indices.isEmpty
                ? _emptySearch(context)
                : ListView.builder(
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
    final indices = _filteredIndices;
    final colorScheme = Theme.of(context).colorScheme;

    if (indices.isEmpty) return _emptySearch(context);

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
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 82),
                    child: Text(
                      _categoryValue(index),
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right, size: 20),
                ],
              ),
              onTap: () => _openCategory(context, index, false),
            ),
          ),
        );
      },
    );
  }

  Widget _emptySearch(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off,
              size: 48,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 12),
            Text(
              'no_settings_found'.tr(),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'no_settings_found_desc'.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Watch(
        (context) => LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= _wideBreakpoint;

            return Column(
              children: [
                _buildHeader(context, wide),
                Expanded(
                  child:
                      wide
                          ? Row(
                            children: [
                              _buildSidebar(context),
                              VerticalDivider(
                                width: 1,
                                color:
                                    Theme.of(
                                      context,
                                    ).colorScheme.outlineVariant,
                              ),
                              Expanded(
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 180),
                                  child: KeyedSubtree(
                                    key: ValueKey(_selectedIndex),
                                    child: _contentFor(_selectedIndex),
                                  ),
                                ),
                              ),
                            ],
                          )
                          : _buildCompactOverview(context),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
