import 'package:flutter_test/flutter_test.dart';
import 'package:flowfit/domain/entities/user_profile.dart';

void main() {
  group('UserProfile', () {
    late UserProfile testProfile;

    setUp(() {
      testProfile = const UserProfile(
        userId: 'user_123',
        fullName: 'John Doe',
        age: 30,
        gender: 'male',
        weight: 75.0,
        height: 180.0,
        activityLevel: 'moderate',
        goals: ['weight_loss', 'muscle_gain'],
        dailyCalorieTarget: 2000,
        surveyCompleted: true,
      );
    });

    group('Constructor', () {
      test('creates profile with all required fields', () {
        expect(testProfile.userId, equals('user_123'));
        expect(testProfile.fullName, equals('John Doe'));
        expect(testProfile.age, equals(30));
        expect(testProfile.gender, equals('male'));
        expect(testProfile.weight, equals(75.0));
        expect(testProfile.height, equals(180.0));
        expect(testProfile.activityLevel, equals('moderate'));
        expect(testProfile.goals, equals(['weight_loss', 'muscle_gain']));
        expect(testProfile.dailyCalorieTarget, equals(2000));
        expect(testProfile.surveyCompleted, isTrue);
      });

      test('accepts const constructor', () {
        const profile = UserProfile(
          userId: 'user_1',
          fullName: 'Test',
          age: 25,
          gender: 'female',
          weight: 60.0,
          height: 165.0,
          activityLevel: 'active',
          goals: [],
          dailyCalorieTarget: 1800,
          surveyCompleted: false,
        );

        expect(profile.userId, equals('user_1'));
      });

      test('accepts empty goals list', () {
        const profile = UserProfile(
          userId: 'user_1',
          fullName: 'Test',
          age: 25,
          gender: 'female',
          weight: 60.0,
          height: 165.0,
          activityLevel: 'active',
          goals: [],
          dailyCalorieTarget: 1800,
          surveyCompleted: false,
        );

        expect(profile.goals, isEmpty);
      });
    });

    group('copyWith', () {
      test('creates copy with updated single field', () {
        final copy = testProfile.copyWith(age: 31);

        expect(copy.age, equals(31));
        expect(copy.userId, equals(testProfile.userId));
        expect(copy.fullName, equals(testProfile.fullName));
        expect(copy.weight, equals(testProfile.weight));
      });

      test('creates copy with updated weight', () {
        final copy = testProfile.copyWith(weight: 80.0);

        expect(copy.weight, equals(80.0));
        expect(copy.age, equals(testProfile.age));
      });

      test('creates copy with updated height', () {
        final copy = testProfile.copyWith(height: 185.0);

        expect(copy.height, equals(185.0));
        expect(copy.weight, equals(testProfile.weight));
      });

      test('creates copy with updated goals', () {
        final newGoals = ['endurance', 'flexibility'];
        final copy = testProfile.copyWith(goals: newGoals);

        expect(copy.goals, equals(newGoals));
        expect(copy.age, equals(testProfile.age));
      });

      test('creates copy with updated calorie target', () {
        final copy = testProfile.copyWith(dailyCalorieTarget: 2500);

        expect(copy.dailyCalorieTarget, equals(2500));
        expect(copy.weight, equals(testProfile.weight));
      });

      test('creates copy with updated survey status', () {
        final copy = testProfile.copyWith(surveyCompleted: false);

        expect(copy.surveyCompleted, isFalse);
        expect(copy.age, equals(testProfile.age));
      });

      test('creates copy with updated activity level', () {
        final copy = testProfile.copyWith(activityLevel: 'very_active');

        expect(copy.activityLevel, equals('very_active'));
        expect(copy.age, equals(testProfile.age));
      });

      test('creates copy with updated full name', () {
        final copy = testProfile.copyWith(fullName: 'Jane Doe');

        expect(copy.fullName, equals('Jane Doe'));
        expect(copy.userId, equals(testProfile.userId));
      });

      test('creates copy with updated gender', () {
        final copy = testProfile.copyWith(gender: 'female');

        expect(copy.gender, equals('female'));
        expect(copy.age, equals(testProfile.age));
      });

      test('creates copy with multiple updated fields', () {
        final copy = testProfile.copyWith(
          age: 32,
          weight: 78.0,
          dailyCalorieTarget: 2200,
        );

        expect(copy.age, equals(32));
        expect(copy.weight, equals(78.0));
        expect(copy.dailyCalorieTarget, equals(2200));
        expect(copy.userId, equals(testProfile.userId));
      });

      test('returns same values when no parameters provided', () {
        final copy = testProfile.copyWith();

        expect(copy.userId, equals(testProfile.userId));
        expect(copy.age, equals(testProfile.age));
        expect(copy.weight, equals(testProfile.weight));
        expect(copy.goals, equals(testProfile.goals));
      });
    });

    group('Equality', () {
      test('two profiles with same values are equal', () {
        const profile1 = UserProfile(
          userId: 'user_123',
          fullName: 'John Doe',
          age: 30,
          gender: 'male',
          weight: 75.0,
          height: 180.0,
          activityLevel: 'moderate',
          goals: ['weight_loss', 'muscle_gain'],
          dailyCalorieTarget: 2000,
          surveyCompleted: true,
        );
        const profile2 = UserProfile(
          userId: 'user_123',
          fullName: 'John Doe',
          age: 30,
          gender: 'male',
          weight: 75.0,
          height: 180.0,
          activityLevel: 'moderate',
          goals: ['weight_loss', 'muscle_gain'],
          dailyCalorieTarget: 2000,
          surveyCompleted: true,
        );

        expect(profile1, equals(profile2));
        expect(profile1.hashCode, equals(profile2.hashCode));
      });

      test('two profiles with different userId are not equal', () {
        final profile2 = testProfile.copyWith(userId: 'user_456');

        expect(testProfile, isNot(equals(profile2)));
      });

      test('two profiles with different age are not equal', () {
        final profile2 = testProfile.copyWith(age: 31);

        expect(testProfile, isNot(equals(profile2)));
      });

      test('two profiles with different goals are not equal', () {
        final profile2 = testProfile.copyWith(goals: ['endurance']);

        expect(testProfile, isNot(equals(profile2)));
      });

      test('two profiles with different goal order are not equal', () {
        const profile1 = UserProfile(
          userId: 'user_1',
          fullName: 'Test',
          age: 30,
          gender: 'male',
          weight: 75.0,
          height: 180.0,
          activityLevel: 'moderate',
          goals: ['goal_a', 'goal_b'],
          dailyCalorieTarget: 2000,
          surveyCompleted: true,
        );
        const profile2 = UserProfile(
          userId: 'user_1',
          fullName: 'Test',
          age: 30,
          gender: 'male',
          weight: 75.0,
          height: 180.0,
          activityLevel: 'moderate',
          goals: ['goal_b', 'goal_a'],
          dailyCalorieTarget: 2000,
          surveyCompleted: true,
        );

        expect(profile1, isNot(equals(profile2)));
      });

      test('profile is equal to itself', () {
        expect(testProfile, equals(testProfile));
      });
    });

    group('toString', () {
      test('includes all fields in string representation', () {
        final string = testProfile.toString();

        expect(string, contains('UserProfile'));
        expect(string, contains('user_123'));
        expect(string, contains('John Doe'));
        expect(string, contains('30'));
        expect(string, contains('75.0'));
        expect(string, contains('180.0'));
        expect(string, contains('moderate'));
        expect(string, contains('2000'));
      });

      test('includes goals list', () {
        final string = testProfile.toString();

        expect(string, contains('weight_loss'));
        expect(string, contains('muscle_gain'));
      });

      test('shows survey completion status', () {
        final string = testProfile.toString();

        expect(string, contains('true'));
      });
    });

    group('Edge Cases', () {
      test('handles zero age', () {
        final profile = testProfile.copyWith(age: 0);

        expect(profile.age, equals(0));
      });

      test('handles very high age', () {
        final profile = testProfile.copyWith(age: 150);

        expect(profile.age, equals(150));
      });

      test('handles zero weight', () {
        final profile = testProfile.copyWith(weight: 0.0);

        expect(profile.weight, equals(0.0));
      });

      test('handles very high weight', () {
        final profile = testProfile.copyWith(weight: 300.0);

        expect(profile.weight, equals(300.0));
      });

      test('handles decimal weight values', () {
        final profile = testProfile.copyWith(weight: 75.5);

        expect(profile.weight, equals(75.5));
      });

      test('handles zero height', () {
        final profile = testProfile.copyWith(height: 0.0);

        expect(profile.height, equals(0.0));
      });

      test('handles very high height', () {
        final profile = testProfile.copyWith(height: 250.0);

        expect(profile.height, equals(250.0));
      });

      test('handles zero calorie target', () {
        final profile = testProfile.copyWith(dailyCalorieTarget: 0);

        expect(profile.dailyCalorieTarget, equals(0));
      });

      test('handles very high calorie target', () {
        final profile = testProfile.copyWith(dailyCalorieTarget: 10000);

        expect(profile.dailyCalorieTarget, equals(10000));
      });

      test('handles empty full name', () {
        final profile = testProfile.copyWith(fullName: '');

        expect(profile.fullName, equals(''));
      });

      test('handles very long full name', () {
        final longName = 'A' * 200;
        final profile = testProfile.copyWith(fullName: longName);

        expect(profile.fullName, equals(longName));
        expect(profile.fullName.length, equals(200));
      });

      test('handles empty goals list', () {
        final profile = testProfile.copyWith(goals: []);

        expect(profile.goals, isEmpty);
      });

      test('handles many goals', () {
        final manyGoals = List.generate(20, (i) => 'goal_$i');
        final profile = testProfile.copyWith(goals: manyGoals);

        expect(profile.goals.length, equals(20));
      });

      test('handles special characters in name', () {
        final profile = testProfile.copyWith(fullName: "O'Malley-Smith");

        expect(profile.fullName, equals("O'Malley-Smith"));
      });

      test('handles unicode characters in name', () {
        final profile = testProfile.copyWith(fullName: 'José María');

        expect(profile.fullName, equals('José María'));
      });
    });

    group('Real-world Scenarios', () {
      test('tracks weight loss progress', () {
        final week1 = testProfile;
        final week2 = week1.copyWith(weight: 74.5);
        final week3 = week2.copyWith(weight: 74.0);

        expect(week1.weight, equals(75.0));
        expect(week2.weight, equals(74.5));
        expect(week3.weight, equals(74.0));
      });

      test('updates goals as user progresses', () {
        final initial = testProfile.copyWith(goals: ['weight_loss']);
        final intermediate = initial.copyWith(
          goals: ['weight_loss', 'muscle_gain'],
        );
        final advanced = intermediate.copyWith(
          goals: ['maintenance', 'muscle_gain', 'endurance'],
        );

        expect(initial.goals.length, equals(1));
        expect(intermediate.goals.length, equals(2));
        expect(advanced.goals.length, equals(3));
      });

      test('adjusts calorie target based on activity level', () {
        final sedentary = testProfile.copyWith(
          activityLevel: 'sedentary',
          dailyCalorieTarget: 1800,
        );
        final active = sedentary.copyWith(
          activityLevel: 'active',
          dailyCalorieTarget: 2400,
        );

        expect(
          sedentary.dailyCalorieTarget,
          lessThan(active.dailyCalorieTarget),
        );
      });

      test('marks survey as completed', () {
        const incomplete = UserProfile(
          userId: 'user_1',
          fullName: 'Test',
          age: 25,
          gender: 'female',
          weight: 60.0,
          height: 165.0,
          activityLevel: 'moderate',
          goals: [],
          dailyCalorieTarget: 1800,
          surveyCompleted: false,
        );
        final completed = incomplete.copyWith(
          surveyCompleted: true,
          goals: ['weight_loss'],
        );

        expect(incomplete.surveyCompleted, isFalse);
        expect(completed.surveyCompleted, isTrue);
      });
    });
  });
}
