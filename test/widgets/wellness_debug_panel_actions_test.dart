import 'package:flowfit/models/wellness_state.dart';
import 'package:flowfit/providers/wellness_state_provider.dart';
import 'package:flowfit/widgets/wellness/wellness_debug_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets(
    'debug panel expands, collapses, and applies mock state buttons',
    (tester) async {
      tester.view.physicalSize = const Size(900, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: const MaterialApp(
            home: Scaffold(
              body: Stack(
                children: [
                  SizedBox.expand(child: Text('Wellness tracker content')),
                  WellnessDebugPanel(),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Debug Panel'), findsNothing);

      await tester.tap(find.byIcon(Icons.bug_report));
      await tester.pumpAndSettle();

      expect(find.text('Debug Panel'), findsOneWidget);
      expect(find.text('Current State: Unknown'), findsOneWidget);

      await tester.tap(find.widgetWithText(ElevatedButton, 'STRESS'));
      await tester.pumpAndSettle();

      expect(find.text('Current State: Stress'), findsOneWidget);

      await tester.tap(find.widgetWithText(ElevatedButton, 'CARDIO'));
      await tester.pumpAndSettle();

      expect(find.text('Current State: Cardio'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.text('Debug Panel'), findsNothing);
      expect(find.byIcon(Icons.bug_report), findsOneWidget);
    },
  );

  testWidgets(
    'debug panel scenario buttons show feedback without sensor input',
    (tester) async {
      tester.view.physicalSize = const Size(900, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: const MaterialApp(
            home: Scaffold(
              body: Stack(
                children: [
                  SizedBox.expand(child: Text('Wellness tracker content')),
                  WellnessDebugPanel(),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.bug_report));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(OutlinedButton, 'Exercise'));
      await tester.pump();

      expect(find.text('HR: 150 BPM'), findsOneWidget);
      expect(find.text('Motion: 3.5 m/s²'), findsOneWidget);
      expect(
        find.text('Simulating: HR=150 BPM, Motion=3.5 m/s²'),
        findsOneWidget,
      );
    },
  );

  testWidgets('debug panel watch disconnect scenario shows feedback', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                SizedBox.expand(child: Text('Wellness tracker content')),
                WellnessDebugPanel(),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.bug_report));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(OutlinedButton, 'Watch Disconnect'));
    await tester.pump();

    expect(find.text('Simulating watch disconnection...'), findsOneWidget);
  });

  testWidgets('debug panel starts with provider state values', (tester) async {
    tester.view.physicalSize = const Size(900, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final initialState = WellnessStateData(
      state: WellnessState.calm,
      timestamp: DateTime(2026, 6, 20),
      heartRate: 72,
      motionMagnitude: 0.24,
      confidence: 0.8,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          wellnessStateProvider.overrideWith((ref) {
            final service = ref.watch(wellnessStateServiceProvider);
            return _SeededWellnessNotifier(service, prefs, initialState);
          }),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                SizedBox.expand(child: Text('Wellness tracker content')),
                WellnessDebugPanel(),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.bug_report));
    await tester.pumpAndSettle();

    expect(find.text('Current State: Calm'), findsOneWidget);
    expect(find.text('HR: 72 BPM'), findsOneWidget);
    expect(find.text('Motion: 0.24 m/s²'), findsOneWidget);
    expect(find.text('Confidence: 80%'), findsOneWidget);
  });
}

class _SeededWellnessNotifier extends WellnessStateNotifier {
  _SeededWellnessNotifier(
    super.service,
    super.prefs,
    WellnessStateData seededState,
  ) {
    state = seededState;
  }
}
