import 'package:astral/core/services/service_manager.dart';
import 'package:astral/core/states/connection_state.dart';
import 'package:astral/core/states/display_state.dart';
import 'package:astral/src/rust/api/simple.dart';
import 'package:astral/shared/utils/network/node_utils.dart';
import 'package:astral/features/rooms/widgets/all_user_card.dart';
import 'package:astral/features/rooms/widgets/mini_user_card.dart';
import 'package:astral/features/rooms/widgets/mesh_constellation.dart';
import 'package:astral/features/rooms/widgets/room_network_stats.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:astral/generated/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:signals_flutter/signals_flutter.dart';

class UserPage extends StatelessWidget {
  final bool showTopology;

  const UserPage({super.key, required this.showTopology});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Watch((context) {
      final netStatus = ServiceManager().connectionState.netStatus.watch(
        context,
      );
      final connectionState = ServiceManager().connectionState.connectionState
          .watch(context);

      if (connectionState != CoState.connected) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.cloud_off_rounded,
                size: 48,
                color: colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                LocaleKeys.rooms_no_data.tr(),
                style: TextStyle(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      } else if (netStatus == null || netStatus.nodes.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.people_outline,
                size: 64,
                color: colorScheme.primary.withValues(alpha: 0.6),
              ),
              const SizedBox(height: 16),
              Text(
                LocaleKeys.rooms_no_members.tr(),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                LocaleKeys.rooms_no_other_peers.tr(),
                style: TextStyle(
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        );
      } else {
        final localIPv4 = ServiceManager().networkConfigState.ipv4.watch(
          context,
        );
        final statsPanel = RoomNetworkStatsPanel(
          stats: RoomNetworkStats.fromNetwork(
            netStatus.nodes,
            localIp: localIPv4,
          ),
        );
        if (showTopology) {
          return Column(
            children: [
              statsPanel,
              Expanded(
                child: MeshConstellation(
                  nodes: netStatus.nodes,
                  localIp: localIPv4,
                  reduceMotion: ServiceManager()
                      .appSettingsState
                      .reduceTopologyAnimations
                      .watch(context),
                ),
              ),
            ],
          );
        }

        // 获取排序选项
        final sortOption = ServiceManager().displayState.sortOption.watch(
          context,
        );
        // 获取排序顺序
        final sortOrder = ServiceManager().displayState.sortOrder.watch(
          context,
        );
        // 获取显示模式
        final displayMode = ServiceManager().displayState.displayMode.watch(
          context,
        );
        final compactPeerCards = ServiceManager().displayState.compactPeerCards
            .watch(context);
        // 获取原始节点列表
        final nodes = List<KVNodeInfo>.from(netStatus.nodes);

        // 根据排序选项对节点进行排序
        if (sortOption == UserSortOption.latency) {
          // 按延迟排序
          nodes.sort((a, b) {
            int comparison = a.latencyMs.compareTo(b.latencyMs);
            return sortOrder == UserSortOrder.ascending
                ? comparison
                : -comparison;
          });
        } else if (sortOption == UserSortOption.nameLength) {
          // 按用户名长度排序
          nodes.sort((a, b) {
            int comparison = a.hostname.length.compareTo(b.hostname.length);
            return sortOrder == UserSortOrder.ascending
                ? comparison
                : -comparison;
          });
        }

        // 根据显示模式过滤节点
        List<KVNodeInfo> filteredNodes = nodes;
        if (displayMode == UserDisplayMode.users) {
          // 仅显示用户（排除服务器）
          filteredNodes = nodes.where((node) => !isServerNode(node)).toList();
        } else if (displayMode == UserDisplayMode.servers) {
          // 仅显示服务器
          filteredNodes = nodes.where((node) => isServerNode(node)).toList();
        }

        // 返回一个可滚动的视图
        return Column(
          children: [
            statsPanel,
            Expanded(
              child: CustomScrollView(
                // 始终允许滚动,即使内容不足一屏
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // 为网格添加内边距
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
                    // 使用瀑布流网格布局
                    sliver: SliverMasonryGrid(
                      // 配置网格布局参数
                      gridDelegate:
                          SliverSimpleGridDelegateWithFixedCrossAxisCount(
                            // 根据屏幕宽度动态计算列数
                            crossAxisCount: _getColumnCount(
                              MediaQuery.of(context).size.width,
                            ),
                          ),
                      // 设置网格项之间的间距
                      mainAxisSpacing: 8.0,
                      crossAxisSpacing: 8.0,
                      // 配置子项构建器
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          // 获取当前索引对应的玩家数据
                          final player = filteredNodes[index];
                          // 根据简单列表模式选项返回不同的卡片组件
                          return compactPeerCards
                              ? MiniUserCard(
                                key: ValueKey(player.peerId),
                                player: player,
                                colorScheme: colorScheme,
                                localIPv4: localIPv4,
                              )
                              : AllUserCard(
                                key: ValueKey(player.peerId),
                                player: player,
                                colorScheme: colorScheme,
                                localIPv4: localIPv4,
                              );
                        },
                        // 设置子项数量为过滤后的节点数量
                        childCount: filteredNodes.length,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      }
    });
  }

  // 根据宽度计算列数
  int _getColumnCount(double width) {
    if (width >= 1200) {
      return 3;
    } else if (width >= 900) {
      return 2;
    }
    return 1; // 窄屏使用单列
  }
}
