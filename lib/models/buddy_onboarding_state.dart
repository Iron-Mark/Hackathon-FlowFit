/// Buddy onboarding state model (Whale-themed)
///
/// Manages temporary onboarding data before final profile creation.
/// This state is used during the 9-screen whale-themed onboarding flow
/// to collect user choices before persisting them to the database.
class BuddyOnboardingState {
  /// Current step in onboarding (0-8 for 9 screens)
  final int currentStep;

  /// User's name (entered in step 2)
  final String? userName;

  /// Selected Buddy color (e.g., 'blue', 'green', 'purple')
  final String? selectedColor;

  /// Buddy name chosen by the user
  final String? buddyName;

  /// User's nickname (optional)
  final String? userNickname;

  /// User's age (optional, 7-12 for kids)
  final int? userAge;

  /// Selected wellness goals (from step 6)
  final List<String> selectedGoals;

  /// Whether notifications permission was granted
  final bool notificationsGranted;

  /// Whether the onboarding flow is complete
  final bool isComplete;

  const BuddyOnboardingState({
    this.currentStep = 0,
    this.userName,
    this.selectedColor,
    this.buddyName,
    this.userNickname,
    this.userAge,
    this.selectedGoals = const [],
    this.notificationsGranted = false,
    this.isComplete = false,
  });

  /// Creates a copy of this state with updated fields
  BuddyOnboardingState copyWith({
    int? currentStep,
    String? userName,
    String? selectedColor,
    String? buddyName,
    String? userNickname,
    int? userAge,
    List<String>? selectedGoals,
    bool? notificationsGranted,
    bool? isComplete,
  }) {
    return BuddyOnboardingState(
      currentStep: currentStep ?? this.currentStep,
      userName: userName ?? this.userName,
      selectedColor: selectedColor ?? this.selectedColor,
      buddyName: buddyName ?? this.buddyName,
      userNickname: userNickname ?? this.userNickname,
      userAge: userAge ?? this.userAge,
      selectedGoals: selectedGoals ?? this.selectedGoals,
      notificationsGranted: notificationsGranted ?? this.notificationsGranted,
      isComplete: isComplete ?? this.isComplete,
    );
  }

  /// Get progress (0.0 to 1.0)
  double get progress => (currentStep + 1) / 9;

  @override
  String toString() {
    return 'BuddyOnboardingState('
        'currentStep: $currentStep, '
        'userName: $userName, '
        'selectedColor: $selectedColor, '
        'buddyName: $buddyName, '
        'userNickname: $userNickname, '
        'userAge: $userAge, '
        'selectedGoals: $selectedGoals, '
        'notificationsGranted: $notificationsGranted, '
        'isComplete: $isComplete)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BuddyOnboardingState &&
        other.currentStep == currentStep &&
        other.userName == userName &&
        other.selectedColor == selectedColor &&
        other.buddyName == buddyName &&
        other.userNickname == userNickname &&
        other.userAge == userAge &&
        other.selectedGoals == selectedGoals &&
        other.notificationsGranted == notificationsGranted &&
        other.isComplete == isComplete;
  }

  @override
  int get hashCode {
    return Object.hash(
      currentStep,
      userName,
      selectedColor,
      buddyName,
      userNickname,
      userAge,
      Object.hashAll(selectedGoals),
      notificationsGranted,
      isComplete,
    );
  }
}
