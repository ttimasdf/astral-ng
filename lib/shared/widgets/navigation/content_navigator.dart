import 'package:flutter/material.dart';

/// Keeps a destination's route stack inside the main application shell.
class ContentNavigator extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return NavigatorPopHandler<Object?>(
      enabled: active,
      onPopWithResult: (result) {
        navigatorKey.currentState?.pop(result);
      },
      child: Navigator(
        key: navigatorKey,
        onGenerateRoute:
            (settings) => MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => rootPage,
            ),
      ),
    );
  }
}
