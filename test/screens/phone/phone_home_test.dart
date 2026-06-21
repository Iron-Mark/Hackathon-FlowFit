import 'dart:async';

import 'package:flowfit/models/tracked_data.dart';
import 'package:flowfit/models/sensor_status.dart';
import 'package:flowfit/screens/phone_home.dart';
import 'package:flowfit/services/database_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const phoneDataChannel = MethodChannel('com.flowfit.phone/data');
  const heartRateEventChannel = EventChannel('com.flowfit.phone/heartrate');
  late InMemoryHeartRateDataStore dataStore;

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    dataStore = InMemoryHeartRateDataStore();
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

    await tester.pumpWidget(
      MaterialApp(home: PhoneHomePage(dataStore: dataStore)),
    );
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

  testWidgets('retry ignores duplicate listener starts while pending', (
    tester,
  ) async {
    var startCalls = 0;
    final retryCompleter = Completer<bool>();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(phoneDataChannel, (call) async {
          if (call.method == 'startListening') {
            startCalls += 1;
            if (startCalls == 1) return false;
            if (startCalls == 2) return retryCompleter.future;
            return true;
          }
          return null;
        });

    await tester.pumpWidget(
      MaterialApp(home: PhoneHomePage(dataStore: dataStore)),
    );
    await tester.pumpAndSettle();

    final retryButton = tester.widget<TextButton>(
      find.widgetWithText(TextButton, 'Retry'),
    );
    final onPressed = retryButton.onPressed!;

    onPressed();
    onPressed();
    await tester.pump();

    expect(startCalls, 2);
    expect(find.text('Starting watch listener...'), findsOneWidget);

    retryCompleter.complete(true);
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
        home: PhoneHomePage(dataStore: dataStore),
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

    await tester.pumpWidget(
      MaterialApp(home: PhoneHomePage(dataStore: dataStore)),
    );
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

    await tester.pumpWidget(
      MaterialApp(home: PhoneHomePage(dataStore: dataStore)),
    );
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

  testWidgets('pull to refresh reloads persisted heart rate history', (
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
      MaterialApp(home: PhoneHomePage(dataStore: dataStore)),
    );
    await tester.pumpAndSettle();

    await dataStore.insertHeartRateDataBatch([
      TrackedData(
        hr: 77,
        ibiValues: const [780, 790],
        hrv: 10,
        spo2: 98,
        timestamp: DateTime.utc(2026, 1, 1, 12),
        status: SensorStatus.active,
      ),
    ]);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, 500));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('77 BPM'),
      300,
      scrollable: find.byType(Scrollable),
    );

    expect(find.text('77 BPM'), findsOneWidget);
    expect(find.text('1 readings'), findsOneWidget);
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

      await tester.pumpWidget(
        MaterialApp(home: PhoneHomePage(dataStore: dataStore)),
      );
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

  testWidgets('clear action ignores duplicate confirmation requests', (
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
      MaterialApp(home: PhoneHomePage(dataStore: dataStore)),
    );
    await tester.pumpAndSettle();

    final clearButton = tester.widget<FloatingActionButton>(
      find.widgetWithText(FloatingActionButton, 'Clear'),
    );
    final onPressed = clearButton.onPressed!;

    onPressed();
    onPressed();
    await tester.pumpAndSettle();

    expect(find.text('Clear All Data'), findsOneWidget);
    expect(
      tester
          .widget<FloatingActionButton>(
            find.widgetWithText(FloatingActionButton, 'Clear'),
          )
          .onPressed,
      isNull,
    );

    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Clear All Data'), findsNothing);
    expect(find.text('Waiting'), findsOneWidget);
  });

  testWidgets('confirmed clear removes received watch data from dashboard', (
    tester,
  ) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(phoneDataChannel, (call) async {
          if (call.method == 'startListening') {
            return true;
          }
          return null;
        });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockStreamHandler(
          heartRateEventChannel,
          MockStreamHandler.inline(
            onListen: (arguments, events) {
              events.success({
                'bpm': 84,
                'timestamp': DateTime.now().millisecondsSinceEpoch,
                'status': 'active',
                'ibiValues': [720, 730, 725],
              });
            },
          ),
        );

    await tester.pumpWidget(
      MaterialApp(home: PhoneHomePage(dataStore: dataStore)),
    );
    await tester.pumpAndSettle();

    expect(find.text('84'), findsWidgets);
    expect(find.text('BPM'), findsOneWidget);
    expect(find.widgetWithText(FloatingActionButton, 'Save 1'), findsOneWidget);

    await tester.tap(find.widgetWithText(FloatingActionButton, 'Clear'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Clear'));
    await tester.pumpAndSettle();

    expect(find.text('Clear All Data'), findsNothing);
    expect(find.text('No data yet'), findsOneWidget);
    expect(find.text('Cleared all data'), findsOneWidget);
    expect(find.widgetWithText(FloatingActionButton, 'Save 1'), findsNothing);
  });

  testWidgets('save action flushes pending watch data to local store', (
    tester,
  ) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(phoneDataChannel, (call) async {
          if (call.method == 'startListening') {
            return true;
          }
          return null;
        });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockStreamHandler(
          heartRateEventChannel,
          MockStreamHandler.inline(
            onListen: (arguments, events) {
              events.success({
                'bpm': 91,
                'timestamp': DateTime.now().millisecondsSinceEpoch,
                'status': 'active',
                'ibiValues': [650, 660, 655],
              });
            },
          ),
        );

    await tester.pumpWidget(
      MaterialApp(home: PhoneHomePage(dataStore: dataStore)),
    );
    await tester.pumpAndSettle();

    expect(find.widgetWithText(FloatingActionButton, 'Save 1'), findsOneWidget);
    expect(await dataStore.getRecentHeartRateData(), isEmpty);

    await tester.tap(find.widgetWithText(FloatingActionButton, 'Save 1'));
    await tester.pumpAndSettle();

    final saved = await dataStore.getRecentHeartRateData();
    expect(saved, hasLength(1));
    expect(saved.single.hr, 91);
    expect(find.widgetWithText(FloatingActionButton, 'Save 1'), findsNothing);
    expect(find.text('Flushed 1 records to database'), findsOneWidget);
  });
}
