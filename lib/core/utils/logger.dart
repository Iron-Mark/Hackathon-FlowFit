import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

/// Logging utility for the application
///
/// Provides structured logging with different severity levels.
/// In production, this can be extended to send logs to analytics services.
class Logger {
  final String _className;

  Logger(this._className);

  /// Log debug information (development only)
  void debug(String message, {Object? error, StackTrace? stackTrace}) {
    _log('DEBUG', message, error: error, stackTrace: stackTrace);
  }

  /// Log informational messages
  void info(String message, {Object? error, StackTrace? stackTrace}) {
    _log('INFO', message, error: error, stackTrace: stackTrace);
  }

  /// Log warnings
  void warning(String message, {Object? error, StackTrace? stackTrace}) {
    _log('WARNING', message, error: error, stackTrace: stackTrace);
  }

  /// Log errors
  void error(String message, {Object? error, StackTrace? stackTrace}) {
    _log('ERROR', message, error: error, stackTrace: stackTrace);
  }

  /// Log critical errors
  void critical(String message, {Object? error, StackTrace? stackTrace}) {
    _log('CRITICAL', message, error: error, stackTrace: stackTrace);
  }

  void _log(
    String level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    // Never emit logs in release builds: this sink is the single choke point
    // every level funnels through, so short-circuiting here neutralizes PII
    // (child biometrics, email, auth tokens) leaking into production logs.
    // Debug builds (including tests) keep full logging.
    if (!kDebugMode) return;

    final timestamp = DateTime.now().toIso8601String();
    final logMessage = '[$timestamp] [$level] [$_className] $message';

    // Use developer.log for better integration with Flutter DevTools
    developer.log(
      logMessage,
      name: _className,
      error: error,
      stackTrace: stackTrace,
      level: _getLevelValue(level),
    );

    // In production, you could send logs to analytics services here
    // Example: FirebaseCrashlytics.instance.log(logMessage);
  }

  int _getLevelValue(String level) {
    switch (level) {
      case 'DEBUG':
        return 500;
      case 'INFO':
        return 800;
      case 'WARNING':
        return 900;
      case 'ERROR':
        return 1000;
      case 'CRITICAL':
        return 1200;
      default:
        return 800;
    }
  }
}
