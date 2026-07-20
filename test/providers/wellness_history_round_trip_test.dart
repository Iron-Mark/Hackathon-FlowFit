import 'dart:async';
import 'dart:convert';

import 'package:flowfit/models/state_transition.dart';
import 'package:flowfit/models/wellness_state.dart';
import 'package:flowfit/providers/wellness_state_provider.dart';
import 'package:flowfit/services/sensors/phone_data_listener.dart';
import 'package:flowfit/services/wellness/wellness_state_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Test double that lets the test push wellness states through the same
/// stream the notifier subscribes to, without touching platform channels.
class _FakeWellnessStateService extends WellnessStateService {
  _FakeWellnessStateService() : super(PhoneDataListener());

  final StreamController<WellnessStateData> controller =
      StreamController<WellnessStateData>.broadcast();

  @override
  Stream<WellnessStateData> get stateStream => controller.stream;
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('saved history and transitions reload in a fresh notifier', () async {
    final prefs = await SharedPreferences.getInstance();

    final writerService = _FakeWellnessStateService();
    addTearDown(writerService.controller.close);
    final writer = WellnessStateNotifier(writerService, prefs);
    addTearDown(writer.dispose);

    final calmTime = DateTime.now().subtract(const Duration(minutes: 10));
    final stressTime = DateTime.now().subtract(const Duration(minutes: 5));

    writerService.controller.add(
      WellnessStateData(
        state: WellnessState.calm,
        timestamp: calmTime,
        heartRate: 72,
        motionMagnitude: 0.3,
        confidence: 0.9,
      ),
    );
    writerService.controller.add(
      WellnessStateData(
        state: WellnessState.stress,
        timestamp: stressTime,
        heartRate: 110,
        confidence: 0.8,
      ),
    );
    await pumpEventQueue();

    // Sanity: persisted entries must be JSON, not Map.toString output.
    final storedHistory = prefs.getStringList('wellness_history')!;
    expect(storedHistory, hasLength(2));
    expect(() => jsonDecode(storedHistory.first), returnsNormally);

    final readerService = _FakeWellnessStateService();
    addTearDown(readerService.controller.close);
    final reader = WellnessStateNotifier(readerService, prefs);
    addTearDown(reader.dispose);
    await pumpEventQueue();

    final history = reader.getStateHistory();
    expect(history, hasLength(2));
    expect(history[0].state, WellnessState.calm);
    expect(history[0].timestamp, calmTime);
    expect(history[0].heartRate, 72);
    expect(history[0].motionMagnitude, 0.3);
    expect(history[0].confidence, 0.9);
    expect(history[1].state, WellnessState.stress);
    expect(history[1].timestamp, stressTime);
    expect(history[1].heartRate, 110);
    expect(history[1].motionMagnitude, isNull);
    expect(history[1].confidence, 0.8);

    final transitions = reader.getTransitions();
    expect(transitions, hasLength(2));
    expect(transitions[0].fromState, WellnessState.unknown);
    expect(transitions[0].toState, WellnessState.calm);
    expect(transitions[1].fromState, WellnessState.calm);
    expect(transitions[1].toState, WellnessState.stress);
    expect(transitions[1].timestamp, stressTime);
    // Duration round-trips at whole-second precision (duration_seconds).
    expect(
      transitions[1].duration.inSeconds,
      stressTime.difference(calmTime).inSeconds,
    );
  });

  test('legacy Map.toString entries are skipped, valid entries load', () async {
    final validTime = DateTime.now().subtract(const Duration(minutes: 3));
    final validEntry = WellnessStateData(
      state: WellnessState.cardio,
      timestamp: validTime,
      heartRate: 140,
      confidence: 1.0,
    );
    final validTransition = StateTransition(
      fromState: WellnessState.calm,
      toState: WellnessState.cardio,
      timestamp: validTime,
      duration: const Duration(seconds: 45),
    );

    SharedPreferences.setMockInitialValues({
      'wellness_history': <String>[
        // Legacy pre-fix format: Dart Map.toString, not parseable as JSON.
        validEntry.toJson().toString(),
        jsonEncode(validEntry.toJson()),
      ],
      'wellness_transitions': <String>[
        validTransition.toJson().toString(),
        jsonEncode(validTransition.toJson()),
      ],
    });
    final prefs = await SharedPreferences.getInstance();

    final service = _FakeWellnessStateService();
    addTearDown(service.controller.close);
    final notifier = WellnessStateNotifier(service, prefs);
    addTearDown(notifier.dispose);
    await pumpEventQueue();

    final history = notifier.getStateHistory();
    expect(history, hasLength(1));
    expect(history.single.state, WellnessState.cardio);
    expect(history.single.timestamp, validTime);
    expect(history.single.heartRate, 140);

    final transitions = notifier.getTransitions();
    expect(transitions, hasLength(1));
    expect(transitions.single.fromState, WellnessState.calm);
    expect(transitions.single.toState, WellnessState.cardio);
    expect(transitions.single.timestamp, validTime);
    expect(transitions.single.duration, const Duration(seconds: 45));
  });
}
