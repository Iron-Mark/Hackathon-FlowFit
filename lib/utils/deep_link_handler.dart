import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flowfit/core/config/flowfit_runtime_config.dart';

/// Handles deep link authentication callbacks from Supabase
class DeepLinkHandler {
  static final DeepLinkHandler _instance = DeepLinkHandler._internal();
  factory DeepLinkHandler() => _instance;
  DeepLinkHandler._internal();

  static int _internalAuthFlowDepth = 0;

  // Global navigator key to handle navigation from anywhere
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static void beginInternalAuthFlow() {
    _internalAuthFlowDepth++;
  }

  static void endInternalAuthFlow() {
    if (_internalAuthFlowDepth > 0) {
      _internalAuthFlowDepth--;
    }
  }

  static void resetInternalAuthFlowSuppressionForTest() {
    _internalAuthFlowDepth = 0;
  }

  static bool shouldNavigateToSurveyForAuthEvent({
    required AuthChangeEvent event,
    required bool hasSession,
    required bool emailConfirmed,
  }) {
    return event == AuthChangeEvent.signedIn &&
        hasSession &&
        emailConfirmed &&
        _internalAuthFlowDepth == 0;
  }

  /// Initialize deep link handling
  /// Call this in main() after Supabase initialization
  void initialize() {
    // Listen for auth state changes from deep links
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      final session = data.session;

      if (kDebugMode) debugPrint('Auth state changed: $event');

      if (shouldNavigateToSurveyForAuthEvent(
        event: event,
        hasSession: session != null,
        emailConfirmed: session?.user.emailConfirmedAt != null,
      )) {
        final user = session!.user;
        // Never log the user's email: emit only a redacted event label.
        if (kDebugMode) {
          debugPrint('User signed in via deep link');
          debugPrint('Email verified! Redirecting to survey flow...');
        }

        // Navigate to survey intro screen after email verification
        Future.delayed(const Duration(milliseconds: 500), () {
          final context = navigatorKey.currentContext;
          if (context != null && context.mounted) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/survey_intro',
              (route) => false,
              arguments: {'userId': user.id, 'email': user.email},
            );
          }
        });
      } else if (event == AuthChangeEvent.tokenRefreshed) {
        if (kDebugMode) debugPrint('Token refreshed');
      }
    });
  }

  /// Handle incoming deep link URI
  /// This processes the auth callback from email verification
  static Future<bool> handleDeepLink(Uri uri) async {
    // Never log the raw URI: it can carry the auth code/token in its query.
    if (kDebugMode) debugPrint('Handling deep link: auth callback received');

    // Check if this is an auth callback
    if (uri.host == 'auth-callback' || uri.path.contains('auth-callback')) {
      try {
        // Supabase Flutter SDK automatically handles the token exchange
        // when the deep link is opened. We just need to check the result.

        // Extract any error information
        final error = uri.queryParameters['error'];

        if (error != null) {
          // Redacted: do not log raw error/description from the callback URI.
          if (kDebugMode) debugPrint('Auth error received');
          return false;
        }

        // Success - the auth state listener will handle navigation
        if (kDebugMode) {
          debugPrint('Deep link auth callback processed successfully');
        }
        return true;
      } catch (e) {
        // Redacted: the exception may embed the raw URI/code.
        if (kDebugMode) debugPrint('Error handling deep link');
        return false;
      }
    }

    return false;
  }

  /// Get the appropriate redirect URL based on environment
  static String getRedirectUrl({bool isDevelopment = false}) {
    return FlowFitRuntimeConfig.authRedirectUrl(isDevelopment: isDevelopment);
  }
}
