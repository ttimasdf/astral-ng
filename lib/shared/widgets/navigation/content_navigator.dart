import 'package:flutter/material.dart';

/// Keeps a destination's route stack inside the main application shell.
class ContentNavigator extends StatefulWidget {
  final GlobalKey<NavigatorState> navigatorKey;
  final Widget rootPage;
  final bool active;

  const ContentNavigator({
    super.key,
    required this.navigatorKey,
    required this.rootPage,
    required this.active,
  });

  @override
  State<ContentNavigator> createState() => _ContentNavigatorState();
}

class _ContentNavigatorState extends State<ContentNavigator> {
  late final _RouteDepthObserver _routeObserver;
  int _routeDepth = 1;

  @override
  void initState() {
    super.initState();
    _routeObserver = _RouteDepthObserver((depth) {
      if (!mounted || depth == _routeDepth) return;
      setState(() => _routeDepth = depth);
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<Object?>(
      canPop: !widget.active || _routeDepth <= 1,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop || !widget.active || _routeDepth <= 1) return;
        widget.navigatorKey.currentState?.pop(result);
      },
      child: Navigator(
        key: widget.navigatorKey,
        observers: [_routeObserver],
        onGenerateRoute:
            (settings) => MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => widget.rootPage,
            ),
      ),
    );
  }
}

class _RouteDepthObserver extends NavigatorObserver {
  final ValueChanged<int> onDepthChanged;
  int _depth = 1;

  _RouteDepthObserver(this.onDepthChanged);

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    if (previousRoute == null) return;
    _depth += 1;
    onDepthChanged(_depth);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    _decrementDepth();
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);
    _decrementDepth();
  }

  void _decrementDepth() {
    if (_depth <= 1) return;
    _depth -= 1;
    onDepthChanged(_depth);
  }
}
