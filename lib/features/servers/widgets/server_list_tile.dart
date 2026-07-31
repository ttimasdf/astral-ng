import 'package:astral/core/models/server_mod.dart';
import 'package:astral/shared/utils/network/blocked_servers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

class ServerListTile extends StatelessWidget {
  const ServerListTile({
    super.key,
    required this.server,
    required this.useMobileActions,
    required this.onEdit,
    required this.onToggle,
    required this.onConfirmDelete,
    required this.onDelete,
  });

  final ServerMod server;
  final bool useMobileActions;
  final VoidCallback onEdit;
  final Future<void> Function(bool) onToggle;
  final Future<bool> Function() onConfirmDelete;
  final Future<void> Function() onDelete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final card = Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: useMobileActions ? onEdit : null,
        horizontalTitleGap: 12,
        leading: Container(
          key: ValueKey('server-state-indicator-${server.id}'),
          width: 4,
          height: 40,
          decoration: BoxDecoration(
            color: server.enable ? Colors.green : Colors.red,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        title: Text(
          server.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          BlockedServers.isBlocked(server.url) ? '***' : server.url,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: useMobileActions ? null : _buildDesktopActions(colorScheme),
      ),
    );

    if (!useMobileActions) return card;

    return Semantics(
      customSemanticsActions: {
        CustomSemanticsAction(label: server.enable ? '停用服务器' : '启用服务器'): () {
          onToggle(!server.enable);
        },
        const CustomSemanticsAction(label: '删除服务器'): () {
          _deleteIfConfirmed();
        },
      },
      child: Dismissible(
        key: ValueKey('server-swipe-${server.id}'),
        direction: DismissDirection.horizontal,
        dismissThresholds: const {
          DismissDirection.startToEnd: 0.3,
          DismissDirection.endToStart: 0.3,
        },
        background: _buildSwipeBackground(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.only(left: 24),
          color: colorScheme.errorContainer,
          foregroundColor: colorScheme.onErrorContainer,
          icon: Icons.delete_outline,
          label: '删除',
        ),
        secondaryBackground: _buildSwipeBackground(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 24),
          color:
              server.enable
                  ? colorScheme.secondaryContainer
                  : colorScheme.primaryContainer,
          foregroundColor:
              server.enable
                  ? colorScheme.onSecondaryContainer
                  : colorScheme.onPrimaryContainer,
          icon:
              server.enable
                  ? Icons.toggle_off_outlined
                  : Icons.toggle_on_outlined,
          label: server.enable ? '停用' : '启用',
        ),
        confirmDismiss: (direction) async {
          if (direction == DismissDirection.endToStart) {
            await onToggle(!server.enable);
            return false;
          }
          return onConfirmDelete();
        },
        onDismissed: (_) {
          onDelete();
        },
        child: card,
      ),
    );
  }

  Widget _buildDesktopActions(ColorScheme colorScheme) {
    final isBlocked = BlockedServers.isBlocked(server.url);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Transform.scale(
          scale: 0.8,
          child: Switch(
            value: server.enable,
            onChanged: (value) {
              onToggle(value);
            },
          ),
        ),
        const SizedBox(width: 4),
        PopupMenuButton<String>(
          onSelected: (value) async {
            if (value == 'edit') {
              onEdit();
            } else if (value == 'delete') {
              await _deleteIfConfirmed();
            }
          },
          itemBuilder:
              (context) => [
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(
                        Icons.edit_outlined,
                        size: 18,
                        color:
                            isBlocked
                                ? colorScheme.outline
                                : colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '编辑',
                        style: TextStyle(
                          color: isBlocked ? colorScheme.outline : null,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(
                        Icons.delete_outline,
                        size: 18,
                        color: colorScheme.error,
                      ),
                      const SizedBox(width: 12),
                      Text('删除', style: TextStyle(color: colorScheme.error)),
                    ],
                  ),
                ),
              ],
        ),
      ],
    );
  }

  Future<void> _deleteIfConfirmed() async {
    if (await onConfirmDelete()) {
      await onDelete();
    }
  }

  Widget _buildSwipeBackground({
    required Alignment alignment,
    required EdgeInsets padding,
    required Color color,
    required Color foregroundColor,
    required IconData icon,
    required String label,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: padding,
      alignment: alignment,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: foregroundColor),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: foregroundColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
