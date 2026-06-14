# Design Document: Supabase Authentication and Onboarding

## Overview

This design document outlines the implementation of a complete authentication and onboarding system for FlowFit using Supabase as the backend. The system will handle user registration, login, session management, and survey-based profile creation with data persistence. The architecture follows clean architecture principles with clear separation between UI, business logic, and data layers using Riverpod for state management.

### Key Features

- Email/password authentication via Supabase Auth
- Persistent session management with automatic re-authentication
- Multi-step survey flow for user profile creation
- Data persistence to Supabase database
- Comprehensive error handling and validation
- Clean architecture with repository pattern

### Supabase Configuration

- **Project URL**: `https://YOUR_PROJECT_REF.supabase.co`
- **Publishable Key**: `sb_publishable_YOUR_KEY`

## Architecture

### Layer Structure

```
┌─────────────────────────────────────────┐
│         Presentation Layer              │
│  (Screens, Widgets, Providers)          │
└─────────────────────────────────────────┘
                  ↓
┌─────────────────────────────────────────┐
│         Domain Layer                    │
│  (Entities, Use Cases, Interfaces)      │
└─────────────────────────────────────────┘
                  ↓
┌─────────────────────────────────────────┐
│         Data Layer                      │
│  (Repositories, Data Sources, Models)   │
└─────────────────────────────────────────┘
```

### State Management

The application uses Riverpod for state management with the following provider types:

- **StateNotifierProvider**: For authentication state and survey state
- **FutureProvider**: For async operations like profile loading
- **Provider**: For repository instances and configuration

### Authentication Flow

```mermaid
graph TD
    A[App Start] --> B{Session Exists?}
    B -->|Yes| C{Profile Complete?}
    B -->|No| D[Welcome Screen]
    C -->|Yes| E[Dashboard]
    C -->|No| F[Survey Flow]
    D --> G[Login/Signup]
    G --> H[Authenticate]
    H -->|Success| F
    F --> I[Save Profile]
    I --> E
```

## Components and Interfaces

### 1. Domain Layer

#### Entities

**User Entity**
```dart
class User {
  final String id;
  final String email;
  final String? fullName;
  final DateTime createdAt;
  
  User({
    required this.id,
    required this.email,
    this.fullName,
    required this.createdAt,
  });
}
```

**UserProfile Entity**
```dart
class UserProfile {
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
  
  UserProfile({
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
  });
}
```

**AuthState Entity**
```dart
enum AuthStatus { authenticated, unauthenticated, loading }

class AuthState {
  final AuthStatus status;
  final User? user;
  final String? errorMessage;
  
  AuthState({
    required this.status,
    this.user,
    this.errorMessage,
  });
}
```

#### Repository Interfaces

**IAuthRepository**
```dart
abstract class IAuthRepository {
  Future<User> signUp({
    required String email,
    required String password,
    required String fullName,
    required Map<String, dynamic> metadata,
  });
  
  Future<User> signIn({
    required String email,
    required String password,
  });
  
  Future<void> signOut();
  
  Future<User?> getCurrentUser();
  
  Stream<User?> authStateChanges();
}
```

**IProfileRepository**
```dart
abstract class IProfileRepository {
  Future<UserProfile> createProfile(UserProfile profile);
  
  Future<UserProfile> updateProfile(UserProfile profile);
  
  Future<UserProfile?> getProfile(String userId);
  
  Future<bool> hasCompletedSurvey(String userId);
}
```

### 2. Data Layer

#### Data Models

**UserModel** (maps to/from Supabase Auth)
```dart
class UserModel {
  final String id;
  final String email;
  final Map<String, dynamic> userMetadata;
  final String createdAt;
  
  factory UserModel.fromJson(Map<String, dynamic> json);
  Map<String, dynamic> toJson();
  User toDomain();
}
```

**UserProfileModel** (maps to/from Supabase Database)
```dart
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
  
  factory UserProfileModel.fromJson(Map<String, dynamic> json);
  Map<String, dynamic> toJson();
  UserProfile toDomain();
  factory UserProfileModel.fromDomain(UserProfile profile);
}
```

#### Repository Implementations

**AuthRepository**
```dart
class AuthRepository implements IAuthRepository {
  final SupabaseClient _client;
  
  AuthRepository(this._client);
  
  @override
  Future<User> signUp({...}) async {
    // Validate email format locally
    // Call Supabase auth.signUp()
    // Handle errors and map to domain User
  }
  
  @override
  Future<User> signIn({...}) async {
    // Call Supabase auth.signInWithPassword()
    // Handle errors and map to domain User
  }
  
  @override
  Future<void> signOut() async {
    // Call Supabase auth.signOut()
    // Clear local session data
  }
  
  @override
  Future<User?> getCurrentUser() async {
    // Get current session from Supabase
    // Map to domain User or return null
  }
  
  @override
  Stream<User?> authStateChanges() {
    // Listen to Supabase auth.onAuthStateChange
    // Map events to domain User stream
  }
}
```

**ProfileRepository**
```dart
class ProfileRepository implements IProfileRepository {
  final SupabaseClient _client;
  static const String _tableName = 'user_profiles';
  static const int _maxRetries = 3;
  
  ProfileRepository(this._client);
  
  @override
  Future<UserProfile> createProfile(UserProfile profile) async {
    // Convert to UserProfileModel
    // Insert into Supabase with retry logic
    // Return created profile
  }
  
  @override
  Future<UserProfile> updateProfile(UserProfile profile) async {
    // Convert to UserProfileModel
    // Update in Supabase with retry logic
    // Return updated profile
  }
  
  @override
  Future<UserProfile?> getProfile(String userId) async {
    // Query Supabase for profile
    // Map to domain UserProfile or return null
  }
  
  @override
  Future<bool> hasCompletedSurvey(String userId) async {
    // Query profile and check surveyCompleted flag
  }
}
```

### 3. Presentation Layer

#### State Notifiers

**AuthNotifier**
```dart
class AuthNotifier extends StateNotifier<AuthState> {
  final IAuthRepository _authRepository;
  final IProfileRepository _profileRepository;
  
  AuthNotifier(this._authRepository, this._profileRepository)
      : super(AuthState(status: AuthStatus.loading)) {
    _init();
  }
  
  Future<void> _init() async {
    // Check for existing session
    // Update state accordingly
  }
  
  Future<void> signUp({...}) async {
    // Validate inputs
    // Call repository
    // Update state
    // Handle errors
  }
  
  Future<void> signIn({...}) async {
    // Validate inputs
    // Call repository
    // Update state
    // Handle errors
  }
  
  Future<void> signOut() async {
    // Call repository
    // Update state
  }
}
```

**SurveyNotifier**
```dart
class SurveyState {
  final Map<String, dynamic> surveyData;
  final int currentStep;
  final bool isLoading;
  final String? errorMessage;
  
  SurveyState({
    required this.surveyData,
    required this.currentStep,
    required this.isLoading,
    this.errorMessage,
  });
}

class SurveyNotifier extends StateNotifier<SurveyState> {
  final IProfileRepository _profileRepository;
  
  SurveyNotifier(this._profileRepository)
      : super(SurveyState(surveyData: {}, currentStep: 0, isLoading: false));
  
  void updateSurveyData(String key, dynamic value) {
    // Update survey data
    // Persist to local storage
  }
  
  void nextStep() {
    // Validate current step
    // Move to next step
  }
  
  Future<void> submitSurvey(String userId) async {
    // Validate all data
    // Create UserProfile entity
    // Call repository with retry logic
    // Handle errors
  }
}
```

#### Screens

- **SignUpScreen**: Email/password registration form with validation
- **LoginScreen**: Email/password login form with social sign-in shortcuts
- **SurveyIntroScreen**: Introduction to survey flow
- **SurveyBasicInfoScreen**: Collects age, gender, name
- **SurveyBodyMeasurementsScreen**: Collects weight, height
- **SurveyActivityGoalsScreen**: Collects activity level and goals
- **SurveyDailyTargetsScreen**: Displays calculated targets and confirms completion

## Data Models

### Supabase Database Schema

#### user_profiles Table

```sql
CREATE TABLE user_profiles (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name TEXT NOT NULL,
  age INTEGER NOT NULL CHECK (age >= 13 AND age <= 120),
  gender TEXT NOT NULL CHECK (gender IN ('male', 'female', 'other', 'prefer_not_to_say')),
  weight DECIMAL(5,2) NOT NULL CHECK (weight > 0 AND weight < 500),
  height DECIMAL(5,2) NOT NULL CHECK (height > 0 AND height < 300),
  activity_level TEXT NOT NULL CHECK (activity_level IN ('sedentary', 'lightly_active', 'moderately_active', 'very_active', 'extremely_active')),
  goals TEXT[] NOT NULL,
  daily_calorie_target INTEGER NOT NULL CHECK (daily_calorie_target > 0),
  survey_completed BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Index for faster lookups
CREATE INDEX idx_user_profiles_user_id ON user_profiles(user_id);

-- Row Level Security
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;

-- Policy: Users can only read their own profile
CREATE POLICY "Users can view own profile"
  ON user_profiles FOR SELECT
  USING (auth.uid() = user_id);

-- Policy: Users can insert their own profile
CREATE POLICY "Users can insert own profile"
  ON user_profiles FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Policy: Users can update their own profile
CREATE POLICY "Users can update own profile"
  ON user_profiles FOR UPDATE
  USING (auth.uid() = user_id);

-- Trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_user_profiles_updated_at
  BEFORE UPDATE ON user_profiles
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();
```

### Validation Rules

#### Email Validation
- Must contain '@' symbol
- Must match regex: `^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$`

#### Password Validation
- Minimum 8 characters
- Supabase enforces additional complexity rules

#### Survey Data Validation
- **Age**: 13-120 years
- **Weight**: 20-500 kg
- **Height**: 50-300 cm
- **Activity Level**: One of predefined enum values
- **Goals**: At least one goal selected, maximum 5 goals

## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system-essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

### Property 1: Valid credentials create accounts

*For any* valid email and password combination, calling signUp should successfully create a user account in Supabase and return a User entity with a valid ID.

**Validates: Requirements 1.1**

### Property 2: Invalid email formats are rejected locally

*For any* string that doesn't match valid email format, the signUp method should reject the input with a validation error before making any Supabase API calls.

**Validates: Requirements 1.3**

### Property 3: Valid credentials authenticate users

*For any* user account that exists in Supabase, providing the correct email and password to signIn should successfully authenticate and return the User entity.

**Validates: Requirements 2.1**

### Property 4: Successful login persists session

*For any* successful login operation, the authentication session token should be stored locally and retrievable for subsequent app launches.

**Validates: Requirements 2.3**

### Property 5: Logout clears all auth data

*For any* authenticated user, calling signOut should remove all authentication tokens and session data from local storage.

**Validates: Requirements 2.5**

### Property 6: Partial survey data persists across navigation

*For any* partially completed survey data, navigating away and returning to the survey should preserve all previously entered values.

**Validates: Requirements 3.2**

### Property 7: Required survey fields are validated

*For any* survey submission with missing required fields, the validation should fail and prevent progression to the next step.

**Validates: Requirements 3.3**

### Property 8: Numeric survey inputs are range-validated

*For any* numeric survey input (age, weight, height), values outside the defined ranges should be rejected with appropriate error messages.

**Validates: Requirements 3.4**

### Property 9: Complete survey data saves to Supabase

*For any* complete and valid survey data, calling submitSurvey should successfully persist all data to the user_profiles table in Supabase.

**Validates: Requirements 4.1**

### Property 10: Valid session restores auth state

*For any* stored valid session token, initializing the AuthNotifier should restore the authenticated user state without requiring re-login.

**Validates: Requirements 5.2**

### Property 11: Error messages don't expose technical details

*For any* error that occurs in the system, the error message displayed to users should not contain stack traces, database queries, or API keys.

**Validates: Requirements 7.5**

## Error Handling

### Error Types

```dart
abstract class AuthException implements Exception {
  final String message;
  final String? code;
  
  AuthException(this.message, [this.code]);
}

class InvalidEmailException extends AuthException {
  InvalidEmailException() : super('Please enter a valid email address', 'invalid_email');
}

class WeakPasswordException extends AuthException {
  WeakPasswordException() : super('Password must be at least 8 characters', 'weak_password');
}

class EmailAlreadyExistsException extends AuthException {
  EmailAlreadyExistsException() : super('An account with this email already exists', 'email_exists');
}

class InvalidCredentialsException extends AuthException {
  InvalidCredentialsException() : super('Invalid email or password', 'invalid_credentials');
}

class NetworkException extends AuthException {
  NetworkException() : super('Network error. Please check your connection', 'network_error');
}

class UnknownException extends AuthException {
  UnknownException() : super('An unexpected error occurred. Please try again', 'unknown_error');
}
```

### Error Handling Strategy

1. **Validation Errors**: Caught at the presentation layer before API calls
2. **Network Errors**: Wrapped in NetworkException with user-friendly message
3. **Supabase Errors**: Mapped to domain-specific exceptions
4. **Unexpected Errors**: Logged for debugging, shown as generic message to users
5. **Retry Logic**: Implemented for profile save operations (max 3 attempts)

### Logging

```dart
class ErrorLogger {
  static void logError(String context, dynamic error, StackTrace? stackTrace) {
    // Log to console in debug mode
    // Send to error tracking service in production
    // Never expose sensitive data
  }
}
```

## Testing Strategy

### Unit Testing

Unit tests will verify specific examples and edge cases:

- Email validation with various invalid formats
- Password validation with boundary cases (7 chars, 8 chars, empty)
- Duplicate email registration attempt
- Login with wrong password
- Survey validation with missing required fields
- Survey validation with out-of-range numeric values
- Retry logic when save operations fail
- Error message sanitization

### Property-Based Testing

Property-based tests will verify universal properties across many inputs using the **test** package with custom generators:

- **Framework**: Dart's built-in test package with custom property test utilities
- **Iterations**: Minimum 100 iterations per property test
- **Generators**: Custom generators for valid emails, passwords, survey data, and user profiles

Each property-based test will:
- Be tagged with a comment referencing the design document property
- Use format: `**Feature: supabase-auth-onboarding, Property {number}: {property_text}**`
- Generate random valid inputs to verify properties hold across all cases
- Test invariants like session persistence, data round-trips, and validation consistency

### Integration Testing

Integration tests will verify:
- Complete authentication flow from signup to dashboard
- Survey flow with data persistence to Supabase
- Session restoration on app restart
- Error handling across the full stack

### Test Organization

```
test/
├── unit/
│   ├── domain/
│   │   └── entities_test.dart
│   ├── data/
│   │   ├── models_test.dart
│   │   └── repositories_test.dart
│   └── presentation/
│       └── notifiers_test.dart
├── property/
│   ├── auth_properties_test.dart
│   ├── validation_properties_test.dart
│   └── survey_properties_test.dart
└── integration/
    ├── auth_flow_test.dart
    └── survey_flow_test.dart
```

## Implementation Notes

### Secrets Management

Store Supabase credentials in `lib/secrets.dart`:

```dart
class SupabaseConfig {
  static const String url = 'https://YOUR_PROJECT_REF.supabase.co';
  static const String publishableKey = 'sb_publishable_YOUR_KEY';

  @Deprecated('Use publishableKey instead.')
  static const String anonKey = publishableKey;
}
```

Add to `.gitignore` to prevent committing credentials.

### Supabase Initialization

Initialize Supabase in `main.dart` before running the app:

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );
  
  runApp(
    ProviderScope(
      child: MyApp(),
    ),
  );
}
```

### Provider Setup

```dart
// Repository providers
final authRepositoryProvider = Provider<IAuthRepository>((ref) {
  return AuthRepository(Supabase.instance.client);
});

final profileRepositoryProvider = Provider<IProfileRepository>((ref) {
  return ProfileRepository(Supabase.instance.client);
});

// State notifier providers
final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    ref.watch(authRepositoryProvider),
    ref.watch(profileRepositoryProvider),
  );
});

final surveyNotifierProvider = StateNotifierProvider<SurveyNotifier, SurveyState>((ref) {
  return SurveyNotifier(ref.watch(profileRepositoryProvider));
});
```

### Navigation Logic

The app should determine initial route based on auth state:

```dart
class MyApp extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    
    return MaterialApp(
      home: authState.status == AuthStatus.loading
          ? SplashScreen()
          : authState.status == AuthStatus.authenticated
              ? FutureBuilder<bool>(
                  future: ref.read(profileRepositoryProvider)
                      .hasCompletedSurvey(authState.user!.id),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return SplashScreen();
                    return snapshot.data! ? DashboardScreen() : SurveyIntroScreen();
                  },
                )
              : WelcomeScreen(),
      routes: {
        '/login': (context) => LoginScreen(),
        '/signup': (context) => SignUpScreen(),
        '/survey_intro': (context) => SurveyIntroScreen(),
        '/dashboard': (context) => DashboardScreen(),
        // ... other routes
      },
    );
  }
}
```

## Security Considerations

1. **Row Level Security**: Enabled on user_profiles table to ensure users can only access their own data
2. **Password Storage**: Handled by Supabase Auth (bcrypt hashing)
3. **Session Tokens**: Stored securely using flutter_secure_storage
4. **API Keys**: Anon key is safe for client-side use (RLS enforces access control)
5. **Input Validation**: All user inputs validated before database operations
6. **Error Messages**: Sanitized to prevent information leakage

## Performance Considerations

1. **Lazy Loading**: User profile loaded only when needed
2. **Caching**: Auth state cached in memory to avoid repeated API calls
3. **Optimistic Updates**: UI updates immediately, syncs with backend asynchronously
4. **Connection Pooling**: Supabase client reused across the app
5. **Retry Logic**: Exponential backoff for failed operations

## Future Enhancements

1. **OAuth Integration**: Implement actual Google and Apple Sign-In
2. **Email Verification**: Enforce email verification before survey access
3. **Password Reset**: Implement forgot password flow
4. **Profile Editing**: Allow users to update their profile after completion
5. **Offline Support**: Cache profile data for offline access
6. **Biometric Auth**: Add fingerprint/face ID for quick login
