import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:flowfit/features/wellness/presentation/maps_page_wrapper.dart';
import 'package:flowfit/screens/font_demo_screen.dart';

/// Application router configuration using go_router
///
/// This file defines all routes and navigation flows for the FlowFit app.
/// Routes are organized by feature and support nested navigation.
class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      // Root route - will be implemented in later tasks
      GoRoute(
        path: '/',
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Dashboard - To be implemented')),
        ),
      ),

      // Active/Workout tracking route
      GoRoute(
        path: '/active',
        builder: (context, state) {
          final activityType = state.uri.queryParameters['type'];
          return Scaffold(
            body: Center(
              child: Text(
                activityType != null
                    ? 'Activity Tracking - $activityType'
                    : 'Workout Selection - To be implemented',
              ),
            ),
          );
        },
      ),

      // Fitness routes - to be implemented
      GoRoute(
        path: '/fitness',
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Fitness - To be implemented')),
        ),
      ),

      // Nutrition routes - to be implemented
      GoRoute(
        path: '/nutrition',
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Nutrition - To be implemented')),
        ),
      ),

      // Sleep routes - to be implemented
      GoRoute(
        path: '/sleep',
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Sleep - To be implemented')),
        ),
      ),

      // Mood routes - to be implemented
      GoRoute(
        path: '/mood',
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Mood - To be implemented')),
        ),
      ),

      // Reports routes - to be implemented
      GoRoute(
        path: '/reports',
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Reports - To be implemented')),
        ),
      ),

      // Profile routes - to be implemented
      GoRoute(
        path: '/profile',
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Profile - To be implemented')),
        ),
      ),
      // Wellness (Geofence maps)
      GoRoute(
        path: '/wellness',
        builder: (context, state) => const MapsPageWrapper(),
      ),
      if (kDebugMode)
        GoRoute(
          path: '/font-demo',
          builder: (context, state) => const FontDemoScreen(),
        ),
    ],
    errorBuilder: (context, state) =>
        Scaffold(body: Center(child: Text('Page not found: ${state.uri}'))),
    // Font demo route - useful for verifying custom fonts
  );
}
