import 'package:flutter_test/flutter_test.dart';
import 'package:flowfit/core/domain/entities/user_profile.dart';

void main() {
  group('UserProfile', () {
    final now = DateTime(2024, 1, 1, 12, 0, 0);

    group('Constructor', () {
      test('creates instance with all fields', () {
        final profile = UserProfile(
          userId: 'user-123',
          fullName: 'John Doe',
          age: 30,
          gender: 'male',
          height: 180.0,
          weight: 75.0,
          heightUnit: 'cm',
          weightUnit: 'kg',
          activityLevel: 'moderately_active',
          goals: ['lose_weight', 'improve_cardio'],
          dailyCalorieTarget: 2000,
          dailyStepsTarget: 10000,
          dailyActiveMinutesTarget: 30,
          dailyWaterTarget: 2.5,
          profileImagePath: '/path/to/image.jpg',
          createdAt: now,
          updatedAt: now,
          isSynced: true,
        );

        expect(profile.userId, 'user-123');
        expect(profile.fullName, 'John Doe');
        expect(profile.age, 30);
        expect(profile.gender, 'male');
        expect(profile.height, 180.0);
        expect(profile.weight, 75.0);
        expect(profile.heightUnit, 'cm');
        expect(profile.weightUnit, 'kg');
        expect(profile.activityLevel, 'moderately_active');
        expect(profile.goals, ['lose_weight', 'improve_cardio']);
        expect(profile.dailyCalorieTarget, 2000);
        expect(profile.dailyStepsTarget, 10000);
        expect(profile.dailyActiveMinutesTarget, 30);
        expect(profile.dailyWaterTarget, 2.5);
        expect(profile.profileImagePath, '/path/to/image.jpg');
        expect(profile.createdAt, now);
        expect(profile.updatedAt, now);
        expect(profile.isSynced, true);
      });

      test('creates instance with minimal fields', () {
        final profile = UserProfile(
          userId: 'user-123',
          createdAt: now,
          updatedAt: now,
        );

        expect(profile.userId, 'user-123');
        expect(profile.fullName, isNull);
        expect(profile.age, isNull);
        expect(profile.isSynced, false);
      });
    });

    group('fromJson', () {
      test('creates instance from camelCase JSON', () {
        final json = {
          'userId': 'user-123',
          'fullName': 'Jane Doe',
          'age': 25,
          'gender': 'female',
          'height': 165.0,
          'weight': 60.0,
          'heightUnit': 'cm',
          'weightUnit': 'kg',
          'activityLevel': 'very_active',
          'goals': ['build_muscle', 'improve_cardio'],
          'dailyCalorieTarget': 2200,
          'dailyStepsTarget': 12000,
          'dailyActiveMinutesTarget': 45,
          'dailyWaterTarget': 3.0,
          'profileImagePath': '/path/to/image.jpg',
          'createdAt': '2024-01-01T12:00:00.000',
          'updatedAt': '2024-01-01T12:00:00.000',
          'isSynced': true,
        };

        final profile = UserProfile.fromJson(json);

        expect(profile.userId, 'user-123');
        expect(profile.fullName, 'Jane Doe');
        expect(profile.age, 25);
        expect(profile.gender, 'female');
        expect(profile.height, 165.0);
        expect(profile.weight, 60.0);
        expect(profile.isSynced, true);
      });

      test('creates instance from snake_case JSON (Supabase format)', () {
        final json = {
          'user_id': 'user-456',
          'full_name': 'Bob Smith',
          'age': 35,
          'gender': 'male',
          'height': 175.0,
          'weight': 80.0,
          'height_unit': 'cm',
          'weight_unit': 'kg',
          'activity_level': 'sedentary',
          'goals': ['lose_weight'],
          'daily_calorie_target': 1800,
          'daily_steps_target': 8000,
          'daily_active_minutes_target': 20,
          'daily_water_target': 2.0,
          'profile_image_url': '/path/to/image.jpg',
          'created_at': '2024-01-01T12:00:00.000',
          'updated_at': '2024-01-01T12:00:00.000',
          'is_synced': false,
        };

        final profile = UserProfile.fromJson(json);

        expect(profile.userId, 'user-456');
        expect(profile.fullName, 'Bob Smith');
        expect(profile.age, 35);
        expect(profile.activityLevel, 'sedentary');
        expect(profile.isSynced, false);
      });

      test('handles missing optional fields', () {
        final json = {
          'userId': 'user-789',
          'createdAt': '2024-01-01T12:00:00.000',
          'updatedAt': '2024-01-01T12:00:00.000',
        };

        final profile = UserProfile.fromJson(json);

        expect(profile.userId, 'user-789');
        expect(profile.fullName, isNull);
        expect(profile.age, isNull);
        expect(profile.gender, isNull);
        expect(profile.goals, isNull);
        expect(profile.isSynced, false);
      });

      test('handles numeric types correctly', () {
        final json = {
          'userId': 'user-123',
          'height': 180, // int instead of double
          'weight': 75, // int instead of double
          'dailyWaterTarget': 2, // int instead of double
          'createdAt': '2024-01-01T12:00:00.000',
          'updatedAt': '2024-01-01T12:00:00.000',
        };

        final profile = UserProfile.fromJson(json);

        expect(profile.height, 180.0);
        expect(profile.weight, 75.0);
        expect(profile.dailyWaterTarget, 2.0);
      });
    });

    group('toJson', () {
      test('converts to camelCase JSON', () {
        final profile = UserProfile(
          userId: 'user-123',
          fullName: 'John Doe',
          age: 30,
          gender: 'male',
          height: 180.0,
          weight: 75.0,
          heightUnit: 'cm',
          weightUnit: 'kg',
          activityLevel: 'moderately_active',
          goals: ['lose_weight'],
          dailyCalorieTarget: 2000,
          dailyStepsTarget: 10000,
          dailyActiveMinutesTarget: 30,
          dailyWaterTarget: 2.5,
          createdAt: now,
          updatedAt: now,
          isSynced: true,
        );

        final json = profile.toJson();

        expect(json['userId'], 'user-123');
        expect(json['fullName'], 'John Doe');
        expect(json['age'], 30);
        expect(json['heightUnit'], 'cm');
        expect(json['activityLevel'], 'moderately_active');
        expect(json['isSynced'], true);
      });

      test('includes null values', () {
        final profile = UserProfile(
          userId: 'user-123',
          createdAt: now,
          updatedAt: now,
        );

        final json = profile.toJson();

        expect(json['fullName'], isNull);
        expect(json['age'], isNull);
        expect(json['gender'], isNull);
      });
    });

    group('toSupabaseJson', () {
      test('converts to snake_case JSON', () {
        final profile = UserProfile(
          userId: 'user-123',
          fullName: 'John Doe',
          age: 30,
          gender: 'male',
          height: 180.0,
          weight: 75.0,
          heightUnit: 'cm',
          weightUnit: 'kg',
          activityLevel: 'moderately_active',
          goals: ['lose_weight'],
          dailyCalorieTarget: 2000,
          dailyStepsTarget: 10000,
          dailyActiveMinutesTarget: 30,
          dailyWaterTarget: 2.5,
          profileImagePath: '/path/to/image.jpg',
          createdAt: now,
          updatedAt: now,
        );

        final json = profile.toSupabaseJson();

        expect(json['user_id'], 'user-123');
        expect(json['full_name'], 'John Doe');
        expect(json['age'], 30);
        expect(json['height_unit'], 'cm');
        expect(json['activity_level'], 'moderately_active');
        expect(json['profile_image_url'], '/path/to/image.jpg');
        expect(json.containsKey('created_at'), false); // Not included
      });

      test('defaults required Supabase notification flag when unset', () {
        final profile = UserProfile(
          userId: 'user-123',
          createdAt: now,
          updatedAt: now,
        );

        final json = profile.toSupabaseJson();

        expect(json['notifications_enabled'], isFalse);
      });
    });

    group('fromSurveyData', () {
      test('creates profile from survey data', () {
        final surveyData = {
          'fullName': 'Alice Johnson',
          'age': 28,
          'gender': 'female',
          'height': 170.0,
          'weight': 65.0,
          'heightUnit': 'ft',
          'weightUnit': 'lbs',
          'activityLevel': 'moderately_active',
          'goals': ['maintain_weight', 'improve_cardio'],
          'dailyCalorieTarget': 1900,
          'dailyStepsTarget': 9000,
          'dailyActiveMinutesTarget': 25,
          'dailyWaterTarget': 2.2,
        };

        final profile = UserProfile.fromSurveyData('user-123', surveyData);

        expect(profile.userId, 'user-123');
        expect(profile.fullName, 'Alice Johnson');
        expect(profile.age, 28);
        expect(profile.gender, 'female');
        expect(profile.height, 170.0);
        expect(profile.weight, 65.0);
        expect(profile.heightUnit, 'ft');
        expect(profile.weightUnit, 'lbs');
        expect(profile.activityLevel, 'moderately_active');
        expect(profile.goals, ['maintain_weight', 'improve_cardio']);
        expect(profile.isSynced, false);
        expect(profile.toSupabaseJson()['survey_completed'], isTrue);
      });

      test('defaults survey units when no unit selection is present', () {
        final surveyData = {
          'fullName': 'Default Units',
          'height': 170.0,
          'weight': 65.0,
        };

        final profile = UserProfile.fromSurveyData('user-789', surveyData);

        expect(profile.heightUnit, 'cm');
        expect(profile.weightUnit, 'kg');
      });

      test('handles partial survey data', () {
        final surveyData = {'fullName': 'Bob', 'age': 40};

        final profile = UserProfile.fromSurveyData('user-456', surveyData);

        expect(profile.userId, 'user-456');
        expect(profile.fullName, 'Bob');
        expect(profile.age, 40);
        expect(profile.gender, isNull);
        expect(profile.goals, isNull);
      });
    });

    group('withDefaults', () {
      test('creates profile with default values', () {
        final profile = UserProfile.withDefaults('user-123');

        expect(profile.userId, 'user-123');
        expect(profile.fullName, isNull);
        expect(profile.age, isNull);
        expect(profile.isSynced, false);
        expect(profile.createdAt, isNotNull);
        expect(profile.updatedAt, isNotNull);
      });
    });

    group('copyWith', () {
      test('creates copy with updated fields', () {
        final original = UserProfile(
          userId: 'user-123',
          fullName: 'John Doe',
          age: 30,
          createdAt: now,
          updatedAt: now,
          isSynced: false,
        );

        final updated = original.copyWith(
          fullName: 'Jane Doe',
          age: 31,
          isSynced: true,
        );

        expect(updated.userId, 'user-123');
        expect(updated.fullName, 'Jane Doe');
        expect(updated.age, 31);
        expect(updated.isSynced, true);
        expect(updated.createdAt, now);
      });

      test('preserves original values when not specified', () {
        final original = UserProfile(
          userId: 'user-123',
          fullName: 'John Doe',
          age: 30,
          gender: 'male',
          createdAt: now,
          updatedAt: now,
        );

        final updated = original.copyWith(age: 31);

        expect(updated.fullName, 'John Doe');
        expect(updated.gender, 'male');
        expect(updated.age, 31);
      });
    });

    group('validate', () {
      test('returns null for valid profile', () {
        final profile = UserProfile(
          userId: 'user-123',
          age: 25,
          gender: 'male',
          height: 180.0,
          weight: 75.0,
          createdAt: now,
          updatedAt: now,
        );

        expect(profile.validate(), isNull);
      });

      test('returns null for lower-bound age', () {
        final profile = UserProfile(
          userId: 'user-123',
          age: 7,
          createdAt: now,
          updatedAt: now,
        );

        expect(profile.validate(), isNull);
      });

      test('returns error for age below 7', () {
        final profile = UserProfile(
          userId: 'user-123',
          age: 6,
          createdAt: now,
          updatedAt: now,
        );

        expect(profile.validate(), contains('Age must be between 7 and 120'));
      });

      test('returns error for age above 120', () {
        final profile = UserProfile(
          userId: 'user-123',
          age: 121,
          createdAt: now,
          updatedAt: now,
        );

        expect(profile.validate(), contains('Age must be between 7 and 120'));
      });

      test('returns error for invalid gender', () {
        final profile = UserProfile(
          userId: 'user-123',
          gender: 'invalid',
          createdAt: now,
          updatedAt: now,
        );

        expect(profile.validate(), contains('Invalid gender value'));
      });

      test('returns error for negative height', () {
        final profile = UserProfile(
          userId: 'user-123',
          height: -10.0,
          createdAt: now,
          updatedAt: now,
        );

        expect(profile.validate(), contains('Height must be positive'));
      });

      test('returns error for zero height', () {
        final profile = UserProfile(
          userId: 'user-123',
          height: 0.0,
          createdAt: now,
          updatedAt: now,
        );

        expect(profile.validate(), contains('Height must be positive'));
      });

      test('returns error for negative weight', () {
        final profile = UserProfile(
          userId: 'user-123',
          weight: -5.0,
          createdAt: now,
          updatedAt: now,
        );

        expect(profile.validate(), contains('Weight must be positive'));
      });
    });

    group('isComplete', () {
      test('returns true for complete profile', () {
        final profile = UserProfile(
          userId: 'user-123',
          fullName: 'John Doe',
          age: 30,
          gender: 'male',
          height: 180.0,
          weight: 75.0,
          activityLevel: 'moderately_active',
          goals: ['lose_weight'],
          createdAt: now,
          updatedAt: now,
        );

        expect(profile.isComplete, true);
      });

      test('returns false when missing fullName', () {
        final profile = UserProfile(
          userId: 'user-123',
          age: 30,
          gender: 'male',
          height: 180.0,
          weight: 75.0,
          activityLevel: 'moderately_active',
          goals: ['lose_weight'],
          createdAt: now,
          updatedAt: now,
        );

        expect(profile.isComplete, false);
      });

      test('returns false when goals is empty', () {
        final profile = UserProfile(
          userId: 'user-123',
          fullName: 'John Doe',
          age: 30,
          gender: 'male',
          height: 180.0,
          weight: 75.0,
          activityLevel: 'moderately_active',
          goals: [],
          createdAt: now,
          updatedAt: now,
        );

        expect(profile.isComplete, false);
      });
    });

    group('completionPercentage', () {
      test('returns 1.0 for complete profile', () {
        final profile = UserProfile(
          userId: 'user-123',
          fullName: 'John Doe',
          age: 30,
          gender: 'male',
          height: 180.0,
          weight: 75.0,
          activityLevel: 'moderately_active',
          goals: ['lose_weight'],
          createdAt: now,
          updatedAt: now,
        );

        expect(profile.completionPercentage, 1.0);
      });

      test('returns 0.0 for empty profile', () {
        final profile = UserProfile(
          userId: 'user-123',
          createdAt: now,
          updatedAt: now,
        );

        expect(profile.completionPercentage, 0.0);
      });

      test('returns correct percentage for partial profile', () {
        final profile = UserProfile(
          userId: 'user-123',
          fullName: 'John Doe',
          age: 30,
          gender: 'male',
          createdAt: now,
          updatedAt: now,
        );

        // 3 out of 7 fields: fullName, age, gender
        expect(profile.completionPercentage, closeTo(3 / 7, 0.01));
      });
    });

    group('equality', () {
      test('returns true for equal profiles', () {
        final profile1 = UserProfile(
          userId: 'user-123',
          fullName: 'John Doe',
          age: 30,
          gender: 'male',
          height: 180.0,
          weight: 75.0,
          isSynced: true,
          createdAt: now,
          updatedAt: now,
        );

        final profile2 = UserProfile(
          userId: 'user-123',
          fullName: 'John Doe',
          age: 30,
          gender: 'male',
          height: 180.0,
          weight: 75.0,
          isSynced: true,
          createdAt: now,
          updatedAt: now,
        );

        expect(profile1, equals(profile2));
      });

      test('returns false for different profiles', () {
        final profile1 = UserProfile(
          userId: 'user-123',
          fullName: 'John Doe',
          age: 30,
          createdAt: now,
          updatedAt: now,
        );

        final profile2 = UserProfile(
          userId: 'user-456',
          fullName: 'Jane Doe',
          age: 25,
          createdAt: now,
          updatedAt: now,
        );

        expect(profile1, isNot(equals(profile2)));
      });
    });

    group('hashCode', () {
      test('returns same hashCode for equal profiles', () {
        final profile1 = UserProfile(
          userId: 'user-123',
          fullName: 'John Doe',
          age: 30,
          createdAt: now,
          updatedAt: now,
        );

        final profile2 = UserProfile(
          userId: 'user-123',
          fullName: 'John Doe',
          age: 30,
          createdAt: now,
          updatedAt: now,
        );

        expect(profile1.hashCode, equals(profile2.hashCode));
      });
    });

    group('toString', () {
      test('returns readable string representation', () {
        final profile = UserProfile(
          userId: 'user-123',
          fullName: 'John Doe',
          age: 30,
          isSynced: true,
          createdAt: now,
          updatedAt: now,
        );

        final str = profile.toString();

        expect(str, contains('user-123'));
        expect(str, contains('John Doe'));
        expect(str, contains('30'));
        expect(str, contains('true'));
      });
    });
  });
}
