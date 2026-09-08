# 更新日志（中文）

本文件是 EasyTier Enmesh 更新日志的中文译本，仅供中文读者阅读。英文版
`CHANGELOG.md` 是唯一权威来源。仅在版本提升（version bump）时翻译对应版本的
章节；两次版本提升之间不维护此文件。

## [v3.0.0] - 2026-09-08

> **版本亮点：** Enmesh 3.0：名称焕新，掌控更从容——重塑的任务控制台、路径感知拓扑界面、更清晰可信的诊断日志。

### 新增

- **Android 快速设置。** 新增快速设置磁贴，显示连接状态，并支持一键连接或断开
  Enmesh。([#10])
- **上游新增功能。**
  - **自动重试。** 新增可配置的失败连接重试次数上限。([upstream-auto-retry])
  - **无 TUN SOCKS5 访问。** 新增可配置的本地监听端口，用于访问虚拟网络。
    ([upstream-#229])
  - **Windows UDP 中继。** 在 Windows 上新增 UDP 广播转发。
    ([upstream-udp-relay])
  - **托盘图标可见性。** 新增在当前会话中隐藏桌面托盘图标的选项。
    ([upstream-#74])
  - **减少动画。** 新增在窗口隐藏时降低拓扑与连接动画更新频率的模式。
    ([upstream-topology])
- **结构化诊断。** 新增经过脱敏的桌面与移动端日志，支持运行时控制、有界持久化、
  关联过滤，并可导出可审查的支持包。([#15])
- **排障工具箱。** 新增启动前诊断开关，以及覆盖应用、网络、路由、EasyTier、
  模块、事件码与原生日志的排查指南。([#15])

### 变更

- **⚠ 破坏性变更 — 包标识。** Enmesh 的包名为 `pw.rabit.enmesh`（金丝雀版为
  `pw.rabit.enmesh.canary`）。旧安装不再接收更新；请卸载旧应用，安装 Enmesh
  并重新配置房间。
- **⚠ 破坏性变更 — 分享链接。** 房间链接与二维码现在使用 `enmesh://`。此前分享的
  `astral://` 链接将无法打开；请在 Enmesh 中重新分享房间。
- **⚠ 破坏性变更 — 金丝雀产物。** 更新产物现以 `enmesh-canary-*` 命名，并由更名后的
  更新 API 提供。旧的金丝雀客户端不再收到更新；请手动安装一次 Enmesh。
- **品牌更名为 EasyTier Enmesh。** 应用现名 Enmesh：界面使用短名称，关于页与文档使用
  "EasyTier Enmesh"。已存储的 Windows 适配器偏好将重置为默认值。
- **选择性 beta 构建。** main 分支的 update-server 与文档变更现在跳过平台构建产物，
  生产部署作为经批准的手动操作提供。
- **⚠ 破坏性变更 — 主线产物。** 匹配 main 构建的下载脚本必须将 `-alpha.RUN+SHA`
  替换为 `-beta.RUN+SHA`；拉取请求产物仍为 alpha。
- **⚠ 破坏性变更 — Android 设置。** Android 用户必须备份房间与中转凭据，卸载旧
  APK，安装 3.0.0，并在设置架构重置后恢复配置。([#12])
- **⚠ 破坏性变更 — 数据目录。** 旧安装可能显示为已重置。桌面用户必须将所有 Isar
  文件移动到应用支持目录的 `db` 目录；其他平台需重新配置。旧日志不会迁移。([#15])
- **⚠ 破坏性变更 — 产物命名。** 下载自动化必须将旧的 `v3.0.0-canary.*` 与
  `v3.0.0` 后缀替换为规范的 SemVer 名称，例如 `3.0.0-alpha.CI_RUN+SHORTREF` 和
  `3.0.0`。([#4])
- **可选更新通道。** 设置现在提供稳定、Beta 与 Alpha 通道。初次选择 Beta 或
  Alpha 时会启用自动检查，同时保留用户可控的开关。
- **更新服务主页。** 新构建使用 `enmesh.rabit.pw`；其服务根页面现以中英文介绍
  EasyTier Enmesh 并附源代码链接。
- **Alpha 产物匹配。** PR 构建现在识别来源提交而非 GitHub 的合成合并提交，成功的
  Alpha 产物因此出现在更新中。
- **响应式设置。** 重新设计桌面与移动端导航、状态描述以及"网络与连接"控件，提供
  更清晰的分段选项与依赖指引。([#12])
- **应用内嵌导航。** 设置与工具保留在应用外壳内，Android 返回键逐级回退嵌套视图，
  引擎退出时现在会停止 VPN 服务。([#12])
- **任务控制台。** 围绕实时会话摘要以及按房间的路由、连通性与 Windows 局域网控制
  重新设计主页；已连接状态下的修改会先暂存，点击"重新连接"后才会应用。([#13])
- **网络拓扑。** 在房间页新增确定性的路径感知布局、稳定的 emoji 身份标识、实线
  直连路径、虚线转发路径、自适应布局与完整的中继路径。([#13])
- **组网指标与 NAT。** 新增节点数量、中位延迟与丢包、共享的 NAT 类型调色板与
  图例，并在拓扑与列表视图中保持一致的 NAT 呈现。([#13])
- **房间操作栏。** 统一已连接与未连接状态的操作堆栈，新增快速复制链接，保留列表
  视图，并移除重复的房间模式图标。([#13])
- **中转导航。** 将"服务器"更名为"中转"并移至"工具"之前，桌面端行项目可直接编辑
  与切换。([#11], [#13])
- **金丝雀身份。** 金丝雀构建在 Linux、Windows 与 Android 上使用独立的名称、命令、
  包标识、图标与 SemVer 显示。([#14])
- **Enmesh 品牌。** 在受支持的平台间统一应用、小组件、通知、安装器与快速设置的
  品牌呈现。([#14])
- **移动端中转手势。** 在 Android 与 iOS 上支持点按编辑、右滑切换、左滑删除前
  确认。([#11])
- **桌面端中转控制。** 以直接的切换与删除操作取代开关和溢出菜单；点击行项目即可
  编辑。([#11])
- **更新通知。** 更新检查现在使用仓库管理的稳定版与 Beta 元数据，并打开可信的
  GitHub 页面，而不是在应用内下载或安装产物。([#17])
- **专用更新服务。** 构建默认使用专用更新服务器，`UPDATE_API_BASE_URL` 仍作为
  可选的编译期覆盖。([#17])
- **生产更新 API。** 发布标签现在在 GitHub Release 发布后，通过受保护的生产环境
  部署更新服务器。
- **Npcap 指引。** Windows FakeTCP 设置现在链接到官方 Npcap 下载页面。([#17])
- **产物保留期。** 金丝雀产物保留 30 天；生产与已合并 PR 的 main 构建保留
  90 天。([#17])
- **CI 产物下载。** 快照与发布产物现在直接下载，不再额外包装一层 ZIP。([#5])
- **房间凭据模式。** 凭据选项更名为**简单**与**高级**，与网络流量加密无关。([#3])
- **上游变更。**
  - **聚焦的工具页。** 以 NAT 测试、端口白名单与 Windows Magic Wall 工具取代
    "探索"页。([upstream-v2.9.9])
  - **更新镜像。** 新增可选下载镜像与自动镜像测速。([upstream-#226])
  - **Android 小组件。** 改进小组件主题、状态刷新与一键连接控制。
    ([upstream-widgets])
  - **连接前置检查。** 连接尝试现在会先识别缺失的房间、未启用的中转或 Windows
    Npcap 驱动。([upstream-connect-guard])

### 修复

- **更新亮点元数据。** 更新元数据现在从英文与中文更新日志的方括号标题中读取
  发布亮点。
- **Android VPN 就绪。** 仅在用户同意、TUN 创建与描述符交接完成后才显示已连接；
  启动失败与请求断开会清理 VPN 接口与服务。([#15])
- **金丝雀启动画面。** Android 金丝雀构建在解析桌面小组件提供方时不再停留在白色
  启动画面。([#14])
- **磁贴长按。** 长按 Android 快速设置磁贴现在直接打开 Enmesh，而不是系统的
  应用信息界面。([#21])
- **上游修复。**
  - **Android VPN 路由。** 修复已连接节点通告或更改代理子网时的路由刷新。
    ([upstream-#231])
  - **房间成员筛选。** 修复用户与中转成员类型之间的切换。([upstream-#236])
  - **Windows 响应速度。** 修复低帧率与窗口关闭延迟。
    ([upstream-windows-fps], [upstream-window-close])
  - **Linux 软件包版本。** DEB 与 RPM 包现在上报真实版本而非 `1.0.0`，包管理器
    可识别升级。([upstream-#237])
- **Android VPN 诊断。** VPN 接口创建返回空值时，启动过程现在保留原始失败原因与
  关联信息。([#15])
- **Alpha 更新发现。** 当 GitHub 从工作流列表响应中省略拉取请求元数据时，PR
  构建仍可被发现。

### 移除

- **语言目录。** 移除德语、西班牙语、法语、日语、韩语与俄语翻译；界面现支持
  英文与中文。([upstream-v2.9.9])

### 开发者说明

- **分阶段预览版本。** 拉取请求产物使用 alpha 版本，`main` 产物使用 beta 版本，
  签名的 `-rc.N` 标签发布带有独立更新历史元数据的 GitHub 预发布。
- **Vercel Git 部署。** 更新 API 改为通过 Vercel Git 集成部署；移除了 Deploy
  Update API 工作流及其 `Preview`/`Production` GitHub 环境审批。
- **发布流水线拆分。** 共享平台操作显式区分 Android debug/release 模式与统一/
  拆分 APK 布局。
- **发布凭据隔离。** Android 签名密钥限定于受保护的 `Production Signing`
  环境，这也是 CI 使用的唯一 GitHub 环境。
- **EasyTier 依赖。** 锁定发布 `v2.6.4`；Windows 改为单独获取 Npcap SDK，而非
  来自内置的 EasyTier 源码树。([#2])
- **版本来源。** `VERSION` 现在控制生产版本号与构建号；CI 将非发布产物标记为
  金丝雀并校验标签。([#4])
- **分层 CI。** 拉取请求默认运行测试；`platform-*` 标签可选择 Linux、Windows、
  Android 或全部平台产物，main 保留金丝雀产物。([#5], [#6])
- **Flutter 工具链。** 将 Nix 开发与打包更新到 Flutter 3.44 以兼容 Dart 3.12。
  ([nix-flutter-3.44])
- **可复现工具链。** 锁定的 nixpkgs 现在提供本地与 CI 工具，包括 Android SDK
  与 NDK。([#9])
- **Android 构建助手。** 新增 `flutter-android`，在 NixOS 上提供金丝雀默认值与
  隔离的 NDK 构建。
- **更新 API 项目。** 新增独立的 `update-server/` Vercel 项目与编译期
  `UPDATE_API_BASE_URL` 覆盖，用于本地与 CI 构建。([#17])
- **EasyTier 诊断。** 在开发 shell 中加入固定的 EasyTier CLI，用于本地无 TUN 与
  端到端网络排查。

[#2]: https://github.com/ttimasdf/enmesh/pull/2
[#3]: https://github.com/ttimasdf/enmesh/pull/3
[#4]: https://github.com/ttimasdf/enmesh/pull/4
[#5]: https://github.com/ttimasdf/enmesh/pull/5
[#6]: https://github.com/ttimasdf/enmesh/pull/6
[#9]: https://github.com/ttimasdf/enmesh/pull/9
[#10]: https://github.com/ttimasdf/enmesh/pull/10
[#11]: https://github.com/ttimasdf/enmesh/pull/11
[#12]: https://github.com/ttimasdf/enmesh/pull/12
[#13]: https://github.com/ttimasdf/enmesh/pull/13
[#14]: https://github.com/ttimasdf/enmesh/pull/14
[#15]: https://github.com/ttimasdf/enmesh/pull/15
[#17]: https://github.com/ttimasdf/enmesh/pull/17
[#21]: https://github.com/ttimasdf/enmesh/pull/21
[nix-flutter-3.44]: https://github.com/ttimasdf/enmesh/commit/b5969b66ff7e2db6e8517413ccf01b9b2a6720a2
[upstream-#74]: https://github.com/ldoubil/astral/issues/74
[upstream-#226]: https://github.com/ldoubil/astral/issues/226
[upstream-#229]: https://github.com/ldoubil/astral/issues/229
[upstream-#231]: https://github.com/ldoubil/astral/pull/231
[upstream-#236]: https://github.com/ldoubil/astral/issues/236
[upstream-#237]: https://github.com/ldoubil/astral/issues/237
[upstream-auto-retry]: https://github.com/ldoubil/astral/commit/0812b53c3b784cf26b3cad7f1b2791cbc3f6c184
[upstream-connect-guard]: https://github.com/ldoubil/astral/commit/3e30b145f4bc63d2924ee6c6d9b2198604b630f2
[upstream-topology]: https://github.com/ldoubil/astral/commit/4579cd72326e2074f4b14b3aea8c63362f02482c
[upstream-udp-relay]: https://github.com/ldoubil/astral/commit/b27b93e6a1eeffb16fb041ce0578e880be23ec03
[upstream-v2.9.9]: https://github.com/ldoubil/astral/releases/tag/v2.9.9
[upstream-widgets]: https://github.com/ldoubil/astral/commit/b43ad374ca6b40ef481727777a1e05219e53c1e7
[upstream-window-close]: https://github.com/ldoubil/astral/commit/e6f42be69152a24f16cd47fd36cb1a32c394e1d3
[upstream-windows-fps]: https://github.com/ldoubil/astral/commit/eb08c820630e7d14e1611e36e4017e0986fe3ec8
