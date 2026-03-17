import 'package:astral/core/services/server_connection_manager.dart';
import 'package:astral/core/services/service_manager.dart';
import 'package:astral/core/states/connection_state.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:window_manager/window_manager.dart';
import 'package:tray_manager/tray_manager.dart';

class WindowControls extends StatefulWidget {
  const WindowControls({super.key});

  @override
  State<WindowControls> createState() => _WindowControlsState();
}

class _WindowControlsState extends State<WindowControls>
    with TrayListener, WindowListener {
  bool _isMaximized = false;
  final TrayManager trayManager = TrayManager.instance;
  EffectCleanup? _connectionStateCleanup;

  @override
  void initState() {
    trayManager.addListener(this);
    windowManager.addListener(this);
    _updateMaximizedStatus();
    // 桌面平台代码
    _initTray();
    _connectionStateCleanup = effect(() {
      ServiceManager().connectionState.connectionState.value;
      _updateTrayMenu();
    });
    super.initState();
  }

  Future<void> _initTray() async {
    if (Platform.isWindows) {
      await trayManager.setIcon('assets/icon.ico');
    } else if (Platform.isMacOS) {
      await trayManager.setIcon('assets/logo.png');
    } else {
      await trayManager.setIcon('assets/icon_tray.png');
    }

    if (!Platform.isLinux) {
      await trayManager.setToolTip('Astral-ng');
    }

    await _updateTrayMenu();
  }

  Future<void> _updateTrayMenu() async {
    final state =
        ServiceManager().connectionState.connectionState.value;
    final isConnected = state == CoState.connected;
    final isConnecting = state == CoState.connecting;

    String connectLabel;
    if (isConnecting) {
      connectLabel = '连接中...';
    } else if (isConnected) {
      connectLabel = '断开连接';
    } else {
      connectLabel = '连接';
    }

    final Menu trayMenu = Menu(
      items: [
        MenuItem(key: 'show_window', label: '显示主界面'),
        MenuItem.separator(),
        MenuItem(
          key: 'toggle_connection',
          label: connectLabel,
          disabled: isConnecting,
        ),
        MenuItem.separator(),
        MenuItem(key: 'exit', label: '退出'),
      ],
    );

    await trayManager.setContextMenu(trayMenu);
  }

  @override
  void onTrayIconRightMouseDown() {
    trayManager.popUpContextMenu();
  }

  @override
  void onTrayIconMouseDown() {
    windowManager.show();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    switch (menuItem.key) {
      case 'show_window':
        windowManager.show();
      case 'toggle_connection':
        final state =
            ServiceManager().connectionState.connectionState.value;
        if (state == CoState.idle) {
          ServerConnectionManager.instance.connect();
        } else if (state == CoState.connected) {
          ServerConnectionManager.instance.disconnect();
        }
      case 'exit':
        exit(0);
    }
  }

  @override
  void dispose() {
    _connectionStateCleanup?.call();
    trayManager.removeListener(this);
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  void onWindowMaximize() {
    setState(() => _isMaximized = true);
  }

  @override
  void onWindowUnmaximize() {
    setState(() => _isMaximized = false);
  }

  Future<void> _updateMaximizedStatus() async {
    final maximized = await windowManager.isMaximized();
    setState(() => _isMaximized = maximized);
  }

  @override
  Widget build(BuildContext context) {
    if (!Platform.isWindows && !Platform.isMacOS && !Platform.isLinux) {
      return const SizedBox.shrink();
    }

    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.remove),
          onPressed: () async {
            
              print('Minimize button was pressed!');
            await windowManager.minimize();
            
          },
          tooltip: '最小化',
          iconSize: 20,
        ),
        IconButton(
          icon: Icon(_isMaximized ? Icons.filter_none : Icons.crop_square),
          onPressed: () async {
            if (_isMaximized) {
              await windowManager.unmaximize();
            } else {
              await windowManager.maximize();
            }
          },
          tooltip: _isMaximized ? '还原' : '最大化',
          iconSize: 20,
        ),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () async {
            if (ServiceManager().windowState.closeMinimize.value) {
              await windowManager.hide();
            } else {
              await windowManager.close();
            }
          },
          tooltip: '关闭',
          iconSize: 20,
        ),
      ],
    );
  }
}
