import 'package:enmesh/features/rooms/utils/random_name.dart';
import 'package:enmesh/features/rooms/dialogs/add_room_dialog.dart';
import 'package:enmesh/features/rooms/dialogs/edit_room_dialog.dart';
import 'package:enmesh/features/rooms/dialogs/room_share_export_dialog.dart';
import 'package:enmesh/features/rooms/dialogs/room_share_import_dialog.dart';
import 'package:enmesh/features/rooms/pages/user_page.dart';
import 'package:enmesh/features/rooms/widgets/room_action_stack.dart';
import 'package:enmesh/features/rooms/widgets/room_card.dart';
import 'package:enmesh/features/rooms/widgets/room_reorder_sheet.dart';
import 'package:enmesh/features/rooms/widgets/room_settings_sheet.dart';
import 'package:enmesh/generated/locale_keys.g.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:enmesh/core/services/service_manager.dart';
import 'package:enmesh/core/states/connection_state.dart';
import 'package:enmesh/core/models/room.dart';
import 'package:uuid/uuid.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:easy_localization/easy_localization.dart';

class RoomPage extends StatefulWidget {
  const RoomPage({super.key});

  @override
  State<RoomPage> createState() => _RoomPageState();
}

// 在_RoomPageState类中添加排序相关方法
class _RoomPageState extends State<RoomPage> {
  final _services = ServiceManager();
  bool _showTopology = true;
  // 根据宽度计算列数
  int _getColumnCount(double width) {
    if (width >= 1200) {
      return 4;
    } else if (width >= 900) {
      return 3;
    } else if (width >= 600) {
      return 2;
    }
    return 1;
  }

  // 显示输入分享码的弹窗
  void _showPasteDialog() {
    showDialog(
      context: context,
      builder: (context) {
        String shareCode = '';
        return AlertDialog(
          title: const Text('导入房间'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                onChanged: (value) {
                  shareCode = value;
                },
                decoration: const InputDecoration(
                  hintText: '请输入分享码或链接',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    await RoomShareImportDialogs.importFromClipboard(context);
                  },
                  icon: const Icon(Icons.paste),
                  label: const Text('从剪贴板导入'),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () async {
                if (shareCode.isNotEmpty) {
                  Navigator.of(context).pop();
                  await RoomShareImportDialogs.importRoom(context, shareCode);
                }
              },
              child: const Text('导入'),
            ),
          ],
        );
      },
    );
  }

  // 构建房间列表视图
  Widget _buildRoomsView(BuildContext context, BoxConstraints constraints) {
    final columnCount = _getColumnCount(constraints.maxWidth);

    return Watch((context) {
      final rooms = _services.roomState.rooms.watch(context);
      final selectedRoom = _services.roomState.selectedRoom.watch(context);

      return CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(16.0),
            sliver: SliverMasonryGrid.count(
              crossAxisCount: columnCount,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childCount: rooms.length,
              itemBuilder: (context, index) {
                final room = rooms[index];
                final isSelected = selectedRoom?.id == room.id;
                return RoomCard(
                  key: ValueKey(room.id),
                  room: room,
                  isSelected: isSelected,
                  onEdit: () {
                    showEditRoomDialog(context, room: room);
                  },
                  onDelete: () {
                    _services.room.deleteRoom(room.id);
                  },
                  onShare: () {
                    RoomShareExportDialogs.showShareDialog(context, room);
                  },
                );
              },
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
          ),
        ],
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Watch((context) {
      final connectionState = _services.connectionState.connectionState.watch(
        context,
      );
      final selectedRoom = _services.roomState.selectedRoom.watch(context);
      final connected = connectionState != CoState.idle;
      return Scaffold(
        body: Column(
          children: [
            Expanded(
              child:
                  connected
                      ? UserPage(showTopology: _showTopology)
                      : LayoutBuilder(
                        builder: (context, constraints) {
                          return _buildRoomsView(context, constraints);
                        },
                      ),
            ),
          ],
        ),
        floatingActionButton:
            connected
                ? RoomViewActions(
                  showTopology: _showTopology,
                  onToggleView:
                      () => setState(() => _showTopology = !_showTopology),
                  onOpenSettings: () => RoomSettingsSheet.show(context),
                  onCopyLink:
                      selectedRoom == null
                          ? null
                          : () => RoomShareExportDialogs.copyShareLink(
                            context,
                            selectedRoom,
                            linkOnly: true,
                          ),
                )
                : RoomListActions(
                  onSort: () {
                    RoomReorderSheet.show(
                      context,
                      _services.roomState.rooms.value,
                    );
                  },
                  onImport: _showPasteDialog,
                  onAdd: () => showAddRoomDialog(context),
                ),
      );
    });
  }
}

class RoomListActions extends StatelessWidget {
  final VoidCallback onSort;
  final VoidCallback onImport;
  final VoidCallback onAdd;

  const RoomListActions({
    super.key,
    required this.onSort,
    required this.onImport,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) => RoomActionStack(
    actions: [
      RoomAction(
        key: const ValueKey('room_sort'),
        heroTag: 'room_sort',
        tooltip: LocaleKeys.rooms_sort_rooms.tr(),
        icon: Icons.sort,
        onPressed: onSort,
      ),
      RoomAction(
        key: const ValueKey('room_import'),
        heroTag: 'room_import',
        tooltip: LocaleKeys.rooms_import_room.tr(),
        icon: Icons.file_download_outlined,
        onPressed: onImport,
      ),
      RoomAction(
        key: const ValueKey('room_add'),
        heroTag: 'room_add',
        tooltip: LocaleKeys.rooms_add_room.tr(),
        icon: Icons.add,
        onPressed: onAdd,
      ),
    ],
  );
}

class RoomViewActions extends StatelessWidget {
  final bool showTopology;
  final VoidCallback onToggleView;
  final VoidCallback onOpenSettings;
  final VoidCallback? onCopyLink;

  const RoomViewActions({
    super.key,
    required this.showTopology,
    required this.onToggleView,
    required this.onOpenSettings,
    required this.onCopyLink,
  });

  @override
  Widget build(BuildContext context) => RoomActionStack(
    actions: [
      if (onCopyLink != null)
        RoomAction(
          key: const ValueKey('room_copy_link'),
          heroTag: 'room_copy_link',
          tooltip: LocaleKeys.rooms_copy_link.tr(),
          icon: Icons.share_rounded,
          onPressed: onCopyLink!,
        ),
      RoomAction(
        key: const ValueKey('room_settings'),
        heroTag: 'room_settings',
        tooltip: LocaleKeys.rooms_settings.tr(),
        icon: Icons.bar_chart,
        onPressed: onOpenSettings,
      ),
      RoomAction(
        key: const ValueKey('room_view_toggle'),
        heroTag: 'topology_toggle',
        tooltip:
            showTopology
                ? LocaleKeys.rooms_list_view.tr()
                : LocaleKeys.rooms_network_topology_view.tr(),
        icon: showTopology ? Icons.list : Icons.auto_awesome,
        onPressed: onToggleView,
      ),
    ],
  );
}

void addRoomForMode(
  bool simpleMode,
  String? name,
  String? roomname,
  String? password,
) {
  final room = Room(
    name: name ?? RandomName(),
    simpleMode: simpleMode,
    roomName: simpleMode ? Uuid().v4() : (roomname ?? ''),
    password: simpleMode ? Uuid().v4() : (password ?? ''),
    messageKey: simpleMode ? Uuid().v4() : '',
    tags: [],
  );
  ServiceManager().room.addRoom(room);
}
