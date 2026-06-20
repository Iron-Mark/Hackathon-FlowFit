import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/auth_state.dart';
import '../../domain/repositories/i_auth_repository.dart';
import '../../domain/exceptions/auth_exceptions.dart';

/// StateNotifier for managing authentication state.
///
/// Handles user sign up, sign in, sign out, and session restoration.
/// Validates inputs before making repository calls.
///
/// Requirements: 1.1, 2.1, 2.3, 2.5, 5.1, 5.2
class AuthNotifier extends StateNotifier<AuthState> {
  final IAuthRepository _authRepository;

  AuthNotifier(this._authRepository) : super(AuthState.initial()) {
    _init();
  }

  /// Initialize the notifier by checking for an existing session.
  ///
  /// If a valid session exists, restore the authenticated user state.
  /// Otherwise, set state to unauthenticated.
  ///
  /// Requirement 5.1: Check for valid stored session on app start
  /// Requirement 5.2: Restore user's authentication state if session exists
  Future<void> _init() async {
    try {
      final user = await _authRepository.getCurrentUser();
      if (user != null) {
        state = AuthState.authenticated(user);
      } else {
        state = AuthState.unauthenticated();
      }
    } catch (e) {
      // If there's an error checking session, assume unauthenticated
      state = AuthState.unauthenticated();
    }
  }

  /// Public method to initialize or re-initialize auth state.
  ///
  /// Can be called from splash screen or when app resumes.
  Future<void> initialize() async {
    await _init();
  }

  /// Signs up a new user with email and password.
  ///
  /// Validates email format and password strength before calling repository.
  /// Updates state to authenticated on success, or error on failure.
  ///
  /// Requirement 1.1: Create new user account with valid credentials
  /// Requirement 1.3: Reject invalid email format before sending to Supabase
  /// Requirement 1.4: Reject password shorter than 8 characters
  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
    Map<String, dynamic>? metadata,
  }) async {
    // Set loading state
    state = state.copyWith(status: AuthStatus.loading, clearError: true);

    try {
      // Validate email format locally (Requirement 1.3)
      if (!_isValidEmail(email)) {
        throw InvalidEmailException();
      }

      // Validate password strength locally (Requirement 1.4)
      if (password.length < 8) {
        throw WeakPasswordException();
      }

      // Call repository to create account (Requirement 1.1)
      final user = await _authRepository.signUp(
        email: email,
        password: password,
        fullName: fullName,
        metadata: metadata ?? {},
      );

      // Update state to authenticated
      state = AuthState.authenticated(user);
    } on AuthException catch (e) {
      // Handle domain exceptions
      state = AuthState.error(e.message, status: AuthStatus.unauthenticated);
    } catch (e) {
      // Handle unexpected errors
      state = AuthState.error(
        'An unexpected error occurred. Please try again',
        status: AuthStatus.unauthenticated,
      );
    }
  }

  /// Signs in an existing user with email and password.
  ///
  /// Validates credentials and updates state on success or failure.
  /// Persists session locally for automatic re-authentication.
  ///
  /// Requirement 2.1: Authenticate user with valid credentials
  /// Requirement 2.2: Reject invalid credentials with error message
  /// Requirement 2.3: Persist session locally on successful login
  Future<void> signIn({required String email, required String password}) async {
    // Set loading state
    state = state.copyWith(status: AuthStatus.loading, clearError: true);

    try {
      // Call repository to authenticate (Requirement 2.1)
      final user = await _authRepository.signIn(
        email: email,
        password: password,
      );

      // Update state to authenticated (Requirement 2.3: session persisted by repository)
      state = AuthState.authenticated(user);
    } on AuthException catch (e) {
      // Handle domain exceptions (Requirement 2.2)
      state = AuthState.error(e.message, status: AuthStatus.unauthenticated);
    } catch (e) {
      // Handle unexpected errors
      state = AuthState.error(
        'An unexpected error occurred. Please try again',
        status: AuthStatus.unauthenticated,
      );
    }
  }

  /// Signs out the current user.
  ///
  /// Clears the session and all locally stored authentication tokens.
  /// Updates state to unauthenticated only after repository sign-out succeeds.
  ///
  /// Requirement 2.5: Clear session and all auth tokens on logout
  Future<void> signOut() async {
    try {
      // Call repository to clear session (Requirement 2.5)
      await _authRepository.signOut();

      // Update state to unauthenticated
      state = AuthState.unauthenticated();
    } on AuthException catch (e) {
      state = state.copyWith(errorMessage: e.message);
      rethrow;
    } catch (e) {
      state = state.copyWith(
        errorMessage:
            'Could not sign out. Check your connection and try again.',
      );
      throw Exception(
        'Could not sign out. Check your connection and try again.',
      );
    }
  }

  /// Validates email format using a simple regex.
  ///
  /// Returns true if email matches the pattern, false otherwise.
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }
}
