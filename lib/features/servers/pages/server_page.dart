import 'package:astral/core/services/service_manager.dart';
import 'package:astral/core/models/server_mod.dart';
import 'package:astral/shared/utils/network/blocked_servers.dart';
import 'package:astral/features/servers/dialogs/server_dialog.dart';
import 'package:astral/features/servers/widgets/server_list_tile.dart';
import 'package:astral/core/ui/app_snack_bars.dart';
import 'package:astral/core/ui/base_settings_page.dart';
import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';

/// 服务器管理页（底栏独立入口）
class ServersPage extends BaseStatefulSettingsPage {
  const ServersPage({super.key});

  @override
  BaseStatefulSettingsPageState<ServersPage> createState() =>
      _ServersPageState();
}

class _ServersPageState extends BaseStatefulSettingsPageState<ServersPage> {
  @override
  void initState() {
    super.initState();
    // 启动服务器状态定期检测
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final servers = ServiceManager().serverState.servers.value;
      ServiceManager().serverStatusState.startPeriodicCheck(
        servers,
        const Duration(seconds: 30),
      );
    });
  }

  @override
  void dispose() {
    ServiceManager().serverStatusState.stopPeriodicCheck();
    super.dispose();
  }

  @override
  bool get showAppBar => false;

  @override
  String get title => '';

  @override
  bool get showBackButton => false;

  @override
  Widget? buildFloatingActionButton(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => showAddServerDialog(context),
      child: const Icon(Icons.add),
    );
  }

  @override
  Widget buildContent(BuildContext context) {
    final platform = Theme.of(context).platform;
    final useMobileActions =
        platform == TargetPlatform.android || platform == TargetPlatform.iOS;

    return Watch((context) {
      final servers = ServiceManager().serverState.servers.watch(context);

      if (servers.isEmpty) {
        return buildEmptyState(
          context: context,
          icon: Icons.dns_outlined,
          title: '暂无服务器',
          actionLabel: '添加服务器',
          onAction: () => showAddServerDialog(context),
        );
      }

      return ReorderableListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: servers.length,
        buildDefaultDragHandles: false,
        proxyDecorator: (child, index, animation) {
          return Material(
            elevation: 0,
            color: Colors.transparent,
            child: child,
          );
        },
        onReorderItem: (oldIndex, newIndex) async {
          final newServers = List<ServerMod>.from(servers);
          final server = newServers.removeAt(oldIndex);
          newServers.insert(newIndex, server);
          await ServiceManager().server.reorderServers(newServers);
        },
        itemBuilder: (context, index) {
          final server = servers[index];

          final row = ServerListTile(
            server: server,
            useMobileActions: useMobileActions,
            onEdit: () => _editServer(server),
            onToggle:
                (value) =>
                    ServiceManager().server.setServerEnable(server, value),
            onConfirmDelete: () => _showDeleteConfirmDialog(server),
            onDelete: () => ServiceManager().server.deleteServer(server),
          );

          if (useMobileActions) {
            return ReorderableDelayedDragStartListener(
              key: ValueKey(server.id),
              index: index,
              child: row,
            );
          }

          return ReorderableDragStartListener(
            key: ValueKey(server.id),
            index: index,
            child: row,
          );
        },
      );
    });
  }

  void _editServer(ServerMod server) {
    if (BlockedServers.isBlocked(server.url)) {
      AppSnackBars.info(
        context,
        '不可编辑',
        '此服务器不可编辑',
        duration: const Duration(seconds: 2),
      );
      return;
    }

    showEditServerDialog(context, server: server);
  }

  Future<bool> _showDeleteConfirmDialog(ServerMod server) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('删除服务器'),
            content: Text('确定要删除服务器 "${server.name}" 吗？此操作不可撤销。'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
                child: const Text('删除'),
              ),
            ],
          ),
    );

    return confirmed ?? false;
  }
}
