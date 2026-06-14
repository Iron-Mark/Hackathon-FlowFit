import 'package:flutter_test/flutter_test.dart';
import 'package:flowfit/services/calorie_calculator_service.dart';
import 'package:flowfit/models/workout_session.dart';

void main() {
  group('CalorieCalculatorService', () {
    late CalorieCalculatorService service;

    setUp(() {
      service = CalorieCalculatorService();
    });

    group('calculateCalories - Running', () {
      test('calculates calories for moderate pace running', () {
        final calories = service.calculateCalories(
          workoutType: WorkoutType.running,
          durationMinutes: 30,
          distanceKm: 5.0,
          weight: 70.0,
        );

        expect(calories, greaterThan(200));
        expect(calories, lessThan(500));
      });

      test('calculates more calories for faster pace', () {
        final slowPace = service.calculateCalories(
          workoutType: WorkoutType.running,
          durationMinutes: 30,
          distanceKm: 4.0,
          weight: 70.0,
        );
        final fastPace = service.calculateCalories(
          workoutType: WorkoutType.running,
          durationMinutes: 30,
          distanceKm: 7.0,
          weight: 70.0,
        );

        expect(fastPace, greaterThan(slowPace));
      });

      test('calculates more calories for heavier person', () {
        final lighter = service.calculateCalories(
          workoutType: WorkoutType.running,
          durationMinutes: 30,
          distanceKm: 5.0,
          weight: 60.0,
        );
        final heavier = service.calculateCalories(
          workoutType: WorkoutType.running,
          durationMinutes: 30,
          distanceKm: 5.0,
          weight: 80.0,
        );

        expect(heavier, greaterThan(lighter));
      });

      test('calculates more calories for longer duration', () {
        final shorter = service.calculateCalories(
          workoutType: WorkoutType.running,
          durationMinutes: 20,
          distanceKm: 3.0,
          weight: 70.0,
        );
        final longer = service.calculateCalories(
          workoutType: WorkoutType.running,
          durationMinutes: 40,
          distanceKm: 6.0,
          weight: 70.0,
        );

        expect(longer, greaterThan(shorter));
      });

      test('uses default weight when not provided', () {
        final calories = service.calculateCalories(
          workoutType: WorkoutType.running,
          durationMinutes: 30,
          distanceKm: 5.0,
        );

        expect(calories, greaterThan(0));
      });

      test('handles zero distance', () {
        final calories = service.calculateCalories(
          workoutType: WorkoutType.running,
          durationMinutes: 30,
          distanceKm: 0.0,
          weight: 70.0,
        );

        expect(calories, greaterThan(0));
      });

      test('uses heart rate data if provided', () {
        final withHeartRate = service.calculateCalories(
          workoutType: WorkoutType.running,
          durationMinutes: 30,
          distanceKm: 5.0,
          weight: 70.0,
          avgHeartRate: 160,
        );

        expect(withHeartRate, greaterThan(0));
      });
    });

    group('calculateCalories - Walking', () {
      test('calculates calories for moderate walking', () {
        final calories = service.calculateCalories(
          workoutType: WorkoutType.walking,
          durationMinutes: 30,
          distanceKm: 2.0,
          weight: 70.0,
        );

        expect(calories, greaterThan(50));
        expect(calories, lessThan(300));
      });

      test('calculates more calories for brisk walking', () {
        final slowWalk = service.calculateCalories(
          workoutType: WorkoutType.walking,
          durationMinutes: 30,
          distanceKm: 1.5,
          weight: 70.0,
        );
        final briskWalk = service.calculateCalories(
          workoutType: WorkoutType.walking,
          durationMinutes: 30,
          distanceKm: 3.0,
          weight: 70.0,
        );

        expect(briskWalk, greaterThan(slowWalk));
      });

      test('handles different pace categories', () {
        final slow = service.calculateCalories(
          workoutType: WorkoutType.walking,
          durationMinutes: 30,
          distanceKm: 1.5,
          weight: 70.0,
        );
        final moderate = service.calculateCalories(
          workoutType: WorkoutType.walking,
          durationMinutes: 30,
          distanceKm: 2.2,
          weight: 70.0,
        );
        final brisk = service.calculateCalories(
          workoutType: WorkoutType.walking,
          durationMinutes: 30,
          distanceKm: 3.0,
          weight: 70.0,
        );

        expect(brisk, greaterThan(moderate));
        expect(moderate, greaterThan(slow));
      });
    });

    group('calculateCalories - Resistance', () {
      test('calculates calories for resistance training', () {
        final calories = service.calculateCalories(
          workoutType: WorkoutType.resistance,
          durationMinutes: 45,
          weight: 70.0,
        );

        expect(calories, greaterThan(100));
        expect(calories, lessThan(500));
      });

      test('adjusts based on heart rate intensity', () {
        final lowIntensity = service.calculateCalories(
          workoutType: WorkoutType.resistance,
          durationMinutes: 45,
          weight: 70.0,
          avgHeartRate: 110,
        );
        final moderateIntensity = service.calculateCalories(
          workoutType: WorkoutType.resistance,
          durationMinutes: 45,
          weight: 70.0,
          avgHeartRate: 130,
        );
        final highIntensity = service.calculateCalories(
          workoutType: WorkoutType.resistance,
          durationMinutes: 45,
          weight: 70.0,
          avgHeartRate: 150,
        );

        expect(highIntensity, greaterThan(moderateIntensity));
        expect(moderateIntensity, greaterThan(lowIntensity));
      });

      test('uses default MET when no heart rate provided', () {
        final calories = service.calculateCalories(
          workoutType: WorkoutType.resistance,
          durationMinutes: 45,
          weight: 70.0,
        );

        expect(calories, greaterThan(0));
      });
    });

    group('calculateCalories - Cycling', () {
      test('calculates calories for moderate cycling', () {
        final calories = service.calculateCalories(
          workoutType: WorkoutType.cycling,
          durationMinutes: 30,
          distanceKm: 10.0,
          weight: 70.0,
        );

        expect(calories, greaterThan(150));
        expect(calories, lessThan(600));
      });

      test('calculates more calories for faster cycling', () {
        final leisurely = service.calculateCalories(
          workoutType: WorkoutType.cycling,
          durationMinutes: 60,
          distanceKm: 12.0,
          weight: 70.0,
        );
        final fast = service.calculateCalories(
          workoutType: WorkoutType.cycling,
          durationMinutes: 60,
          distanceKm: 30.0,
          weight: 70.0,
        );

        expect(fast, greaterThan(leisurely));
      });

      test('handles different speed categories', () {
        final leisurely = service.calculateCalories(
          workoutType: WorkoutType.cycling,
          durationMinutes: 60,
          distanceKm: 12.0,
          weight: 70.0,
        );
        final moderate = service.calculateCalories(
          workoutType: WorkoutType.cycling,
          durationMinutes: 60,
          distanceKm: 18.0,
          weight: 70.0,
        );
        final moderateFast = service.calculateCalories(
          workoutType: WorkoutType.cycling,
          durationMinutes: 60,
          distanceKm: 22.0,
          weight: 70.0,
        );
        final fast = service.calculateCalories(
          workoutType: WorkoutType.cycling,
          durationMinutes: 60,
          distanceKm: 28.0,
          weight: 70.0,
        );

        expect(fast, greaterThan(moderateFast));
        expect(moderateFast, greaterThan(moderate));
        expect(moderate, greaterThan(leisurely));
      });
    });

    group('calculateCalories - Yoga', () {
      test('calculates calories for yoga session', () {
        final calories = service.calculateCalories(
          workoutType: WorkoutType.yoga,
          durationMinutes: 60,
          weight: 70.0,
        );

        expect(calories, greaterThan(100));
        expect(calories, lessThan(300));
      });

      test('scales with duration', () {
        final shorter = service.calculateCalories(
          workoutType: WorkoutType.yoga,
          durationMinutes: 30,
          weight: 70.0,
        );
        final longer = service.calculateCalories(
          workoutType: WorkoutType.yoga,
          durationMinutes: 90,
          weight: 70.0,
        );

        expect(longer, greaterThan(shorter));
        expect(longer, closeTo(shorter * 3, 10));
      });

      test('scales with weight', () {
        final lighter = service.calculateCalories(
          workoutType: WorkoutType.yoga,
          durationMinutes: 60,
          weight: 50.0,
        );
        final heavier = service.calculateCalories(
          workoutType: WorkoutType.yoga,
          durationMinutes: 60,
          weight: 90.0,
        );

        expect(heavier, greaterThan(lighter));
      });
    });

    group('calculatePace', () {
      test('calculates pace correctly for running', () {
        final pace = service.calculatePace(
          distanceKm: 5.0,
          durationMinutes: 25,
        );

        expect(pace, equals(5.0)); // 5 min/km
      });

      test('calculates pace for different distances', () {
        final pace10k = service.calculatePace(
          distanceKm: 10.0,
          durationMinutes: 50,
        );
        final pace5k = service.calculatePace(
          distanceKm: 5.0,
          durationMinutes: 25,
        );

        expect(pace10k, equals(5.0));
        expect(pace5k, equals(5.0));
      });

      test('handles fractional values', () {
        final pace = service.calculatePace(
          distanceKm: 5.5,
          durationMinutes: 33,
        );

        expect(pace, closeTo(6.0, 0.1));
      });

      test('returns zero for zero distance', () {
        final pace = service.calculatePace(
          distanceKm: 0.0,
          durationMinutes: 30,
        );

        expect(pace, equals(0.0));
      });

      test('calculates faster pace for shorter duration', () {
        final faster = service.calculatePace(
          distanceKm: 5.0,
          durationMinutes: 20,
        );
        final slower = service.calculatePace(
          distanceKm: 5.0,
          durationMinutes: 30,
        );

        expect(faster, lessThan(slower));
      });
    });

    group('calculateTargetHeartRate', () {
      test('calculates target heart rate for moderate intensity', () {
        final targetHR = service.calculateTargetHeartRate(
          age: 30,
          intensity: 0.7,
        );

        expect(targetHR, greaterThan(130));
        expect(targetHR, lessThan(170));
      });

      test('calculates higher HR for higher intensity', () {
        final lowIntensity = service.calculateTargetHeartRate(
          age: 30,
          intensity: 0.5,
        );
        final highIntensity = service.calculateTargetHeartRate(
          age: 30,
          intensity: 0.9,
        );

        expect(highIntensity, greaterThan(lowIntensity));
      });

      test('calculates lower HR for older age', () {
        final younger = service.calculateTargetHeartRate(
          age: 25,
          intensity: 0.7,
        );
        final older = service.calculateTargetHeartRate(age: 50, intensity: 0.7);

        expect(younger, greaterThan(older));
      });

      test('handles zero intensity', () {
        final targetHR = service.calculateTargetHeartRate(
          age: 30,
          intensity: 0.0,
        );

        expect(targetHR, equals(60)); // Should equal resting HR
      });

      test('handles maximum intensity', () {
        final targetHR = service.calculateTargetHeartRate(
          age: 30,
          intensity: 1.0,
        );

        const maxHR = 220 - 30;
        expect(targetHR, lessThanOrEqualTo(maxHR));
        expect(targetHR, greaterThan(180));
      });

      test('uses Karvonen formula correctly', () {
        // Karvonen: Target HR = ((max HR − resting HR) × intensity) + resting HR
        const age = 40;
        const intensity = 0.6;
        const maxHR = 220 - age; // 180
        const restingHR = 60;
        final expected = ((maxHR - restingHR) * intensity + restingHR).round();

        final targetHR = service.calculateTargetHeartRate(
          age: age,
          intensity: intensity,
        );

        expect(targetHR, equals(expected));
      });
    });

    group('Edge Cases and Boundary Conditions', () {
      test('handles zero duration', () {
        final calories = service.calculateCalories(
          workoutType: WorkoutType.running,
          durationMinutes: 0,
          distanceKm: 0.0,
          weight: 70.0,
        );

        expect(calories, equals(0));
      });

      test('handles very long duration', () {
        final calories = service.calculateCalories(
          workoutType: WorkoutType.walking,
          durationMinutes: 300,
          distanceKm: 15.0,
          weight: 70.0,
        );

        expect(calories, greaterThan(500));
      });

      test('handles very light weight', () {
        final calories = service.calculateCalories(
          workoutType: WorkoutType.running,
          durationMinutes: 30,
          distanceKm: 5.0,
          weight: 40.0,
        );

        expect(calories, greaterThan(0));
        expect(calories, lessThan(300));
      });

      test('handles very heavy weight', () {
        final calories = service.calculateCalories(
          workoutType: WorkoutType.running,
          durationMinutes: 30,
          distanceKm: 5.0,
          weight: 120.0,
        );

        expect(calories, greaterThan(300));
      });

      test('handles very short distance', () {
        final calories = service.calculateCalories(
          workoutType: WorkoutType.walking,
          durationMinutes: 10,
          distanceKm: 0.5,
          weight: 70.0,
        );

        expect(calories, greaterThan(0));
      });

      test('handles very long distance', () {
        final calories = service.calculateCalories(
          workoutType: WorkoutType.cycling,
          durationMinutes: 180,
          distanceKm: 60.0,
          weight: 70.0,
        );

        expect(calories, greaterThan(1000));
      });

      test('handles null optional parameters gracefully', () {
        final calories = service.calculateCalories(
          workoutType: WorkoutType.running,
          durationMinutes: 30,
        );

        expect(calories, greaterThan(0));
      });

      test('handles extreme heart rate values', () {
        final lowHR = service.calculateCalories(
          workoutType: WorkoutType.resistance,
          durationMinutes: 45,
          weight: 70.0,
          avgHeartRate: 80,
        );
        final highHR = service.calculateCalories(
          workoutType: WorkoutType.resistance,
          durationMinutes: 45,
          weight: 70.0,
          avgHeartRate: 180,
        );

        expect(lowHR, greaterThan(0));
        expect(highHR, greaterThan(lowHR));
      });
    });

    group('Consistency and Proportionality', () {
      test('doubles duration doubles calories (approximately)', () {
        final base = service.calculateCalories(
          workoutType: WorkoutType.running,
          durationMinutes: 30,
          distanceKm: 5.0,
          weight: 70.0,
        );
        final doubled = service.calculateCalories(
          workoutType: WorkoutType.running,
          durationMinutes: 60,
          distanceKm: 10.0,
          weight: 70.0,
        );

        expect(doubled, closeTo(base * 2, base * 0.1));
      });

      test('calories are proportional to weight', () {
        final weight60 = service.calculateCalories(
          workoutType: WorkoutType.walking,
          durationMinutes: 30,
          distanceKm: 2.5,
          weight: 60.0,
        );
        final weight80 = service.calculateCalories(
          workoutType: WorkoutType.walking,
          durationMinutes: 30,
          distanceKm: 2.5,
          weight: 80.0,
        );

        final ratio = weight80 / weight60;
        expect(ratio, closeTo(80.0 / 60.0, 0.1));
      });

      test('running burns more calories than walking for same duration', () {
        final walking = service.calculateCalories(
          workoutType: WorkoutType.walking,
          durationMinutes: 30,
          distanceKm: 2.0,
          weight: 70.0,
        );
        final running = service.calculateCalories(
          workoutType: WorkoutType.running,
          durationMinutes: 30,
          distanceKm: 5.0,
          weight: 70.0,
        );

        expect(running, greaterThan(walking));
      });

      test('yoga burns fewer calories than resistance training', () {
        final yoga = service.calculateCalories(
          workoutType: WorkoutType.yoga,
          durationMinutes: 60,
          weight: 70.0,
        );
        final resistance = service.calculateCalories(
          workoutType: WorkoutType.resistance,
          durationMinutes: 60,
          weight: 70.0,
        );

        expect(resistance, greaterThan(yoga));
      });
    });
  });
}
