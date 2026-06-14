import 'package:flowfit/data/models/user_profile_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses Buddy-created partial profile rows without throwing', () {
    final model = UserProfileModel.fromJson({
      'user_id': 'auth-user-id',
      'nickname': 'Kid',
      'is_kids_mode': true,
      'wellness_goals': ['move_more'],
      'notifications_enabled': true,
      'survey_completed': false,
      'created_at': '2026-06-14T00:00:00.000Z',
      'updated_at': '2026-06-14T00:00:00.000Z',
    });

    expect(model.userId, 'auth-user-id');
    expect(model.fullName, 'Kid');
    expect(model.age, 0);
    expect(model.gender, '');
    expect(model.weight, 0);
    expect(model.height, 0);
    expect(model.activityLevel, '');
    expect(model.goals, isEmpty);
    expect(model.dailyCalorieTarget, 0);
    expect(model.surveyCompleted, isFalse);
    expect(model.toDomain().fullName, 'Kid');
  });
}
