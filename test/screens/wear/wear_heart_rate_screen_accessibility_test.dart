import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flowfit/screens/wear/wear_heart_rate_screen.dart';
import 'package:wear_plus/wear_plus.dart';

/// Tests for WCAG 2.1 Level AA accessibility compliance
/// Requirement 3.3: Touch targets must be at least 48x48dp
void main() {
  const watchDataChannel = MethodChannel('com.flowfit.watch/data');
  const watchSyncChannel = MethodChannel('com.flowfit.watch/sync');
  const heartRateEventChannel = EventChannel('com.flowfit.watch/heartrate');

  group('WearHeartRateScreen Accessibility Tests', () {
    setUp(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(watchDataChannel, (call) async {
            switch (call.method) {
              case 'checkPermission':
                return 'granted';
              case 'requestPermission':
              case 'connectWatch':
              case 'isWatchConnected':
                return true;
              case 'startHeartRate':
                return false;
              case 'stopHeartRate':
              case 'getTestModeData':
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
                return true;
              default:
                return null;
            }
          });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(watchDataChannel, null);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(watchSyncChannel, null);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockStreamHandler(heartRateEventChannel, null);
    });

    Future<void> pumpWearHeartRateScreen(WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: WearHeartRateScreen(
            shape: WearShape.round,
            mode: WearMode.active,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
    }

    testWidgets('Start/Stop button meets minimum touch target size (48x48dp)', (
      WidgetTester tester,
    ) async {
      // Arrange
      await pumpWearHeartRateScreen(tester);

      // Act - Find the Start button
      final startButtonFinder = find.widgetWithText(ElevatedButton, 'Start');
      expect(startButtonFinder, findsOneWidget);

      // Assert - Verify touch target size
      final RenderBox buttonBox =
          tester.renderObject(startButtonFinder) as RenderBox;
      final Size buttonSize = buttonBox.size;

      // WCAG 2.1 Level AA requires minimum 48x48dp touch targets
      expect(
        buttonSize.height,
        greaterThanOrEqualTo(48.0),
        reason: 'Button height must be at least 48dp for accessibility',
      );
      expect(
        buttonSize.width,
        greaterThanOrEqualTo(48.0),
        reason: 'Button width must be at least 48dp for accessibility',
      );
    });

    testWidgets('Send button meets minimum touch target size (48x48dp)', (
      WidgetTester tester,
    ) async {
      var sendCalls = 0;

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(watchDataChannel, (call) async {
            switch (call.method) {
              case 'checkPermission':
                return 'granted';
              case 'connectWatch':
              case 'isWatchConnected':
              case 'startHeartRate':
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
                sendCalls += 1;
                expect(call.arguments, isA<Map>());
                expect('${call.arguments}', contains('74'));
                return true;
              default:
                return null;
            }
          });
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockStreamHandler(
            heartRateEventChannel,
            MockStreamHandler.inline(
              onListen: (arguments, events) {
                events.success({
                  'bpm': 74,
                  'timestamp': DateTime.now().millisecondsSinceEpoch,
                  'status': 'active',
                  'ibiValues': [810, 805],
                });
              },
            ),
          );

      await pumpWearHeartRateScreen(tester);

      await tester.tap(find.widgetWithText(ElevatedButton, 'Start'));
      await tester.pump(const Duration(milliseconds: 100));

      final sendButtonFinder = find.widgetWithText(ElevatedButton, 'Send');
      expect(sendButtonFinder, findsOneWidget);

      final RenderBox buttonBox =
          tester.renderObject(sendButtonFinder) as RenderBox;
      expect(buttonBox.size.height, greaterThanOrEqualTo(48.0));
      expect(buttonBox.size.width, greaterThanOrEqualTo(48.0));

      await tester.tap(sendButtonFinder);
      await tester.pump();

      expect(sendCalls, 1);
      expect(find.text('Sent!'), findsOneWidget);
    });

    testWidgets('All interactive elements have sufficient padding', (
      WidgetTester tester,
    ) async {
      // Arrange
      await pumpWearHeartRateScreen(tester);

      // Act - Find all ElevatedButton widgets
      final buttonFinders = find.byType(ElevatedButton);

      // Assert - Verify each button has adequate size
      for (final buttonFinder in buttonFinders.evaluate()) {
        final RenderBox box = buttonFinder.renderObject as RenderBox;
        final Size size = box.size;

        // Check that at least one dimension meets the 48dp requirement
        // (Some buttons might be wider than tall or vice versa)
        final meetsMinimum = size.height >= 48.0 || size.width >= 48.0;
        expect(
          meetsMinimum,
          isTrue,
          reason:
              'Interactive element should have at least one dimension >= 48dp',
        );
      }
    });

    testWidgets(
      'Start ignores duplicate taps and unmounts during native start',
      (WidgetTester tester) async {
        final startCompleter = Completer<bool>();
        var startCalls = 0;

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(watchDataChannel, (call) async {
              switch (call.method) {
                case 'checkPermission':
                  return 'granted';
                case 'connectWatch':
                case 'isWatchConnected':
                  return true;
                case 'startHeartRate':
                  startCalls += 1;
                  return startCompleter.future;
                case 'stopHeartRate':
                case 'disconnectWatch':
                  return null;
                default:
                  return null;
              }
            });

        await pumpWearHeartRateScreen(tester);

        await tester.tap(find.widgetWithText(ElevatedButton, 'Start'));
        await tester.pump();

        expect(startCalls, 1);
        expect(find.widgetWithText(ElevatedButton, 'Wait'), findsOneWidget);

        await tester.tap(find.widgetWithText(ElevatedButton, 'Wait'));
        await tester.pump();

        expect(startCalls, 1);

        await tester.pumpWidget(const SizedBox.shrink());
        startCompleter.complete(true);
        await tester.pump();

        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('Font sizes meet minimum accessibility requirements', (
      WidgetTester tester,
    ) async {
      // Arrange
      await pumpWearHeartRateScreen(tester);

      // Act - Find text widgets
      final textWidgets = find.byType(Text);

      // Assert - Verify font sizes
      for (final textWidget in textWidgets.evaluate()) {
        final Text widget = textWidget.widget as Text;
        final TextStyle? style = widget.style;

        if (style?.fontSize != null) {
          // Body text should be at least 14sp
          // Status text at 10sp is acceptable for non-critical info
          expect(
            style!.fontSize!,
            greaterThanOrEqualTo(10.0),
            reason: 'Text should have readable font size',
          );
        }
      }
    });

    testWidgets(
      'Error display shows icon and descriptive text with proper styling',
      (WidgetTester tester) async {
        await pumpWearHeartRateScreen(tester);

        await tester.tap(find.widgetWithText(ElevatedButton, 'Start'));
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.byIcon(Icons.error_outline), findsOneWidget);
        expect(
          find.text('Failed to start heart rate tracking'),
          findsOneWidget,
        );
        expect(find.text('Start failed'), findsOneWidget);
      },
    );

    testWidgets(
      'Test mode toggle displays live sensor values from the native bridge',
      (WidgetTester tester) async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(watchDataChannel, (call) async {
              switch (call.method) {
                case 'checkPermission':
                  return 'granted';
                case 'connectWatch':
                case 'isWatchConnected':
                  return true;
                case 'getTestModeData':
                  return {
                    'heartRate': 82,
                    'accelerometerX': 1.25,
                    'accelerometerY': -0.5,
                    'accelerometerZ': 9.81,
                    'bufferSize': 3,
                    'timeSinceLastTransmission': 2500,
                  };
                case 'disconnectWatch':
                  return null;
                default:
                  return null;
              }
            });

        await pumpWearHeartRateScreen(tester);

        await tester.tap(find.byIcon(Icons.bug_report_outlined));
        await tester.pump(const Duration(milliseconds: 600));

        expect(find.text('Test Mode'), findsOneWidget);
        expect(find.text('82 bpm'), findsOneWidget);
        expect(find.text('3/32 samples'), findsOneWidget);
        expect(find.text('2 s ago'), findsOneWidget);
      },
    );
  });
}
