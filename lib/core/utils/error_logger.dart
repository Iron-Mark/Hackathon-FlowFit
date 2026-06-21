import 'package:flutter/foundation.dart';

/// Utility class for logging errors throughout the application.
///
/// This logger ensures that:
/// - Errors are logged to console in debug mode
/// - No sensitive data (passwords, tokens, API keys) is logged
/// - Error messages are sanitized before logging
/// - Stack traces are included for debugging purposes
class ErrorLogger {
  /// Logs an error with context information.
  ///
  /// [context] describes where the error occurred (e.g., 'AuthRepository.signIn')
  /// [error] is the error object that was caught
  /// [stackTrace] is the optional stack trace for debugging
  ///
  /// This method will only log in debug mode to avoid exposing
  /// sensitive information in production builds.
  static void logError(String context, dynamic error, StackTrace? stackTrace) {
    // Only log in debug mode
    if (kDebugMode) {
      final sanitizedError = _sanitizeError(error);

      // Log the error with context
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('ERROR in $context');
      debugPrint('Error: $sanitizedError');

      if (stackTrace != null) {
        debugPrint('Stack trace:');
        debugPrint(stackTrace.toString());
      }

      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    }

    // In production, you would send this to an error tracking service
    // like Sentry, Firebase Crashlytics, etc.
    // Example:
    // if (kReleaseMode) {
    //   Sentry.captureException(error, stackTrace: stackTrace);
    // }
  }

  /// Sanitizes error messages to remove sensitive data.
  ///
  /// This method removes:
  /// - API keys and tokens
  /// - Passwords
  /// - Email addresses (partially masked)
  /// - Database connection strings
  /// - Any other potentially sensitive information
  static String _sanitizeError(dynamic error) {
    String errorString = error.toString();

    // Remove potential API keys (long alphanumeric strings)
    errorString = errorString.replaceAllMapped(
      RegExp(r'[a-zA-Z0-9]{32,}'),
      (match) => '[REDACTED_TOKEN]',
    );

    // Remove potential passwords (after 'password' keyword)
    errorString = errorString.replaceAllMapped(
      RegExp(r'password["\s:=]+[^\s,}"]+', caseSensitive: false),
      (match) => 'password: [REDACTED]',
    );

    // Partially mask email addresses
    errorString = errorString.replaceAllMapped(
      RegExp(r'([a-zA-Z0-9._%+-]+)@([a-zA-Z0-9.-]+\.[a-zA-Z]{2,})'),
      (match) {
        final username = match.group(1) ?? '';
        final domain = match.group(2) ?? '';

        // Show first 2 chars of username and full domain
        if (username.length > 2) {
          return '${username.substring(0, 2)}***@$domain';
        }
        return '***@$domain';
      },
    );

    // Remove database connection strings
    errorString = errorString.replaceAllMapped(
      RegExp(r'postgres://[^\s]+'),
      (match) => 'postgres://[REDACTED]',
    );

    // Remove JWT tokens
    errorString = errorString.replaceAllMapped(
      RegExp(r'eyJ[a-zA-Z0-9_-]+\.eyJ[a-zA-Z0-9_-]+\.[a-zA-Z0-9_-]+'),
      (match) => '[REDACTED_JWT]',
    );

    return errorString;
  }

  /// Logs a warning message.
  ///
  /// Use this for non-critical issues that should be noted but don't
  /// require immediate attention.
  static void logWarning(String context, String message) {
    if (kDebugMode) {
      debugPrint('⚠️ WARNING in $context: $message');
    }
  }

  /// Logs an info message.
  ///
  /// Use this for general information that might be useful for debugging.
  static void logInfo(String context, String message) {
    if (kDebugMode) {
      debugPrint('ℹ️ INFO in $context: $message');
    }
  }
}
