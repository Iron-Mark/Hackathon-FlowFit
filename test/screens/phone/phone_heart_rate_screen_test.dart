import 'package:flowfit/screens/phone/phone_heart_rate_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const phoneDataChannel = MethodChannel('com.flowfit.phone/data');
  const heartRateEventChannel = EventChannel('com.flowfit.phone/heartrate');
  const sensorEventChannel = EventChannel('com.flowfit.phone/sensor_data');

  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: PhoneHeartRateScreen()));
    await tester.pumpAndSettle();
  }

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockStreamHandler(
          heartRateEventChannel,
          MockStreamHandler.inline(onListen: (arguments, events) {}),
        );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockStreamHandler(
          sensorEventChannel,
          MockStreamHandler.inline(onListen: (arguments, events) {}),
        );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(phoneDataChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockStreamHandler(heartRateEventChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockStreamHandler(sensorEventChannel, null);
  });

  testWidgets('starts listening when opened from Heart Check', (tester) async {
    var startCalls = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(phoneDataChannel, (call) async {
          if (call.method == 'startListening') {
            startCalls += 1;
            return true;
          }
          return null;
        });

    await pumpScreen(tester);

    expect(startCalls, 1);
    expect(find.text('Listening for watch data'), findsOneWidget);
    expect(
      find.text('Start heart rate tracking on your watch'),
      findsOneWidget,
    );
    expect(find.text('Retry'), findsNothing);
  });

  testWidgets('shows retry when phone watch listener cannot start', (
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

    await pumpScreen(tester);

    expect(find.text('Watch listener is not active'), findsOneWidget);
    expect(
      find.text(
        'Could not start phone watch listener. Check Bluetooth and Wear OS connection, then retry.',
      ),
      findsOneWidget,
    );
    expect(find.text('Retry'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(startCalls, 2);
    expect(find.text('Listening for watch data'), findsOneWidget);
    expect(find.text('Retry'), findsNothing);
  });

  testWidgets('shows retry when watch heart rate stream fails', (tester) async {
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

    await pumpScreen(tester);

    expect(startCalls, 1);
    expect(find.text('Watch listener is not active'), findsOneWidget);
    expect(
      find.text(
        'Watch data stream stopped. Check Bluetooth and Wear OS connection, then retry.',
      ),
      findsOneWidget,
    );
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('retry after watch stream failure restarts listener', (
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

    await pumpScreen(tester);

    expect(startCalls, 1);
    expect(find.text('Watch listener is not active'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(startCalls, 2);
    expect(find.text('Listening for watch data'), findsOneWidget);
    expect(find.text('Retry'), findsNothing);
  });

  testWidgets(
    'test mode shows sensor batch data before heart readings arrive',
    (tester) async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(phoneDataChannel, (call) async {
            if (call.method == 'startListening') {
              return true;
            }
            return null;
          });
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockStreamHandler(
            sensorEventChannel,
            MockStreamHandler.inline(
              onListen: (arguments, events) {
                events.success({
                  'type': 'sensor_batch',
                  'timestamp': DateTime.now().millisecondsSinceEpoch,
                  'bpm': 91,
                  'sample_rate': 32,
                  'count': 2,
                  'accelerometer': [
                    [0.1, 0.2, 9.8],
                    [0.2, 0.3, 9.7],
                  ],
                });
              },
            ),
          );

      await pumpScreen(tester);

      await tester.tap(find.byTooltip('Test Mode'));
      await tester.pump();

      expect(find.text('Test Mode - Sensor Batch Data'), findsOneWidget);
      expect(find.text('Sample Count'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('Heart Rate'), findsOneWidget);
      expect(find.text('91 bpm'), findsOneWidget);
    },
  );
}
