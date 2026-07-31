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
        horizontalTitleGap: 4,
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
      child: _ServerSwipeAction(
        key: ValueKey('server-swipe-${server.id}'),
        server: server,
        background: _buildSwipeBackground(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.only(left: 24),
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
        secondaryBackground: _buildSwipeBackground(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 24),
          color: colorScheme.errorContainer,
          foregroundColor: colorScheme.onErrorContainer,
          icon: Icons.delete_outline,
          label: '删除',
        ),
        onToggle: onToggle,
        onConfirmDelete: onConfirmDelete,
        onDelete: onDelete,
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

class _ServerSwipeAction extends StatefulWidget {
  const _ServerSwipeAction({
    super.key,
    required this.server,
    required this.background,
    required this.secondaryBackground,
    required this.onToggle,
    required this.onConfirmDelete,
    required this.onDelete,
    required this.child,
  });

  final ServerMod server;
  final Widget background;
  final Widget secondaryBackground;
  final Future<void> Function(bool) onToggle;
  final Future<bool> Function() onConfirmDelete;
  final Future<void> Function() onDelete;
  final Widget child;

  @override
  State<_ServerSwipeAction> createState() => _ServerSwipeActionState();
}

class _ServerSwipeActionState extends State<_ServerSwipeAction>
    with SingleTickerProviderStateMixin {
  static const _maximumDragFraction = 0.24;
  static const _triggerFraction = 0.14;

  late final AnimationController _returnController;
  Animation<double>? _returnAnimation;
  double _dragExtent = 0;
  double _rowWidth = 0;
  double _backgroundDirection = 0;
  bool _handlingAction = false;

  @override
  void initState() {
    super.initState();
    _returnController =
        AnimationController(
            vsync: this,
            duration: const Duration(milliseconds: 280),
          )
          ..addListener(() {
            final animation = _returnAnimation;
            if (animation == null || !mounted) return;
            setState(() => _dragExtent = animation.value);
          })
          ..addStatusListener((status) {
            if (status != AnimationStatus.completed || !mounted) return;
            setState(() {
              _dragExtent = 0;
              _backgroundDirection = 0;
            });
          });
  }

  @override
  void dispose() {
    _returnController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _rowWidth = constraints.maxWidth;
        final background =
            _backgroundDirection < 0
                ? widget.secondaryBackground
                : widget.background;

        return ClipRect(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragStart: _handleDragStart,
            onHorizontalDragUpdate: _handleDragUpdate,
            onHorizontalDragEnd: _handleDragEnd,
            onHorizontalDragCancel: _animateBack,
            child: Stack(
              children: [
                if (_backgroundDirection != 0)
                  Positioned.fill(child: IgnorePointer(child: background)),
                Transform.translate(
                  key: ValueKey('server-swipe-content-${widget.server.id}'),
                  offset: Offset(_dragExtent, 0),
                  child: widget.child,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handleDragStart(DragStartDetails details) {
    if (_handlingAction) return;
    _returnController.stop();
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (_handlingAction || _rowWidth <= 0) return;

    final maximumExtent = _rowWidth * _maximumDragFraction;
    final nextExtent =
        (_dragExtent + details.delta.dx)
            .clamp(-maximumExtent, maximumExtent)
            .toDouble();

    setState(() {
      _dragExtent = nextExtent;
      if (nextExtent != 0) _backgroundDirection = nextExtent.sign;
    });
  }

  Future<void> _handleDragEnd(DragEndDetails details) async {
    if (_handlingAction || _rowWidth <= 0) return;

    if (_dragExtent.abs() < _rowWidth * _triggerFraction) {
      _animateBack();
      return;
    }

    _handlingAction = true;
    final swipedRight = _dragExtent > 0;
    _animateBack();

    if (swipedRight) {
      await widget.onToggle(!widget.server.enable);
    } else if (await widget.onConfirmDelete()) {
      await widget.onDelete();
    }

    if (!mounted) return;
    _handlingAction = false;
  }

  void _animateBack() {
    if (!mounted) return;
    _returnController.stop();
    _returnController.reset();
    _returnAnimation = Tween<double>(begin: _dragExtent, end: 0).animate(
      CurvedAnimation(parent: _returnController, curve: Curves.easeOutBack),
    );
    _returnController.forward();
  }
}
