import 'package:flowfit/domain/entities/user.dart';
import 'package:flowfit/domain/repositories/i_auth_repository.dart';
import 'package:flowfit/main.dart';
import 'package:flowfit/presentation/providers/providers.dart';
import 'package:flowfit/providers/wellness_state_provider.dart' as wellness;
import 'package:flowfit/widgets/buddy_pending_sync_listener.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('welcome actions navigate through the production route table', (
    tester,
  ) async {
    await _pumpFlowFitAppAt(tester, '/welcome');

    await tester.tap(find.widgetWithText(ElevatedButton, 'Get Started'));
    await tester.pumpAndSettle();

    expect(find.text('Create Account'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);

    final readTerms = find.text('Read Terms');
    await tester.ensureVisible(readTerms);
    await tester.pumpAndSettle();
    await tester.tap(readTerms);
    await tester.pumpAndSettle();

    expect(find.text('Terms of Service'), findsWidgets);

    Navigator.of(tester.element(find.byType(Scaffold))).pop();
    await tester.pumpAndSettle();

    final readPolicy = find.text('Read Policy');
    await tester.ensureVisible(readPolicy);
    await tester.pumpAndSettle();
    await tester.tap(readPolicy);
    await tester.pumpAndSettle();

    expect(find.text('Privacy Policy'), findsWidgets);

    Navigator.of(tester.element(find.byType(Scaffold))).pop();
    await tester.pumpAndSettle();

    final loginLink = find.text('Log In').last;
    await tester.ensureVisible(loginLink);
    await tester.pumpAndSettle();
    await tester.tap(loginLink);
    await tester.pumpAndSettle();

    expect(find.text('Forgot password?'), findsOneWidget);
  });

  testWidgets('login sign-up action returns to the production signup route', (
    tester,
  ) async {
    await _pumpFlowFitAppAt(tester, '/login');

    final signUpLink = find.text('Sign Up').last;
    await tester.ensureVisible(signUpLink);
    await tester.pumpAndSettle();
    await tester.tap(signUpLink);
    await tester.pumpAndSettle();

    expect(find.text('Create Account'), findsOneWidget);
  });

  testWidgets('workout type actions open their production setup routes', (
    tester,
  ) async {
    await _pumpFlowFitAppAt(tester, '/workout/select-type');

    await tester.tap(find.text('Running'));
    await tester.pumpAndSettle();

    expect(find.text('Running Setup'), findsOneWidget);
    expect(find.text('Start Running'), findsOneWidget);

    await _pumpFlowFitAppAt(tester, '/workout/select-type');

    await tester.tap(find.text('Walking'));
    await tester.pumpAndSettle();

    expect(find.text('Choose Walking Mode'), findsOneWidget);
    expect(find.text('Start Free Walk'), findsOneWidget);

    await _pumpFlowFitAppAt(tester, '/workout/select-type');

    await tester.ensureVisible(find.text('Resistance Training'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Resistance Training'));
    await tester.pumpAndSettle();

    expect(find.text('Choose Your Split'), findsOneWidget);
    expect(find.text('Chest, Back, Shoulders, Arms'), findsOneWidget);
  });

  const settingsDestinations = <String, String>{
    'Privacy Policy': 'FlowFit is built for fitness',
    'Notification Reminder': 'Achievement Notifications',
    'App Integration': 'Set up Galaxy Watch sensors',
    'Language': 'Select your preferred language',
    'Units': 'Measurement System',
    'Delete Account': 'Submitting this request will:',
    'Terms of Service': 'Acceptance of Terms',
    'Help & Support': 'Email Support',
    'About Us': 'Meet the team behind FlowFit',
  };

  for (final destination in settingsDestinations.entries) {
    testWidgets('settings ${destination.key} opens its production route', (
      tester,
    ) async {
      await _pumpFlowFitAppAt(tester, '/settings');

      final item = find.text(destination.key);
      await tester.ensureVisible(item);
      await tester.pumpAndSettle();
      await tester.tap(item);
      await tester.pumpAndSettle();

      expect(find.textContaining(destination.value), findsWidgets);
    });
  }
}

Future<void> _pumpFlowFitAppAt(WidgetTester tester, String routeName) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(_UnauthenticatedAuth()),
        buddyPendingSyncUserIdProvider.overrideWithValue(null),
        buddyPendingSyncActionProvider.overrideWithValue(() async {}),
        wellness.sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const FlowFitPhoneApp(),
    ),
  );
  await tester.pump();

  final navigator = tester.state<NavigatorState>(find.byType(Navigator));
  navigator.pushReplacementNamed(routeName);
  await tester.pumpAndSettle();
  await tester.pump(const Duration(seconds: 3));
  await tester.pumpAndSettle();
}

class _UnauthenticatedAuth implements IAuthRepository {
  @override
  Stream<User?> authStateChanges() => const Stream<User?>.empty();

  @override
  Future<User?> getCurrentUser() async => null;

  @override
  Future<void> signOut() async {}

  @override
  Future<User> signIn({required String email, required String password}) {
    throw UnimplementedError();
  }

  @override
  Future<User> signUp({
    required String email,
    required String password,
    required String fullName,
    required Map<String, dynamic> metadata,
  }) {
    throw UnimplementedError();
  }
}
