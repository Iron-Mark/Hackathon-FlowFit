import '../entities/user.dart';

/// Interface for authentication repository operations.
abstract class IAuthRepository {
  /// Signs up a new user with email and password.
  ///
  /// [email] - The user's email address
  /// [password] - The user's password
  /// [fullName] - The user's full name
  /// [metadata] - Additional user metadata
  ///
  /// Returns a [User] entity on successful registration.
  /// Throws [AuthException] on failure.
  Future<User> signUp({
    required String email,
    required String password,
    required String fullName,
    required Map<String, dynamic> metadata,
  });

  /// Signs in an existing user with email and password.
  ///
  /// [email] - The user's email address
  /// [password] - The user's password
  ///
  /// Returns a [User] entity on successful authentication.
  /// Throws [AuthException] on failure.
  Future<User> signIn({required String email, required String password});

  /// Signs out the current user.
  ///
  /// Clears the session and all locally stored authentication tokens.
  /// Throws [AuthException] on failure.
  Future<void> signOut();

  /// Gets the currently authenticated user.
  ///
  /// Returns a [User] entity if a user is authenticated, null otherwise.
  Future<User?> getCurrentUser();

  /// Stream of authentication state changes.
  ///
  /// Emits a [User] when a user signs in, null when a user signs out.
  Stream<User?> authStateChanges();
}
