import 'package:enmesh/core/ui/main_tab.dart';
import 'package:flutter/widgets.dart' show BuildContext, View;
import 'package:signals_flutter/signals_flutter.dart';

/// UI状态（纯Signal，临时状态，不需要持久化）
class UIState {
  final isDesktop = signal(false);
  final selectedIndex = signal(0);
  final hoveredIndex = signal<int?>(null);
  final isInBackground = signal(false);
  final trayHidden = signal(false);

  void goTo(MainTab tab) {
    selectedIndex.value = tab.index;
  }

  void updateScreenSplitWidth(double width) {
    isDesktop.value = width > 480;
  }

  /// Current window width in logical pixels, read from the widget's view.
  ///
  /// Use this instead of `MediaQuery.of(context)` inside
  /// [WidgetsBindingObserver.didChangeMetrics]: metrics callbacks fire before
  /// the widget tree rebuilds, so MediaQuery still reports the previous
  /// orientation's size. Caching that stale width left phones stuck in the
  /// desktop sidebar layout after a landscape round trip (issue #22).
  static double windowWidthOf(BuildContext context) {
    final view = View.of(context);
    return view.physicalSize.width / view.devicePixelRatio;
  }

  void setBackground(bool value) {
    isInBackground.value = value;
  }

  void setTrayHidden(bool value) {
    trayHidden.value = value;
  }
}
