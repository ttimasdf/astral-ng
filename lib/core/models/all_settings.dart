import 'package:isar_community/isar.dart';
import 'package:astral/shared/utils/github_proxy_selector.dart';
part 'all_settings.g.dart';

@collection
class AllSettings {
  /// 主键ID，固定为1因为只需要一个实例
  Id id = 1;

  /// 当前选择的房间 ID
  int? selectedRoomId;

  /// 节点显示名称
  String? peerName;

  /// 节点监听地址
  List<String>? peerListeners = ["tcp://0.0.0.0:0", "udp://0.0.0.0:0"];

  /// Android VPN 额外路由
  List<String> androidVpnRoutes = [];

  /// 使用紧凑节点卡片
  bool compactPeerCards = true;

  /// 关闭窗口时保留后台进程并隐藏到托盘
  bool closeToTray = true;

  /// 登录系统时启动 AstralNG
  bool launchAtLogin = false;

  /// 启动后隐藏到系统托盘
  bool launchToTray = false;

  /// 启动后自动连接
  bool connectAfterLaunch = false;

  /// 优先使用 AstralNG Windows 适配器
  bool preferAstralAdapter = true;

  /// 接收 Beta 更新
  bool receiveBetaUpdates = false;

  /// 自动检查更新
  bool automaticUpdateChecks = true;

  /// 更新包下载源
  String updateDownloadSource = GitHubProxySelector.autoMode;

  /// 节点排序选项 (0: 默认, 1: 延迟, 2: 用户名)
  int peerSortOption = 0;

  /// 节点排序方式 (0: 升序, 1: 降序)
  int peerSortOrder = 0;

  /// 节点显示模式 (0: 全部, 1: 用户, 2: 服务器)
  int peerDisplayMode = 0;

  /// 最近检查到的可用版本
  String? latestAvailableVersion;

  /// 显示 Android 后台连接通知
  bool connectionNotificationEnabled = true;

  /// 降低拓扑动画与刷新频率
  bool reduceTopologyAnimations = false;

  /// 连接失败后的重试次数，0 表示禁用
  int connectionRetryLimit = 3;
}
