/// User profile entity containing all user information
///
/// This model represents the complete user profile including data
/// collected during onboarding and any subsequent updates.
class UserProfile {
  final String userId;
  final String? fullName;
  final int? age;
  final String? gender;
  final double? height;
  final double? weight;
  final String? heightUnit;
  final String? weightUnit;
  final String? activityLevel;
  final List<String>? goals;
  final List<String>? wellnessGoals; // Whale onboarding wellness goals
  final bool? notificationsEnabled; // Whale onboarding notification preference
  final int? dailyCalorieTarget;
  final int? dailyStepsTarget;
  final int? dailyActiveMinutesTarget;
  final double? dailyWaterTarget;
  final String? profileImagePath;
  final String? nickname;
  final bool isKidsMode;
  final bool surveyCompleted;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSynced;

  const UserProfile({
    required this.userId,
    this.fullName,
    this.age,
    this.gender,
    this.height,
    this.weight,
    this.heightUnit,
    this.weightUnit,
    this.activityLevel,
    this.goals,
    this.wellnessGoals,
    this.notificationsEnabled,
    this.dailyCalorieTarget,
    this.dailyStepsTarget,
    this.dailyActiveMinutesTarget,
    this.dailyWaterTarget,
    this.profileImagePath,
    this.nickname,
    this.isKidsMode = true,
    this.surveyCompleted = false,
    required this.createdAt,
    required this.updatedAt,
    this.isSynced = false,
  });

  /// Create UserProfile from JSON
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      userId: json['userId'] as String? ?? json['user_id'] as String,
      fullName: json['fullName'] as String? ?? json['full_name'] as String?,
      age: json['age'] as int?,
      gender: json['gender'] as String?,
      height: (json['height'] as num?)?.toDouble(),
      weight: (json['weight'] as num?)?.toDouble(),
      heightUnit:
          json['heightUnit'] as String? ?? json['height_unit'] as String?,
      weightUnit:
          json['weightUnit'] as String? ?? json['weight_unit'] as String?,
      activityLevel:
          json['activityLevel'] as String? ?? json['activity_level'] as String?,
      goals: (json['goals'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      wellnessGoals:
          (json['wellnessGoals'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          (json['wellness_goals'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList(),
      notificationsEnabled:
          json['notificationsEnabled'] as bool? ??
          json['notifications_enabled'] as bool?,
      dailyCalorieTarget:
          json['dailyCalorieTarget'] as int? ??
          json['daily_calorie_target'] as int?,
      dailyStepsTarget:
          json['dailyStepsTarget'] as int? ??
          json['daily_steps_target'] as int?,
      dailyActiveMinutesTarget:
          json['dailyActiveMinutesTarget'] as int? ??
          json['daily_active_minutes_target'] as int?,
      dailyWaterTarget:
          (json['dailyWaterTarget'] as num?)?.toDouble() ??
          (json['daily_water_target'] as num?)?.toDouble(),
      profileImagePath:
          json['profileImagePath'] as String? ??
          json['profile_image_url'] as String?,
      nickname: json['nickname'] as String?,
      isKidsMode:
          json['isKidsMode'] as bool? ?? json['is_kids_mode'] as bool? ?? false,
      surveyCompleted:
          json['surveyCompleted'] as bool? ??
          json['survey_completed'] as bool? ??
          false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : (json['created_at'] != null
                ? DateTime.parse(json['created_at'] as String)
                : DateTime.now()),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : (json['updated_at'] != null
                ? DateTime.parse(json['updated_at'] as String)
                : DateTime.now()),
      isSynced:
          json['isSynced'] as bool? ?? json['is_synced'] as bool? ?? false,
    );
  }

  /// Convert UserProfile to JSON (camelCase for local storage)
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'fullName': fullName,
      'age': age,
      'gender': gender,
      'height': height,
      'weight': weight,
      'heightUnit': heightUnit,
      'weightUnit': weightUnit,
      'activityLevel': activityLevel,
      'goals': goals,
      'wellnessGoals': wellnessGoals,
      'notificationsEnabled': notificationsEnabled,
      'dailyCalorieTarget': dailyCalorieTarget,
      'dailyStepsTarget': dailyStepsTarget,
      'dailyActiveMinutesTarget': dailyActiveMinutesTarget,
      'dailyWaterTarget': dailyWaterTarget,
      'profileImagePath': profileImagePath,
      'nickname': nickname,
      'isKidsMode': isKidsMode,
      'surveyCompleted': surveyCompleted,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isSynced': isSynced,
    };
  }

  /// Convert to Supabase format (snake_case)
  Map<String, dynamic> toSupabaseJson() {
    return {
      'user_id': userId,
      'full_name': fullName,
      'age': age,
      'gender': gender,
      'height': height,
      'weight': weight,
      'height_unit': heightUnit,
      'weight_unit': weightUnit,
      'activity_level': activityLevel,
      'goals': goals,
      'wellness_goals': wellnessGoals,
      'notifications_enabled': notificationsEnabled ?? false,
      'daily_calorie_target': dailyCalorieTarget,
      'daily_steps_target': dailyStepsTarget,
      'daily_active_minutes_target': dailyActiveMinutesTarget,
      'daily_water_target': dailyWaterTarget,
      'profile_image_url': profileImagePath,
      'nickname': nickname,
      'is_kids_mode': isKidsMode,
      'survey_completed': surveyCompleted,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Create UserProfile from survey data
  factory UserProfile.fromSurveyData(
    String userId,
    Map<String, dynamic> surveyData,
  ) {
    final now = DateTime.now();
    return UserProfile(
      userId: userId,
      fullName: surveyData['fullName'] as String?,
      age: surveyData['age'] as int?,
      gender: surveyData['gender'] as String?,
      height: (surveyData['height'] as num?)?.toDouble(),
      weight: (surveyData['weight'] as num?)?.toDouble(),
      heightUnit: 'cm', // Default from survey
      weightUnit: 'kg', // Default from survey
      activityLevel: surveyData['activityLevel'] as String?,
      goals: (surveyData['goals'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      dailyCalorieTarget: surveyData['dailyCalorieTarget'] as int?,
      dailyStepsTarget: surveyData['dailyStepsTarget'] as int?,
      dailyActiveMinutesTarget: surveyData['dailyActiveMinutesTarget'] as int?,
      dailyWaterTarget: (surveyData['dailyWaterTarget'] as num?)?.toDouble(),
      surveyCompleted: true,
      createdAt: now,
      updatedAt: now,
      isSynced: false,
    );
  }

  /// Create UserProfile with default values
  factory UserProfile.withDefaults(String userId) {
    final now = DateTime.now();
    return UserProfile(
      userId: userId,
      createdAt: now,
      updatedAt: now,
      isSynced: false,
    );
  }

  /// Create a copy with updated fields
  UserProfile copyWith({
    String? userId,
    String? fullName,
    int? age,
    String? gender,
    double? height,
    double? weight,
    String? heightUnit,
    String? weightUnit,
    String? activityLevel,
    List<String>? goals,
    List<String>? wellnessGoals,
    bool? notificationsEnabled,
    int? dailyCalorieTarget,
    int? dailyStepsTarget,
    int? dailyActiveMinutesTarget,
    double? dailyWaterTarget,
    String? profileImagePath,
    String? nickname,
    bool? isKidsMode,
    bool? surveyCompleted,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSynced,
  }) {
    return UserProfile(
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      heightUnit: heightUnit ?? this.heightUnit,
      weightUnit: weightUnit ?? this.weightUnit,
      activityLevel: activityLevel ?? this.activityLevel,
      goals: goals ?? this.goals,
      wellnessGoals: wellnessGoals ?? this.wellnessGoals,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      dailyCalorieTarget: dailyCalorieTarget ?? this.dailyCalorieTarget,
      dailyStepsTarget: dailyStepsTarget ?? this.dailyStepsTarget,
      dailyActiveMinutesTarget:
          dailyActiveMinutesTarget ?? this.dailyActiveMinutesTarget,
      dailyWaterTarget: dailyWaterTarget ?? this.dailyWaterTarget,
      profileImagePath: profileImagePath ?? this.profileImagePath,
      nickname: nickname ?? this.nickname,
      isKidsMode: isKidsMode ?? this.isKidsMode,
      surveyCompleted: surveyCompleted ?? this.surveyCompleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  /// Validate profile data
  String? validate() {
    if (age != null && (age! < 7 || age! > 120)) {
      return 'Age must be between 7 and 120';
    }
    if (gender != null && !['male', 'female', 'other'].contains(gender)) {
      return 'Invalid gender value';
    }
    if (height != null && height! <= 0) {
      return 'Height must be positive';
    }
    if (weight != null && weight! <= 0) {
      return 'Weight must be positive';
    }
    return null;
  }

  /// Check if profile is complete
  bool get isComplete {
    return fullName != null &&
        age != null &&
        gender != null &&
        height != null &&
        weight != null &&
        activityLevel != null &&
        goals != null &&
        goals!.isNotEmpty;
  }

  /// Get completion percentage
  double get completionPercentage {
    int totalFields =
        7; // fullName, age, gender, height, weight, activityLevel, goals
    int completedFields = 0;

    if (fullName != null) completedFields++;
    if (age != null) completedFields++;
    if (gender != null) completedFields++;
    if (height != null) completedFields++;
    if (weight != null) completedFields++;
    if (activityLevel != null) completedFields++;
    if (goals != null && goals!.isNotEmpty) completedFields++;

    return completedFields / totalFields;
  }

  @override
  String toString() {
    return 'UserProfile(userId: $userId, fullName: $fullName, age: $age, surveyCompleted: $surveyCompleted, isSynced: $isSynced)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserProfile &&
        other.userId == userId &&
        other.fullName == fullName &&
        other.age == age &&
        other.gender == gender &&
        other.height == height &&
        other.weight == weight &&
        other.surveyCompleted == surveyCompleted &&
        other.isSynced == isSynced;
  }

  @override
  int get hashCode {
    return Object.hash(
      userId,
      fullName,
      age,
      gender,
      height,
      weight,
      surveyCompleted,
      isSynced,
    );
  }
}
