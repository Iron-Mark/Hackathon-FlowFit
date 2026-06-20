import 'package:flowfit/screens/phone_home.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const phoneDataChannel = MethodChannel('com.flowfit.phone/data');
  const heartRateEventChannel = EventChannel('com.flowfit.phone/heartrate');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockStreamHandler(
          heartRateEventChannel,
          MockStreamHandler.inline(onListen: (arguments, events) {}),
        );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(phoneDataChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockStreamHandler(heartRateEventChannel, null);
  });

  testWidgets('shows retry when dashboard listener startup fails', (
    tester,
  ) async {
    var startCalls = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(phoneDataChannel, (call) async {
          if (call.method == 'startListening') {
            startCalls += 1;
            return startCalls > 1;
          }
          return null;
        });

    await tester.pumpWidget(const MaterialApp(home: PhoneHomePage()));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Could not start watch listener. Check Bluetooth and Wear OS connection, then retry.',
      ),
      findsOneWidget,
    );
    expect(find.widgetWithText(TextButton, 'Retry'), findsOneWidget);

    final retryButton = find.widgetWithText(TextButton, 'Retry');
    await tester.ensureVisible(retryButton);
    await tester.pumpAndSettle();
    await tester.tap(retryButton);
    await tester.pumpAndSettle();

    expect(startCalls, 2);
    expect(find.text('Listening for watch data...'), findsOneWidget);
  });

  testWidgets('sensor data action opens the phone heart rate route', (
    tester,
  ) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(phoneDataChannel, (call) async {
          if (call.method == 'startListening') {
            return true;
          }
          return null;
        });

    await tester.pumpWidget(
      MaterialApp(
        home: const PhoneHomePage(),
        routes: {
          '/phone_heart_rate': (_) =>
              const Scaffold(body: Text('route:phone-heart-rate')),
        },
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Sensor Data (Test Mode)'));
    await tester.pumpAndSettle();

    expect(find.text('route:phone-heart-rate'), findsOneWidget);
  });

  testWidgets('watch status action reports disconnected state', (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(phoneDataChannel, (call) async {
          if (call.method == 'startListening') {
            return true;
          }
          return null;
        });

    await tester.pumpWidget(const MaterialApp(home: PhoneHomePage()));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.watch_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Watch not connected'), findsOneWidget);
  });

  testWidgets('watch stream error shows retry action on dashboard', (
    tester,
  ) async {
    var startCalls = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(phoneDataChannel, (call) async {
          if (call.method == 'startListening') {
            startCalls += 1;
            return true;
          }
          return null;
        });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockStreamHandler(
          heartRateEventChannel,
          MockStreamHandler.inline(
            onListen: (arguments, events) {
              events.error(
                code: 'WATCH_STREAM_ERROR',
                message: 'Heart rate stream disconnected',
              );
            },
          ),
        );

    await tester.pumpWidget(const MaterialApp(home: PhoneHomePage()));
    await tester.pumpAndSettle();

    expect(startCalls, 1);
    expect(
      find.text(
        'Watch data stream stopped. Check Bluetooth and Wear OS connection, then retry.',
      ),
      findsOneWidget,
    );
    expect(find.widgetWithText(TextButton, 'Retry'), findsOneWidget);
  });

  testWidgets(
    'clear action can be cancelled without clearing dashboard state',
    (tester) async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(phoneDataChannel, (call) async {
            if (call.method == 'startListening') {
              return true;
            }
            return null;
          });

      await tester.pumpWidget(const MaterialApp(home: PhoneHomePage()));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FloatingActionButton, 'Clear'));
      await tester.pumpAndSettle();

      expect(find.text('Clear All Data'), findsOneWidget);

      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Clear All Data'), findsNothing);
      expect(find.text('Waiting'), findsOneWidget);
    },
  );
}
