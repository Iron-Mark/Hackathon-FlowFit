import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Handles deep link authentication callbacks from Supabase
class DeepLinkHandler {
  static final DeepLinkHandler _instance = DeepLinkHandler._internal();
  factory DeepLinkHandler() => _instance;
  DeepLinkHandler._internal();

  // Global navigator key to handle navigation from anywhere
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  /// Initialize deep link handling
  /// Call this in main() after Supabase initialization
  void initialize() {
    // Listen for auth state changes from deep links
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      final session = data.session;

      debugPrint('Auth state changed: $event');

      if (event == AuthChangeEvent.signedIn && session != null) {
        debugPrint('User signed in via deep link: ${session.user.email}');

        // Check if email is verified
        final user = session.user;
        if (user.emailConfirmedAt != null) {
          debugPrint('Email verified! Redirecting to survey flow...');

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
        }
      } else if (event == AuthChangeEvent.tokenRefreshed) {
        debugPrint('Token refreshed');
      }
    });
  }

  /// Handle incoming deep link URI
  /// This processes the auth callback from email verification
  static Future<bool> handleDeepLink(Uri uri) async {
    debugPrint('Handling deep link: $uri');

    // Check if this is an auth callback
    if (uri.host == 'auth-callback' || uri.path.contains('auth-callback')) {
      try {
        // Supabase Flutter SDK automatically handles the token exchange
        // when the deep link is opened. We just need to check the result.

        // Extract any error information
        final error = uri.queryParameters['error'];
        final errorDescription = uri.queryParameters['error_description'];

        if (error != null) {
          debugPrint('Auth error: $error - $errorDescription');
          return false;
        }

        // Success - the auth state listener will handle navigation
        debugPrint('Deep link auth callback processed successfully');
        return true;
      } catch (e) {
        debugPrint('Error handling deep link: $e');
        return false;
      }
    }

    return false;
  }

  /// Get the appropriate redirect URL based on environment
  static String getRedirectUrl({bool isDevelopment = false}) {
    if (isDevelopment) {
      return 'com.example.flowfit.dev://auth-callback';
    }
    return 'com.example.flowfit://auth-callback';
  }
}
