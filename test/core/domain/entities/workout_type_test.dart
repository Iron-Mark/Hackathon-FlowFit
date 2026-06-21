import 'package:flutter_test/flutter_test.dart';
import 'package:flowfit/core/domain/entities/workout_type.dart';

void main() {
  group('WorkoutType', () {
    group('Enum Values', () {
      test('has all expected workout types', () {
        expect(WorkoutType.values.length, equals(6));
        expect(WorkoutType.values, contains(WorkoutType.running));
        expect(WorkoutType.values, contains(WorkoutType.walking));
        expect(WorkoutType.values, contains(WorkoutType.cycling));
        expect(WorkoutType.values, contains(WorkoutType.strength));
        expect(WorkoutType.values, contains(WorkoutType.yoga));
        expect(WorkoutType.values, contains(WorkoutType.other));
      });

      test('enum values have correct names', () {
        expect(WorkoutType.running.name, equals('running'));
        expect(WorkoutType.walking.name, equals('walking'));
        expect(WorkoutType.cycling.name, equals('cycling'));
        expect(WorkoutType.strength.name, equals('strength'));
        expect(WorkoutType.yoga.name, equals('yoga'));
        expect(WorkoutType.other.name, equals('other'));
      });
    });

    group('displayName', () {
      test('returns correct display name for running', () {
        expect(WorkoutType.running.displayName, equals('Running'));
      });

      test('returns correct display name for walking', () {
        expect(WorkoutType.walking.displayName, equals('Walking'));
      });

      test('returns correct display name for cycling', () {
        expect(WorkoutType.cycling.displayName, equals('Cycling'));
      });

      test('returns correct display name for strength', () {
        expect(WorkoutType.strength.displayName, equals('Strength'));
      });

      test('returns correct display name for yoga', () {
        expect(WorkoutType.yoga.displayName, equals('Yoga'));
      });

      test('returns correct display name for other', () {
        expect(WorkoutType.other.displayName, equals('Other'));
      });

      test('all display names are capitalized', () {
        for (final type in WorkoutType.values) {
          final displayName = type.displayName;
          expect(displayName[0], equals(displayName[0].toUpperCase()));
        }
      });

      test('display names have no trailing whitespace', () {
        for (final type in WorkoutType.values) {
          final displayName = type.displayName;
          expect(displayName, equals(displayName.trim()));
        }
      });
    });

    group('Enum Operations', () {
      test('can iterate over all workout types', () {
        final displayNames = <String>[];
        for (final type in WorkoutType.values) {
          displayNames.add(type.displayName);
        }

        expect(displayNames, hasLength(6));
        expect(displayNames, contains('Running'));
        expect(displayNames, contains('Walking'));
      });

      test('can compare workout types', () {
        expect(WorkoutType.running, equals(WorkoutType.running));
        expect(WorkoutType.running, isNot(equals(WorkoutType.walking)));
      });

      test('can use in switch statements', () {
        String getDescription(WorkoutType type) {
          switch (type) {
            case WorkoutType.running:
              return 'Cardiovascular';
            case WorkoutType.walking:
              return 'Low impact';
            case WorkoutType.cycling:
              return 'Endurance';
            case WorkoutType.strength:
              return 'Muscle building';
            case WorkoutType.yoga:
              return 'Flexibility';
            case WorkoutType.other:
              return 'General';
          }
        }

        expect(getDescription(WorkoutType.running), equals('Cardiovascular'));
        expect(getDescription(WorkoutType.yoga), equals('Flexibility'));
      });

      test('can convert from string name', () {
        final type = WorkoutType.values.byName('running');
        expect(type, equals(WorkoutType.running));
      });

      test('can be used as map keys', () {
        final map = <WorkoutType, String>{
          WorkoutType.running: 'Run',
          WorkoutType.walking: 'Walk',
        };

        expect(map[WorkoutType.running], equals('Run'));
        expect(map[WorkoutType.walking], equals('Walk'));
      });

      test('can be used in sets', () {
        final cardioTypes = {
          WorkoutType.running,
          WorkoutType.walking,
          WorkoutType.cycling,
        };

        expect(cardioTypes, hasLength(3));
        expect(cardioTypes, contains(WorkoutType.running));
        expect(cardioTypes, isNot(contains(WorkoutType.yoga)));
      });
    });

    group('Serialization', () {
      test('enum index is consistent', () {
        expect(WorkoutType.running.index, equals(0));
        expect(WorkoutType.walking.index, equals(1));
        expect(WorkoutType.cycling.index, equals(2));
        expect(WorkoutType.strength.index, equals(3));
        expect(WorkoutType.yoga.index, equals(4));
        expect(WorkoutType.other.index, equals(5));
      });

      test('can convert to and from name', () {
        for (final type in WorkoutType.values) {
          final name = type.name;
          final recovered = WorkoutType.values.byName(name);
          expect(recovered, equals(type));
        }
      });
    });
  });
}
