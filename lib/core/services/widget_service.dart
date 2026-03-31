import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:signals_flutter/signals_flutter.dart';

/// Widget service for Android home screen widgets
class WidgetService {
  static WidgetService? _instance;

  final _isInitialized = signal(false);

  bool get isInitialized => _isInitialized.value;

  WidgetService._();

  static WidgetService get instance {
    _instance ??= WidgetService._();
    return _instance!;
  }

  /// Initialize the widget service
  Future<void> initialize() async {
    if (!Platform.isAndroid) {
      return;
    }

    try {
      // Set app group ID for Android (used for shared preferences)
      await HomeWidget.setAppGroupId('com.kevin.astral');

      // Register callback for widget updates
      HomeWidget.widgetClicked.listen(_handleWidgetClick);

      _isInitialized.value = true;
    } catch (e) {
      debugPrint('WidgetService initialization failed: $e');
    }
  }

  /// Handle widget click
  void _handleWidgetClick(Uri? uri) {
    // Widget clicks will launch the app
    // The actual connection toggle should be handled by the app when it opens
    debugPrint('Widget clicked');
  }

  /// Update widget with current connection status
  Future<void> updateConnectionStatus({
    required bool isConnected,
    required String ipAddress,
    required String duration,
    String? serverName,
    int peerCount = 0,
  }) async {
    if (!Platform.isAndroid || !_isInitialized.value) {
      return;
    }

    try {
      await HomeWidget.saveWidgetData<bool>('is_connected', isConnected);
      await HomeWidget.saveWidgetData<String>('ip_address', ipAddress);
      await HomeWidget.saveWidgetData<String>('duration', duration);

      if (serverName != null) {
        await HomeWidget.saveWidgetData<String>('server_name', serverName);
      }
      await HomeWidget.saveWidgetData<int>('peer_count', peerCount);

      // Trigger widget update
      await HomeWidget.updateWidget(
        name: 'AstralWidgetProvider',
        androidName: 'AstralWidgetProvider',
        iOSName: 'AstralWidget',
      );
    } catch (e) {
      debugPrint('Failed to update widget: $e');
    }
  }

  /// Clear widget data (disconnected state)
  Future<void> clearWidgetData() async {
    if (!Platform.isAndroid || !_isInitialized.value) {
      return;
    }

    try {
      await HomeWidget.saveWidgetData<bool>('is_connected', false);
      await HomeWidget.saveWidgetData<String>('ip_address', 'No IP');
      await HomeWidget.saveWidgetData<String>('duration', '00:00');
      await HomeWidget.saveWidgetData<String>('server_name', 'No Server');
      await HomeWidget.saveWidgetData<int>('peer_count', 0);

      // Trigger widget update
      await HomeWidget.updateWidget(
        name: 'AstralWidgetProvider',
        androidName: 'AstralWidgetProvider',
        iOSName: 'AstralWidget',
      );
    } catch (e) {
      debugPrint('Failed to clear widget data: $e');
    }
  }
}
