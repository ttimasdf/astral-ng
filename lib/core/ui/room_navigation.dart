import 'dart:async';

import 'package:enmesh/core/diagnostics/diagnostic_modules.dart';
import 'package:enmesh/core/diagnostics/diagnostics_runtime.dart';
import 'package:enmesh/core/models/room.dart';
import 'package:enmesh/core/services/service_manager.dart';
import 'package:enmesh/core/ui/app_snack_bars.dart';
import 'package:enmesh/core/ui/main_tab.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// 跳转到房间页并选中房间（core 唯一入口）
class RoomNavigation {
  static Future<void> goToRoom(Room room, {BuildContext? context}) async {
    try {
      ServiceManager().uiState.goTo(MainTab.room);

      final completer = Completer<void>();
      SchedulerBinding.instance.addPostFrameCallback((_) async {
        try {
          await ServiceManager().room.setRoom(room);
          completer.complete();
        } catch (e, st) {
          completer.completeError(e, st);
        }
      });
      await completer.future;
    } catch (e, stack) {
      Diagnostics.logger(DiagnosticModules.appLinks).warning(
        'room-navigation.failed',
        'Failed to navigate to a room',
        error: e,
        stackTrace: stack,
      );
      if (context != null && context.mounted) {
        AppSnackBars.error(context, '跳转失败', '无法跳转到房间页面: $e');
      }
    }
  }
}
