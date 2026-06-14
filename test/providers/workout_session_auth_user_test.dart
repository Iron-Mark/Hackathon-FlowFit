import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late Map<String, String> sources;

  setUpAll(() {
    sources = {
      for (final path in [
        'lib/providers/running_session_provider.dart',
        'lib/providers/walking_session_provider.dart',
        'lib/providers/resistance_session_provider.dart',
        'lib/screens/workout/running/running_summary_screen.dart',
        'lib/screens/workout/running/active_running_screen.dart',
        'lib/screens/workout/walking/active_walking_screen.dart',
        'lib/screens/workout/resistance/split_selection_screen.dart',
        'lib/screens/workout/resistance/active_resistance_screen.dart',
        'lib/screens/workout/resistance/resistance_summary_screen.dart',
      ])
        path: File(path).readAsStringSync(),
    };
  });

  test('workout session providers do not use placeholder user IDs', () {
    for (final entry in sources.entries) {
      expect(
        entry.value,
        isNot(contains('current-user-id')),
        reason: '${entry.key} must use the signed-in auth user.',
      );
    }
  });

  test('workout session providers resolve the current Supabase auth user', () {
    final runningProvider =
        sources['lib/providers/running_session_provider.dart']!;
    expect(runningProvider, contains('workoutSessionUserIdProvider'));
    expect(
      runningProvider,
      contains('Supabase.instance.client.auth.currentUser?.id'),
    );
    expect(runningProvider, contains('requireWorkoutSessionUserId'));

    for (final path in [
      'lib/providers/running_session_provider.dart',
      'lib/providers/walking_session_provider.dart',
      'lib/providers/resistance_session_provider.dart',
    ]) {
      expect(
        sources[path],
        contains('requireWorkoutSessionUserId(_readCurrentUserId)'),
        reason: '$path must fail before persistence when no user is signed in.',
      );
    }
  });

  test('running workouts persist initial and completed sessions', () {
    final runningProvider =
        sources['lib/providers/running_session_provider.dart']!;
    final runningSummary =
        sources['lib/screens/workout/running/running_summary_screen.dart']!;

    expect(
      runningProvider,
      contains('await _sessionService.createSession(session);'),
    );
    expect(
      runningProvider,
      contains('await _sessionService.saveSession(state!);'),
    );
    expect(runningSummary, contains('saveSession(session)'));
    expect(runningSummary, isNot(contains('Backend disabled')));
    expect(runningSummary, isNot(contains('Re-enable when backend is ready')));
  });

  test('active running end action navigates to summary after sync failure', () {
    final activeRunning =
        sources['lib/screens/workout/running/active_running_screen.dart']!;

    expect(activeRunning, contains('try {'));
    expect(activeRunning, contains('await notifier.endSession();'));
    expect(activeRunning, contains('Workout ended, but sync failed'));
    expect(
      activeRunning,
      contains("pushReplacementNamed('/workout/running/summary')"),
    );
  });

  test('production workout screens do not expose placeholder flows', () {
    for (final path in [
      'lib/screens/workout/walking/active_walking_screen.dart',
      'lib/screens/workout/resistance/active_resistance_screen.dart',
      'lib/screens/workout/resistance/resistance_summary_screen.dart',
    ]) {
      final source = sources[path]!;

      expect(source, isNot(contains('placeholder')), reason: path);
      expect(source, isNot(contains('TODO: Implement full')), reason: path);
      expect(source, isNot(contains('Active Walking Screen')), reason: path);
      expect(source, isNot(contains('Active Resistance Screen')), reason: path);
      expect(source, isNot(contains('Save to History')), reason: path);
    }
  });

  test('walking and resistance end actions save before summary navigation', () {
    final activeWalking =
        sources['lib/screens/workout/walking/active_walking_screen.dart']!;
    final activeResistance =
        sources['lib/screens/workout/resistance/active_resistance_screen.dart']!;
    final resistanceSummary =
        sources['lib/screens/workout/resistance/resistance_summary_screen.dart']!;

    expect(activeWalking, contains('await notifier.endSession();'));
    expect(
      activeWalking,
      contains("pushReplacementNamed('/workout/walking/summary')"),
    );
    expect(activeWalking, contains('Workout ended, but sync failed'));

    expect(activeResistance, contains('await notifier.endWorkout();'));
    expect(
      activeResistance,
      contains("pushReplacementNamed('/workout/resistance/summary')"),
    );
    expect(activeResistance, contains('Workout ended, but sync failed'));
    expect(resistanceSummary, contains('retrySaveSession'));
    expect(resistanceSummary, contains('Retry Sync'));
  });

  test('resistance split start creates session before active navigation', () {
    final splitSelection =
        sources['lib/screens/workout/resistance/split_selection_screen.dart']!;

    expect(
      splitSelection,
      contains("import '../../../providers/resistance_session_provider.dart';"),
    );
    expect(
      splitSelection,
      contains("import '../../../providers/workout_flow_provider.dart';"),
    );
    expect(splitSelection, contains('.startSession('));
    expect(splitSelection, contains('split: selectedSplit'));
    expect(splitSelection, contains('exercises: exercises'));
    expect(splitSelection, contains('restTimerSeconds: _restTimerSeconds'));
    expect(splitSelection, contains('audioCuesEnabled: _audioCuesEnabled'));
    expect(splitSelection, contains('hrMonitorEnabled: _hrMonitorEnabled'));
    expect(splitSelection, contains('Could not start resistance workout'));
    expect(
      splitSelection.indexOf('.startSession('),
      lessThan(
        splitSelection.indexOf("pushNamed('/workout/resistance/active')"),
      ),
    );
  });

  test('resistance provider implements audio cue and retry sync paths', () {
    final resistanceProvider =
        sources['lib/providers/resistance_session_provider.dart']!;

    expect(resistanceProvider, contains('SystemSound.play'));
    expect(resistanceProvider, isNot(contains('TODO: Play audio cue')));
    expect(resistanceProvider, contains('Future<void> retrySaveSession()'));
    expect(
      resistanceProvider,
      contains('await _sessionService.saveSession(state!)'),
    );
  });

  test('workout providers persist before starting device services', () {
    final expectations = {
      'lib/providers/running_session_provider.dart':
          'await _gpsService.startTracking();',
      'lib/providers/walking_session_provider.dart':
          'await _gpsService.startTracking();',
      'lib/providers/resistance_session_provider.dart':
          '_timerService.start();',
    };

    for (final entry in expectations.entries) {
      final source = sources[entry.key]!;
      final createIndex = source.indexOf(
        'await _sessionService.createSession(session);',
      );
      final serviceStartIndex = source.indexOf(entry.value);

      expect(createIndex, isNonNegative, reason: entry.key);
      expect(serviceStartIndex, isNonNegative, reason: entry.key);
      expect(
        createIndex,
        lessThan(serviceStartIndex),
        reason:
            '${entry.key} must fail before starting timers, GPS, or sensors '
            'when the Supabase insert is rejected.',
      );
    }
  });
}
