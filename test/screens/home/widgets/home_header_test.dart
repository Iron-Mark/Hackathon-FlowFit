import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flowfit/screens/home/widgets/home_header.dart';
import 'package:flowfit/providers/dashboard_providers.dart';

void main() {
  group('HomeHeader', () {
    testWidgets('displays app title', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: Scaffold(appBar: HomeHeader())),
        ),
      );

      expect(find.text('FlowFit'), findsOneWidget);
    });

    testWidgets('displays notification icon', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: Scaffold(appBar: HomeHeader())),
        ),
      );

      // Check for IconButton which contains the notification icon
      expect(find.byType(IconButton), findsOneWidget);
    });

    testWidgets('hides badge when notification count is 0', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [unreadNotificationsProvider.overrideWith((ref) => 0)],
          child: const MaterialApp(home: Scaffold(appBar: HomeHeader())),
        ),
      );

      // Badge should not be visible
      expect(find.text('0'), findsNothing);
    });

    testWidgets('displays exact count when count <= 9', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [unreadNotificationsProvider.overrideWith((ref) => 5)],
          child: const MaterialApp(home: Scaffold(appBar: HomeHeader())),
        ),
      );

      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('displays "9+" when count > 9', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [unreadNotificationsProvider.overrideWith((ref) => 15)],
          child: const MaterialApp(home: Scaffold(appBar: HomeHeader())),
        ),
      );

      expect(find.text('9+'), findsOneWidget);
    });

    testWidgets('displays "9+" when count is exactly 10', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [unreadNotificationsProvider.overrideWith((ref) => 10)],
          child: const MaterialApp(home: Scaffold(appBar: HomeHeader())),
        ),
      );

      expect(find.text('9+'), findsOneWidget);
    });

    testWidgets('displays exact count for boundary value 9', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [unreadNotificationsProvider.overrideWith((ref) => 9)],
          child: const MaterialApp(home: Scaffold(appBar: HomeHeader())),
        ),
      );

      expect(find.text('9'), findsOneWidget);
    });

    testWidgets('notification button has tooltip', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: Scaffold(appBar: HomeHeader())),
        ),
      );

      final iconButton = tester.widget<IconButton>(find.byType(IconButton));
      expect(iconButton.tooltip, 'Notifications');
    });

    testWidgets('notification button opens notification settings', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [unreadNotificationsProvider.overrideWith((ref) => 2)],
          child: MaterialApp(
            home: const Scaffold(appBar: HomeHeader()),
            routes: {
              '/notification-settings': (context) => const Scaffold(
                body: Center(child: Text('Notification Settings Route')),
              ),
            },
          ),
        ),
      );

      await tester.tap(find.byTooltip('Notifications'));
      await tester.pumpAndSettle();

      expect(find.text('Notification Settings Route'), findsOneWidget);
    });

    testWidgets('uses theme colors correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: ThemeData(
              colorScheme: const ColorScheme.light(
                surface: Colors.white,
                onSurface: Colors.black,
                error: Colors.red,
              ),
            ),
            home: const Scaffold(appBar: HomeHeader()),
          ),
        ),
      );

      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.backgroundColor, Colors.white);
    });

    testWidgets('badge uses error color from theme', (
      WidgetTester tester,
    ) async {
      const testErrorColor = Colors.red;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [unreadNotificationsProvider.overrideWith((ref) => 5)],
          child: MaterialApp(
            theme: ThemeData(
              colorScheme: const ColorScheme.light(error: testErrorColor),
            ),
            home: const Scaffold(appBar: HomeHeader()),
          ),
        ),
      );

      // Find the badge container
      final container = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(Stack),
              matching: find.byType(Container),
            )
            .first,
      );

      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, testErrorColor);
    });
  });
}
