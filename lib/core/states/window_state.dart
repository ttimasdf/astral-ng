import 'package:signals_flutter/signals_flutter.dart';

enum WindowCloseBehavior { closeToTray, exitProgram }

/// 窗口相关状态
class WindowState {
  // 关闭窗口时默认保留后台进程并隐藏到托盘
  final closeBehavior = signal(WindowCloseBehavior.closeToTray);

  // 状态更新方法
  void setCloseBehavior(WindowCloseBehavior value) {
    closeBehavior.value = value;
  }
}
