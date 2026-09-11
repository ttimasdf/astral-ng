import 'package:enmesh/core/states/ui_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('updateScreenSplitWidth', () {
    test('portrait phone width stays compact', () {
      final uiState = UIState();
      uiState.updateScreenSplitWidth(411.4);
      expect(uiState.isDesktop.value, isFalse);
    });

    test('exactly 480 dp stays compact', () {
      final uiState = UIState();
      uiState.updateScreenSplitWidth(480);
      expect(uiState.isDesktop.value, isFalse);
    });

    test('landscape phone width switches to desktop layout', () {
      final uiState = UIState();
      uiState.updateScreenSplitWidth(914.3);
      expect(uiState.isDesktop.value, isTrue);
    });
  });

  testWidgets(
    'windowWidthOf sees the new orientation inside didChangeMetrics while MediaQuery is stale',
    (tester) async {
      double? mediaQueryWidthInCallback;
      double? viewWidthInCallback;
      final uiState = UIState();

      // Mirrors the MainScreen metrics pattern: an observer reading both width
      // sources from didChangeMetrics, exactly where the stale-width
      // regression of issue #22 used to cache the previous orientation into
      // the isDesktop signal.
      await tester.pumpWidget(
        MaterialApp(
          home: _MetricsProbe(
            onMetrics: (mediaQueryWidth, viewWidth) {
              mediaQueryWidthInCallback = mediaQueryWidth;
              viewWidthInCallback = viewWidth;
              uiState.updateScreenSplitWidth(viewWidth);
            },
          ),
        ),
      );

      // Rotate the test view to landscape the way the engine does: update the
      // view metrics first, then notify observers before the tree rebuilds.
      tester.view.physicalSize = const Size(3200, 1440);
      tester.view.devicePixelRatio = 3.5;

      expect(
        mediaQueryWidthInCallback,
        closeTo(800, 0.01),
        reason:
            'MediaQuery.of inside didChangeMetrics still reports the '
            'previous orientation; it must not feed the isDesktop signal',
      );
      expect(
        viewWidthInCallback,
        closeTo(3200 / 3.5, 0.01),
        reason:
            'windowWidthOf must report the fresh landscape width so the '
            'layout signal flips immediately',
      );
      expect(uiState.isDesktop.value, isTrue);

      // Rotate back to portrait and verify the same callback path switches the
      // layout state back instead of leaving the desktop layout cached.
      tester.view.physicalSize = const Size(1440, 3200);
      await tester.pump();
      expect(uiState.isDesktop.value, isFalse);
      expect(viewWidthInCallback, closeTo(1440 / 3.5, 0.01));

      await tester.pump();
      addTearDown(tester.view.reset);
    },
  );
}

class _MetricsProbe extends StatefulWidget {
  const _MetricsProbe({required this.onMetrics});

  final void Function(double mediaQueryWidth, double viewWidth) onMetrics;

  @override
  State<_MetricsProbe> createState() => _MetricsProbeState();
}

class _MetricsProbeState extends State<_MetricsProbe>
    with WidgetsBindingObserver {
  BuildContext? _probeContext;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    final context = _probeContext;
    if (context == null || !context.mounted) return;
    widget.onMetrics(
      MediaQuery.of(context).size.width,
      UIState.windowWidthOf(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    _probeContext = context;
    return const SizedBox.shrink();
  }
}
