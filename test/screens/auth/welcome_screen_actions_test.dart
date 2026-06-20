import 'package:flowfit/domain/entities/user.dart';
import 'package:flowfit/domain/repositories/i_auth_repository.dart';
import 'package:flowfit/presentation/providers/providers.dart';
import 'package:flowfit/screens/auth/welcome_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildHarness() {
    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(_UnauthenticatedAuth()),
      ],
      child: MaterialApp(
        home: const WelcomeScreen(),
        routes: {
          '/signup': (_) => const Scaffold(body: Text('route:signup')),
          '/login': (_) => const Scaffold(body: Text('route:login')),
          '/dashboard': (_) => const Scaffold(body: Text('route:dashboard')),
        },
      ),
    );
  }

  testWidgets('Get Started opens signup', (tester) async {
    await tester.pumpWidget(buildHarness());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();

    expect(find.text('route:signup'), findsOneWidget);
  });

  testWidgets('Log In opens login', (tester) async {
    await tester.pumpWidget(buildHarness());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Log In'));
    await tester.pumpAndSettle();

    expect(find.text('route:login'), findsOneWidget);
  });
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
