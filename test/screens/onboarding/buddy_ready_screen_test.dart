import 'package:flowfit/core/exceptions/buddy_exceptions.dart';
import 'package:flowfit/screens/onboarding/buddy_ready_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('start adventure completes onboarding and opens dashboard', (
    tester,
  ) async {
    var completionCalls = 0;

    await _pumpScreen(
      tester,
      completeOnboarding: ({required ref, required context}) async {
        completionCalls++;
      },
    );

    await tester.tap(find.text('START ADVENTURE!'));
    await tester.pumpAndSettle();

    expect(completionCalls, 1);
    expect(find.text('route:dashboard'), findsOneWidget);
  });

  testWidgets('offline local save opens dashboard with sync feedback', (
    tester,
  ) async {
    await _pumpScreen(
      tester,
      completeOnboarding: ({required ref, required context}) async {
        throw BuddySaveException(
          'saved locally',
          savedLocally: true,
          userFriendlyMessage: 'Saved locally for later sync.',
        );
      },
    );

    await tester.tap(find.text('START ADVENTURE!'));
    await tester.pumpAndSettle();

    expect(find.text('Saved locally for later sync.'), findsOneWidget);
    expect(find.text('route:dashboard'), findsOneWidget);
  });

  testWidgets('auth failure keeps screen visible with friendly feedback', (
    tester,
  ) async {
    await _pumpScreen(
      tester,
      completeOnboarding: ({required ref, required context}) async {
        throw BuddyAuthException(
          'missing session',
          userFriendlyMessage: 'Please sign in before creating your Buddy.',
        );
      },
    );

    await tester.tap(find.text('START ADVENTURE!'));
    await tester.pumpAndSettle();

    expect(find.text('route:dashboard'), findsNothing);
    expect(find.text('START ADVENTURE!'), findsOneWidget);
    expect(
      find.text('Please sign in before creating your Buddy.'),
      findsOneWidget,
    );
  });
}

Future<void> _pumpScreen(
  WidgetTester tester, {
  required BuddyReadyCompletionAction completeOnboarding,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        home: BuddyReadyScreen(completeOnboarding: completeOnboarding),
        routes: {
          '/dashboard': (_) => const Scaffold(body: Text('route:dashboard')),
        },
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 700));
}
