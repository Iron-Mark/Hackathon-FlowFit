import 'user.dart';

/// Enum representing the authentication status.
enum AuthStatus { authenticated, unauthenticated, loading }

/// Domain entity representing the current authentication state.
/// Designed to work with Riverpod StateNotifier for reactive state management.
class AuthState {
  final AuthStatus status;
  final User? user;
  final String? errorMessage;

  const AuthState({required this.status, this.user, this.errorMessage});

  /// Factory constructor for initial loading state
  factory AuthState.initial() => const AuthState(status: AuthStatus.loading);

  /// Factory constructor for authenticated state
  factory AuthState.authenticated(User user) =>
      AuthState(status: AuthStatus.authenticated, user: user);

  /// Factory constructor for unauthenticated state
  factory AuthState.unauthenticated() =>
      const AuthState(status: AuthStatus.unauthenticated);

  /// Factory constructor for error state
  factory AuthState.error(String message, {AuthStatus? status}) => AuthState(
    status: status ?? AuthStatus.unauthenticated,
    errorMessage: message,
  );

  /// Creates a copy of this state with the given fields replaced
  AuthState copyWith({
    AuthStatus? status,
    User? user,
    String? errorMessage,
    bool clearError = false,
    bool clearUser = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: clearUser ? null : (user ?? this.user),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthState &&
          runtimeType == other.runtimeType &&
          status == other.status &&
          user == other.user &&
          errorMessage == other.errorMessage;

  @override
  int get hashCode => status.hashCode ^ user.hashCode ^ errorMessage.hashCode;

  @override
  String toString() {
    return 'AuthState{status: $status, user: $user, errorMessage: $errorMessage}';
  }
}
