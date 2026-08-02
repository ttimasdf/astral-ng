import 'package:astral/core/constants/home_widget_keys.dart';
import 'package:astral/core/services/widget_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('home_widget');
  final calls = <MethodCall>[];

  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return true;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test(
    'updates widgets with Kotlin-namespace-qualified provider names',
    () async {
      await WidgetService.instance.updateHomeWidgets();

      expect(calls.map((call) => call.method), everyElement('updateWidget'));
      expect(
        calls.map(
          (call) =>
              (call.arguments as Map<Object?, Object?>)['qualifiedAndroidName'],
        ),
        [
          HomeWidgetKeys.widgetSmall,
          HomeWidgetKeys.widgetMedium,
          HomeWidgetKeys.widgetLarge,
        ],
      );
      expect(
        calls.map(
          (call) => (call.arguments as Map<Object?, Object?>)['android'],
        ),
        everyElement(isNull),
      );
    },
  );
}
