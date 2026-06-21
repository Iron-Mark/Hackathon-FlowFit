import 'dart:async';

import 'package:flowfit/providers/wellness_state_provider.dart';
import 'package:flowfit/screens/wellness/wellness_settings_screen.dart';
import 'package:flowfit/services/phone_data_listener.dart';
import 'package:flowfit/services/wellness_monitoring_service.dart';
import 'package:flowfit/services/wellness_state_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('wellness settings persist alert preferences', (tester) async {
    SharedPreferences.setMockInitialValues({
      'wellness_stress_alerts_enabled': true,
      'wellness_cardio_alerts_enabled': true,
      'wellness_alert_frequency_minutes': 30,
    });
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const MaterialApp(home: WellnessSettingsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Stress Alerts'));
    await tester.pumpAndSettle();

    expect(prefs.getBool('wellness_stress_alerts_enabled'), isFalse);

    await tester.tap(find.text('Exercise Detection'));
    await tester.pumpAndSettle();

    expect(prefs.getBool('wellness_cardio_alerts_enabled'), isFalse);

    await tester.tap(find.byType(DropdownButton<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('1 hour').last);
    await tester.pumpAndSettle();

    expect(prefs.getInt('wellness_alert_frequency_minutes'), 60);
  });

  testWidgets('wellness monitoring toggle calls lifecycle service', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'wellness_monitoring_enabled': false,
    });
    final prefs = await SharedPreferences.getInstance();
    final monitoringService = _FakeWellnessMonitoringService(prefs);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          wellnessMonitoringServiceProvider.overrideWithValue(
            monitoringService,
          ),
        ],
        child: const MaterialApp(home: WellnessSettingsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Enable Wellness Monitoring'));
    await tester.pumpAndSettle();

    expect(monitoringService.enableCalls, 1);
    expect(prefs.getBool('wellness_monitoring_enabled'), isTrue);

    await tester.tap(find.text('Enable Wellness Monitoring'));
    await tester.pumpAndSettle();

    expect(monitoringService.disableCalls, 1);
    expect(prefs.getBool('wellness_monitoring_enabled'), isFalse);
  });

  testWidgets('failed wellness monitoring enable does not persist enabled', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'wellness_monitoring_enabled': false,
    });
    final prefs = await SharedPreferences.getInstance();
    final monitoringService = _FakeWellnessMonitoringService(
      prefs,
      failEnable: true,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          wellnessMonitoringServiceProvider.overrideWithValue(
            monitoringService,
          ),
        ],
        child: const MaterialApp(home: WellnessSettingsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Enable Wellness Monitoring'));
    await tester.pumpAndSettle();

    expect(monitoringService.enableCalls, 1);
    expect(prefs.getBool('wellness_monitoring_enabled'), isFalse);
    expect(
      find.textContaining('Could not start wellness monitoring'),
      findsOneWidget,
    );
    expect(
      tester
          .widget<SwitchListTile>(
            find.widgetWithText(SwitchListTile, 'Enable Wellness Monitoring'),
          )
          .value,
      isFalse,
    );
  });

  testWidgets('privacy policy action opens the privacy route', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: MaterialApp(
          home: const WellnessSettingsScreen(),
          routes: {
            '/privacy-policy': (_) =>
                const Scaffold(body: Text('Privacy route opened')),
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Privacy Policy'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Privacy Policy'));
    await tester.pumpAndSettle();

    expect(find.text('Privacy route opened'), findsOneWidget);
  });

  testWidgets('clear wellness history copy is local-device scoped', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'wellness_history': '[]',
      'wellness_transitions': '[]',
    });
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const MaterialApp(home: WellnessSettingsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Clear Wellness History'));
    await tester.pumpAndSettle();
    expect(find.text('Clear local device wellness history'), findsOneWidget);

    await tester.tap(find.text('Clear Wellness History'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'This clears local wellness state history and transitions on this device. It does not delete account, workout, heart-rate, or Supabase records.',
      ),
      findsOneWidget,
    );
    expect(find.widgetWithText(TextButton, 'Clear'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Clear'));
    await tester.pumpAndSettle();

    expect(find.text('Local wellness history cleared'), findsOneWidget);
    expect(prefs.containsKey('wellness_history'), isFalse);
    expect(prefs.containsKey('wellness_transitions'), isFalse);
  });

  testWidgets('clear wellness history can be cancelled', (tester) async {
    SharedPreferences.setMockInitialValues({
      'wellness_history': '[]',
      'wellness_transitions': '[]',
    });
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const MaterialApp(home: WellnessSettingsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Clear Wellness History'));
    await tester.tap(find.text('Clear Wellness History'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Clear Local Wellness History?'), findsNothing);
    expect(prefs.containsKey('wellness_history'), isTrue);
    expect(prefs.containsKey('wellness_transitions'), isTrue);
  });

  testWidgets('clear wellness history ignores duplicate confirmations', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'wellness_history': '[]',
      'wellness_transitions': '[]',
    });
    final prefs = await SharedPreferences.getInstance();
    final wellnessNotifier = _FakeWellnessStateNotifier(prefs);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          wellnessStateProvider.overrideWith((ref) => wellnessNotifier),
        ],
        child: const MaterialApp(home: WellnessSettingsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Clear Wellness History'));
    await tester.pumpAndSettle();

    final clearTile = tester.widget<ListTile>(
      find.widgetWithText(ListTile, 'Clear Wellness History'),
    );
    clearTile.onTap!();
    clearTile.onTap!();
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await tester.pumpAndSettle();

    expect(wellnessNotifier.clearCalls, 0);
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('clear wellness history ignores duplicate clears while pending', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'wellness_history': '[]',
      'wellness_transitions': '[]',
    });
    final prefs = await SharedPreferences.getInstance();
    final clearCompleter = Completer<void>();
    final wellnessNotifier = _FakeWellnessStateNotifier(
      prefs,
      clearCompleter: clearCompleter,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          wellnessStateProvider.overrideWith((ref) => wellnessNotifier),
        ],
        child: const MaterialApp(home: WellnessSettingsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Clear Wellness History'));
    await tester.tap(find.text('Clear Wellness History'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Clear'));
    await tester.pumpAndSettle();

    expect(wellnessNotifier.clearCalls, 1);
    expect(find.byType(AlertDialog), findsNothing);
    expect(
      tester
          .widget<ListTile>(
            find.widgetWithText(ListTile, 'Clear Wellness History'),
          )
          .onTap,
      isNull,
    );

    await tester.tap(find.text('Clear Wellness History'), warnIfMissed: false);
    await tester.pump();

    expect(wellnessNotifier.clearCalls, 1);

    clearCompleter.complete();
    await tester.pumpAndSettle();

    expect(wellnessNotifier.clearCalls, 1);
    expect(find.text('Local wellness history cleared'), findsOneWidget);
    expect(prefs.containsKey('wellness_history'), isFalse);
    expect(prefs.containsKey('wellness_transitions'), isFalse);
  });
}

class _FakeWellnessMonitoringService extends WellnessMonitoringService {
  _FakeWellnessMonitoringService(this.prefs, {this.failEnable = false})
    : super(WellnessStateService(PhoneDataListener()), prefs);

  final SharedPreferences prefs;
  final bool failEnable;
  var enableCalls = 0;
  var disableCalls = 0;

  @override
  bool get isEnabled => prefs.getBool('wellness_monitoring_enabled') ?? false;

  @override
  Future<void> enableMonitoring() async {
    enableCalls++;
    if (failEnable) {
      await prefs.setBool('wellness_monitoring_enabled', false);
      throw StateError('sensor unavailable');
    }
    await prefs.setBool('wellness_monitoring_enabled', true);
  }

  @override
  Future<void> disableMonitoring() async {
    disableCalls++;
    await prefs.setBool('wellness_monitoring_enabled', false);
  }
}

class _FakeWellnessStateNotifier extends WellnessStateNotifier {
  _FakeWellnessStateNotifier(this.prefs, {this.clearCompleter})
    : super(WellnessStateService(PhoneDataListener()), prefs);

  final SharedPreferences prefs;
  final Completer<void>? clearCompleter;
  var clearCalls = 0;

  @override
  Future<void> clearHistory() async {
    clearCalls++;
    final completer = clearCompleter;
    if (completer != null) {
      await completer.future;
    }
    await super.clearHistory();
  }
}
