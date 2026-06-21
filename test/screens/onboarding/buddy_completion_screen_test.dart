import 'package:flowfit/core/exceptions/buddy_exceptions.dart';
import 'package:flowfit/screens/onboarding/buddy_completion_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget buildHarness({BuddyOnboardingCompletionAction? completeOnboarding}) {
    return ProviderScope(
      child: MaterialApp(
        home: BuddyCompletionScreen(completeOnboarding: completeOnboarding),
        routes: {
          '/dashboard': (_) => const Scaffold(body: Text('route:dashboard')),
        },
      ),
    );
  }

  Future<void> pumpScreen(
    WidgetTester tester, {
    BuddyOnboardingCompletionAction? completeOnboarding,
  }) async {
    await tester.pumpWidget(
      buildHarness(completeOnboarding: completeOnboarding),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
  }

  testWidgets('start mission completes onboarding and opens dashboard', (
    tester,
  ) async {
    var completionCalls = 0;

    await pumpScreen(
      tester,
      completeOnboarding: ({required ref, required context}) async {
        completionCalls++;
      },
    );

    await tester.tap(find.text('START FIRST MISSION'));
    await tester.pumpAndSettle();

    expect(completionCalls, 1);
    expect(find.text('route:dashboard'), findsOneWidget);
  });

  testWidgets('locally saved Buddy still opens dashboard', (tester) async {
    await pumpScreen(
      tester,
      completeOnboarding: ({required ref, required context}) async {
        throw BuddySaveException('offline fallback', savedLocally: true);
      },
    );

    await tester.tap(find.text('START FIRST MISSION'));
    await tester.pumpAndSettle();

    expect(find.text('route:dashboard'), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('start mission failure resets loading and allows cancel', (
    tester,
  ) async {
    await pumpScreen(tester);

    await tester.tap(find.text('START FIRST MISSION'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('Oops!'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('START FIRST MISSION'), findsOneWidget);
  });

  testWidgets('retry failure does not stack duplicate error dialogs', (
    tester,
  ) async {
    await pumpScreen(tester);

    await tester.tap(find.text('START FIRST MISSION'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(AlertDialog), findsOneWidget);

    await tester.tap(find.text('Try Again'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('Oops!'), findsOneWidget);
  });

  testWidgets('auth failure shows user-friendly message without navigating', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      completeOnboarding: ({required ref, required context}) async {
        throw BuddyAuthException(
          'missing session',
          userFriendlyMessage: 'Please sign in before creating your Buddy.',
        );
      },
    );

    await tester.tap(find.text('START FIRST MISSION'));
    await tester.pumpAndSettle();

    expect(find.text('route:dashboard'), findsNothing);
    expect(
      find.text('Please sign in before creating your Buddy.'),
      findsOneWidget,
    );
    expect(find.widgetWithText(TextButton, 'OK'), findsOneWidget);
  });
}
