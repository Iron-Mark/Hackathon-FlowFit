/// Base class for all authentication-related exceptions.
abstract class AuthException implements Exception {
  final String message;
  final String? code;

  AuthException(this.message, [this.code]);

  @override
  String toString() =>
      'AuthException: $message${code != null ? ' (code: $code)' : ''}';
}

/// Exception thrown when an invalid email format is provided.
class InvalidEmailException extends AuthException {
  InvalidEmailException()
    : super('Please enter a valid email address', 'invalid_email');
}

/// Exception thrown when a password is too weak.
class WeakPasswordException extends AuthException {
  WeakPasswordException()
    : super('Password must be at least 8 characters', 'weak_password');
}

/// Exception thrown when attempting to register with an email that already exists.
class EmailAlreadyExistsException extends AuthException {
  EmailAlreadyExistsException()
    : super('An account with this email already exists', 'email_exists');
}

/// Exception thrown when invalid credentials are provided during login.
class InvalidCredentialsException extends AuthException {
  InvalidCredentialsException()
    : super('Invalid email or password', 'invalid_credentials');
}

/// Exception thrown when a network error occurs.
class NetworkException extends AuthException {
  NetworkException()
    : super('Network error. Please check your connection', 'network_error');
}

/// Exception thrown when an unexpected error occurs.
class UnknownException extends AuthException {
  UnknownException()
    : super('An unexpected error occurred. Please try again', 'unknown_error');
}
