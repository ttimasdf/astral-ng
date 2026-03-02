# Astral-ng

[English](README_en.md) | 中文

> 本项目基于 [ldoubil](https://github.com/ldoubil) 的原始工作开发。感谢原作者的开创性贡献，为本项目奠定了坚实的基础。

Astral-ng 是一个跨平台的 P2P 组网与 VPN 应用，基于 [EasyTier](https://github.com/EasyTier/EasyTier) 构建，使用 Flutter（前端）和 Rust（后端）开发。

## 功能特性

- P2P 点对点组网连接
- VPN 服务
- 跨平台支持：Windows、macOS、Linux、Android、iOS
- 多语言支持（中文、英文、日文、韩文、法文、德文、西班牙文、俄文）

## 使用场景

- 异地设备组建虚拟局域网，实现远程访问家庭/办公网络
- 多人联机游戏组网（无需公网 IP 或端口转发）
- 远程开发与调试，安全访问内网服务
- 跨平台设备间文件共享与协作

## 开发环境

### 使用 Nix（推荐）

```bash
nix develop
```

### 手动配置

依赖项：
- Flutter SDK 3.7+
- Rust（beta channel）
- protobuf 编译器
- 平台特定依赖（Linux 需要 webkitgtk 和 libayatana-appindicator）

## 构建与运行

```bash
# 安装依赖
flutter pub get

# 代码生成
dart run build_runner build --delete-conflicting-outputs

# 运行（桌面端）
flutter run -d linux    # 或 windows, macos

# 运行（移动端）
flutter run -d android
flutter run -d ios

# 生产构建
flutter build linux
flutter build windows
flutter build apk --split-per-abi
flutter build ios
```

### Rust 后端

```bash
cd rust
cargo build
cargo test
```

## 技术栈

- 前端：Flutter + signals_flutter（状态管理）+ Isar（本地数据库）
- 后端：Rust + EasyTier
- 桥接：flutter_rust_bridge

## 许可证

[GPLv3](LICENSE)
