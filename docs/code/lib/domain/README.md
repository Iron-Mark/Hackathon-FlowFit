# Domain Layer - Supabase Auth & Onboarding

This directory contains the domain entities, repository interfaces, and exceptions for the authentication and onboarding feature.

## Structure

```
domain/
├── entities/           # Domain entities (immutable data classes)
│   ├── user.dart
│   ├── user_profile.dart
│   └── auth_state.dart
├── repositories/       # Repository interfaces (contracts)
│   ├── i_auth_repository.dart
│   └── i_profile_repository.dart
└── exceptions/         # Domain-specific exceptions
    └── auth_exceptions.dart
```

## Entities

### User
Represents a user account in the system.
- Immutable with `const` constructor
- Used in authentication flows

### UserProfile
Represents a user's profile data collected during onboarding.
- Immutable with `const` constructor
- Includes `copyWith()` for state updates
- Contains survey data (age, weight, height, goals, etc.)

### AuthState
Represents the current authentication state of the application.
- Designed for use with Riverpod `StateNotifier<AuthState>`
- Factory constructors for common states:
  - `AuthState.initial()` - Loading state
  - `AuthState.authenticated(user)` - User logged in
  - `AuthState.unauthenticated()` - No user logged in
  - `AuthState.error(message)` - Error occurred
- Includes `copyWith()` with options to clear user/error

## Repository Interfaces

### IAuthRepository
Defines the contract for authentication operations:
- `signUp()` - Create new user account
- `signIn()` - Authenticate existing user
- `signOut()` - Clear session
- `getCurrentUser()` - Get current user
- `authStateChanges()` - Stream of auth state changes

### IProfileRepository
Defines the contract for profile operations:
- `createProfile()` - Create user profile
- `updateProfile()` - Update user profile
- `getProfile()` - Get user profile by ID
- `hasCompletedSurvey()` - Check survey completion status

## Exceptions

All authentication exceptions extend `AuthException`:
- `InvalidEmailException` - Invalid email format
- `WeakPasswordException` - Password too weak
- `EmailAlreadyExistsException` - Email already registered
- `InvalidCredentialsException` - Wrong email/password
- `NetworkException` - Network error
- `UnknownException` - Unexpected error

## Riverpod Integration

These entities are designed to work seamlessly with Riverpod:

### StateNotifier Example
```dart
class AuthNotifier extends StateNotifier<AuthState> {
  final IAuthRepository _authRepository;
  
  AuthNotifier(this._authRepository) : super(AuthState.initial());
  
  Future<void> signIn(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);
    
    try {
      final user = await _authRepository.signIn(
        email: email,
        password: password,
      );
      state = AuthState.authenticated(user);
    } on InvalidCredentialsException catch (e) {
      state = AuthState.error(e.message);
    } catch (e) {
      state = AuthState.error('An unexpected error occurred');
    }
  }
}
```

### Provider Setup
```dart
final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return AuthNotifier(authRepository);
});
```

### Widget Usage
```dart
class LoginScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    
    if (authState.status == AuthStatus.loading) {
      return CircularProgressIndicator();
    }
    
    if (authState.errorMessage != null) {
      return Text('Error: ${authState.errorMessage}');
    }
    
    return LoginForm();
  }
}
```

## Design Principles

1. **Immutability** - All entities use `const` constructors
2. **Clean Architecture** - Domain layer has no dependencies on data or presentation layers
3. **Type Safety** - Strong typing with enums and explicit types
4. **Testability** - Pure domain logic, easy to unit test
5. **Riverpod-Ready** - Designed for reactive state management

## Next Steps

The data layer will implement these repository interfaces using Supabase as the backend.
The presentation layer will use StateNotifiers to manage state and expose it via Riverpod providers.
