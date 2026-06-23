import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flowfit/screens/wear/wear_heart_rate_screen.dart';
import 'package:wear_plus/wear_plus.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const watchDataChannel = MethodChannel('com.flowfit.watch/data');
  const watchSyncChannel = MethodChannel('com.flowfit.watch/sync');
  const transmissionEventChannel = EventChannel(
    'com.flowfit.watch/transmission',
  );

  var connectWatchCalls = 0;

  setUp(() {
    connectWatchCalls = 0;

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(watchDataChannel, (call) async {
          switch (call.method) {
            case 'checkPermission':
              return 'granted';
            case 'connectWatch':
              connectWatchCalls += 1;
              throw PlatformException(
                code: 'SERVICE_UNAVAILABLE',
                message: 'Samsung Health service unavailable',
                details: 'com.samsung.android.service.health',
              );
            case 'requestPermission':
            case 'isWatchConnected':
              return true;
            case 'stopHeartRate':
            case 'disconnectWatch':
              return null;
            default:
              return null;
          }
        });

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(watchSyncChannel, (call) async {
          switch (call.method) {
            case 'checkPhoneConnection':
              return false;
            case 'sendHeartRateToPhone':
              fail('Simulated heart-rate data should not be sent to phone');
            default:
              return null;
          }
        });

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockStreamHandler(
          transmissionEventChannel,
          MockStreamHandler.inline(onListen: (_, __) {}),
        );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(watchDataChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(watchSyncChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockStreamHandler(transmissionEventChannel, null);
  });

  testWidgets(
    'uses simulated BPM in debug when Samsung Health service is unavailable',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: WearHeartRateScreen(
            shape: WearShape.round,
            mode: WearMode.active,
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(
        find.textContaining('Samsung Health service unavailable'),
        findsAtLeastNWidgets(1),
      );
      expect(find.text('Start'), findsOneWidget);
      expect(connectWatchCalls, 1);

      await tester.tap(find.widgetWithText(ElevatedButton, 'Start'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(seconds: 1));

      expect(connectWatchCalls, 1);
      expect(find.text('Simulated'), findsOneWidget);
      expect(find.text('Sim'), findsOneWidget);
      expect(find.text('--'), findsNothing);
      expect(find.text('Send'), findsNothing);

      await tester.tap(find.widgetWithText(ElevatedButton, 'Stop'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Stopped'), findsOneWidget);
      expect(find.text('Start'), findsOneWidget);
      expect(
        find.textContaining('Samsung Health service unavailable'),
        findsAtLeastNWidgets(1),
      );
      expect(find.text('Send'), findsNothing);
    },
  );
}
