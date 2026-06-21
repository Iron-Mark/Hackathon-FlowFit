import 'package:flutter_test/flutter_test.dart';
import 'package:flowfit/models/recent_activity.dart';

void main() {
  group('RecentActivity', () {
    test('creates instance with valid data', () {
      final now = DateTime.now();
      final activity = RecentActivity(
        id: '1',
        name: 'Morning Run',
        type: 'run',
        details: '3.2 miles • 30 min',
        date: now,
      );

      expect(activity.id, '1');
      expect(activity.name, 'Morning Run');
      expect(activity.type, 'run');
      expect(activity.details, '3.2 miles • 30 min');
      expect(activity.date, now);
    });

    test('dateLabel returns "Today" for today\'s date', () {
      final now = DateTime.now();
      final activity = RecentActivity(
        id: '1',
        name: 'Morning Run',
        type: 'run',
        details: '3.2 miles • 30 min',
        date: now,
      );

      expect(activity.dateLabel, 'Today');
    });

    test('dateLabel returns "Yesterday" for yesterday\'s date', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final activity = RecentActivity(
        id: '1',
        name: 'Morning Run',
        type: 'run',
        details: '3.2 miles • 30 min',
        date: yesterday,
      );

      expect(activity.dateLabel, 'Yesterday');
    });

    test('dateLabel returns formatted date for older dates', () {
      final oldDate = DateTime.now().subtract(const Duration(days: 5));
      final activity = RecentActivity(
        id: '1',
        name: 'Morning Run',
        type: 'run',
        details: '3.2 miles • 30 min',
        date: oldDate,
      );

      // Should be in "MMM d" format (e.g., "Nov 21")
      expect(activity.dateLabel, isNot('Today'));
      expect(activity.dateLabel, isNot('Yesterday'));
      expect(activity.dateLabel.length, greaterThan(0));
    });

    test('accepts valid activity types', () {
      final now = DateTime.now();

      expect(
        () => RecentActivity(
          id: '1',
          name: 'Run',
          type: 'run',
          details: 'details',
          date: now,
        ),
        returnsNormally,
      );

      expect(
        () => RecentActivity(
          id: '2',
          name: 'Walk',
          type: 'walk',
          details: 'details',
          date: now,
        ),
        returnsNormally,
      );

      expect(
        () => RecentActivity(
          id: '3',
          name: 'Workout',
          type: 'workout',
          details: 'details',
          date: now,
        ),
        returnsNormally,
      );

      expect(
        () => RecentActivity(
          id: '4',
          name: 'Cycle',
          type: 'cycle',
          details: 'details',
          date: now,
        ),
        returnsNormally,
      );
    });

    test('asserts on invalid activity type', () {
      final now = DateTime.now();

      expect(
        () => RecentActivity(
          id: '1',
          name: 'Invalid',
          type: 'invalid',
          details: 'details',
          date: now,
        ),
        throwsAssertionError,
      );
    });

    test('asserts on future date', () {
      final future = DateTime.now().add(const Duration(days: 1));

      expect(
        () => RecentActivity(
          id: '1',
          name: 'Future Activity',
          type: 'run',
          details: 'details',
          date: future,
        ),
        throwsAssertionError,
      );
    });

    test('fromJson creates valid instance', () {
      final now = DateTime.now();
      final json = {
        'id': '1',
        'name': 'Morning Run',
        'type': 'run',
        'details': '3.2 miles • 30 min',
        'date': now.toIso8601String(),
      };

      final activity = RecentActivity.fromJson(json);

      expect(activity.id, '1');
      expect(activity.name, 'Morning Run');
      expect(activity.type, 'run');
      expect(activity.details, '3.2 miles • 30 min');
    });

    test('toJson creates valid map', () {
      final now = DateTime.now();
      final activity = RecentActivity(
        id: '1',
        name: 'Morning Run',
        type: 'run',
        details: '3.2 miles • 30 min',
        date: now,
      );

      final json = activity.toJson();

      expect(json['id'], '1');
      expect(json['name'], 'Morning Run');
      expect(json['type'], 'run');
      expect(json['details'], '3.2 miles • 30 min');
      expect(json['date'], now.toIso8601String());
    });

    test('equality works correctly', () {
      final now = DateTime.now();
      final activity1 = RecentActivity(
        id: '1',
        name: 'Morning Run',
        type: 'run',
        details: '3.2 miles • 30 min',
        date: now,
      );

      final activity2 = RecentActivity(
        id: '1',
        name: 'Morning Run',
        type: 'run',
        details: '3.2 miles • 30 min',
        date: now,
      );

      expect(activity1, activity2);
    });

    test('hashCode works correctly', () {
      final now = DateTime.now();
      final activity1 = RecentActivity(
        id: '1',
        name: 'Morning Run',
        type: 'run',
        details: '3.2 miles • 30 min',
        date: now,
      );

      final activity2 = RecentActivity(
        id: '1',
        name: 'Morning Run',
        type: 'run',
        details: '3.2 miles • 30 min',
        date: now,
      );

      expect(activity1.hashCode, activity2.hashCode);
    });
  });
}
