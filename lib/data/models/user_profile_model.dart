import '../../domain/entities/user_profile.dart';

/// Data model for UserProfile that maps to/from Supabase Database.
/// Handles JSON serialization for database operations.
class UserProfileModel {
  final String userId;
  final String fullName;
  final int age;
  final String gender;
  final double weight;
  final double height;
  final String activityLevel;
  final List<String> goals;
  final int dailyCalorieTarget;
  final bool surveyCompleted;
  final String createdAt;
  final String updatedAt;
  final String? heightUnit;
  final String? weightUnit;
  final int? dailyStepsTarget;
  final int? dailyActiveMinutesTarget;
  final double? dailyWaterTarget;
  final String? profileImageUrl;

  const UserProfileModel({
    required this.userId,
    required this.fullName,
    required this.age,
    required this.gender,
    required this.weight,
    required this.height,
    required this.activityLevel,
    required this.goals,
    required this.dailyCalorieTarget,
    required this.surveyCompleted,
    required this.createdAt,
    required this.updatedAt,
    this.heightUnit,
    this.weightUnit,
    this.dailyStepsTarget,
    this.dailyActiveMinutesTarget,
    this.dailyWaterTarget,
    this.profileImageUrl,
  });

  /// Creates a UserProfileModel from JSON data received from Supabase.
  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    final nickname = json['nickname'] as String?;
    return UserProfileModel(
      userId: json['user_id'] as String,
      fullName: (json['full_name'] as String?) ?? nickname ?? '',
      age: _readInt(json['age']) ?? 0,
      gender: (json['gender'] as String?) ?? '',
      weight: _readDouble(json['weight']) ?? 0,
      height: _readDouble(json['height']) ?? 0,
      activityLevel: (json['activity_level'] as String?) ?? '',
      goals: _readStringList(json['goals']),
      dailyCalorieTarget: _readInt(json['daily_calorie_target']) ?? 0,
      surveyCompleted: (json['survey_completed'] as bool?) ?? false,
      createdAt: (json['created_at'] as String?) ?? '',
      updatedAt: (json['updated_at'] as String?) ?? '',
      heightUnit: json['height_unit'] as String?,
      weightUnit: json['weight_unit'] as String?,
      dailyStepsTarget: _readInt(json['daily_steps_target']),
      dailyActiveMinutesTarget: _readInt(json['daily_active_minutes_target']),
      dailyWaterTarget: _readDouble(json['daily_water_target']),
      profileImageUrl: json['profile_image_url'] as String?,
    );
  }

  /// Converts this UserProfileModel to JSON for sending to Supabase.
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'full_name': fullName,
      'age': age,
      'gender': gender,
      'weight': weight,
      'height': height,
      'activity_level': activityLevel,
      'goals': goals,
      'daily_calorie_target': dailyCalorieTarget,
      'survey_completed': surveyCompleted,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'height_unit': heightUnit,
      'weight_unit': weightUnit,
      'daily_steps_target': dailyStepsTarget,
      'daily_active_minutes_target': dailyActiveMinutesTarget,
      'daily_water_target': dailyWaterTarget,
      'profile_image_url': profileImageUrl,
    };
  }

  /// Converts this data model to a domain entity.
  UserProfile toDomain() {
    return UserProfile(
      userId: userId,
      fullName: fullName,
      age: age,
      gender: gender,
      weight: weight,
      height: height,
      activityLevel: activityLevel,
      goals: goals,
      dailyCalorieTarget: dailyCalorieTarget,
      surveyCompleted: surveyCompleted,
      heightUnit: heightUnit,
      weightUnit: weightUnit,
      dailyStepsTarget: dailyStepsTarget,
      dailyActiveMinutesTarget: dailyActiveMinutesTarget,
      dailyWaterTarget: dailyWaterTarget,
      profileImageUrl: profileImageUrl,
    );
  }

  /// Creates a UserProfileModel from a domain entity.
  /// Uses current timestamp for createdAt and updatedAt if not provided.
  factory UserProfileModel.fromDomain(UserProfile profile) {
    final now = DateTime.now().toIso8601String();
    return UserProfileModel(
      userId: profile.userId,
      fullName: profile.fullName,
      age: profile.age,
      gender: profile.gender,
      weight: profile.weight,
      height: profile.height,
      activityLevel: profile.activityLevel,
      goals: profile.goals,
      dailyCalorieTarget: profile.dailyCalorieTarget,
      surveyCompleted: profile.surveyCompleted,
      createdAt: now,
      updatedAt: now,
      heightUnit: profile.heightUnit,
      weightUnit: profile.weightUnit,
      dailyStepsTarget: profile.dailyStepsTarget,
      dailyActiveMinutesTarget: profile.dailyActiveMinutesTarget,
      dailyWaterTarget: profile.dailyWaterTarget,
      profileImageUrl: profile.profileImageUrl,
    );
  }
}

int? _readInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return null;
}

double? _readDouble(Object? value) {
  if (value is num) return value.toDouble();
  return null;
}

List<String> _readStringList(Object? value) {
  if (value is List) {
    return value.whereType<String>().toList();
  }
  return const [];
}
