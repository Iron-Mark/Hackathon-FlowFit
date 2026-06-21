import 'package:flowfit/screens/profile/settings/delete_account_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  testWidgets('delete account requires the permanent action checkbox', (
    tester,
  ) async {
    var actionCalled = false;

    await tester.pumpWidget(
      _buildScreen(
        deleteAccount: ({required String password}) async {
          actionCalled = true;
        },
      ),
    );

    await _enterValidDeletionForm(tester);
    await _tapDeleteAccount(tester);
    await tester.pump();

    expect(
      find.text('Please confirm that you want to delete your account'),
      findsOneWidget,
    );
    expect(actionCalled, isFalse);
  });

  testWidgets('delete account validates confirmation text and password', (
    tester,
  ) async {
    var actionCalled = false;

    await tester.pumpWidget(
      _buildScreen(
        deleteAccount: ({required String password}) async {
          actionCalled = true;
        },
      ),
    );

    await tester.enterText(find.widgetWithText(TextFormField, 'DELETE'), 'DEL');
    await tester.ensureVisible(find.byType(Checkbox));
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    await _tapDeleteAccount(tester);
    await tester.pumpAndSettle();

    expect(
      find.text('Type DELETE to confirm account deletion'),
      findsOneWidget,
    );
    expect(find.text('Enter your account password'), findsOneWidget);
    expect(actionCalled, isFalse);
  });

  testWidgets('delete account confirms and submits the injected action', (
    tester,
  ) async {
    String? submittedPassword;

    await tester.pumpWidget(
      _buildScreen(
        deleteAccount: ({required String password}) async {
          submittedPassword = password;
        },
      ),
    );

    await _enterValidDeletionForm(tester);
    await _setPermanentCheckbox(tester);
    await _tapDeleteAccount(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(TextButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(submittedPassword, 'current-password-123');
    expect(find.text('Welcome route'), findsOneWidget);
    expect(find.text('Account deletion request submitted'), findsOneWidget);
  });

  testWidgets('delete account ignores duplicate confirmation requests', (
    tester,
  ) async {
    var actionCalled = false;

    await tester.pumpWidget(
      _buildScreen(
        deleteAccount: ({required String password}) async {
          actionCalled = true;
        },
      ),
    );

    await _enterValidDeletionForm(tester);
    await _setPermanentCheckbox(tester);
    await tester.ensureVisible(
      find.widgetWithText(ElevatedButton, 'Delete My Account'),
    );
    final button = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Delete My Account'),
    );
    final onPressed = button.onPressed!;

    onPressed();
    onPressed();
    await tester.pumpAndSettle();

    expect(find.text('Delete Account?'), findsOneWidget);
    expect(
      tester
          .widget<ElevatedButton>(
            find.widgetWithText(ElevatedButton, 'Delete My Account'),
          )
          .onPressed,
      isNull,
    );
    expect(actionCalled, isFalse);

    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Delete Account'), findsOneWidget);
    expect(actionCalled, isFalse);
  });

  testWidgets('delete account final confirmation can be cancelled', (
    tester,
  ) async {
    var actionCalled = false;

    await tester.pumpWidget(
      _buildScreen(
        deleteAccount: ({required String password}) async {
          actionCalled = true;
        },
      ),
    );

    await _enterValidDeletionForm(tester);
    await _setPermanentCheckbox(tester);
    await _tapDeleteAccount(tester);
    await tester.pumpAndSettle();

    expect(find.text('Delete Account?'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await tester.pumpAndSettle();

    expect(actionCalled, isFalse);
    expect(find.text('Delete Account'), findsOneWidget);
    expect(find.text('Welcome route'), findsNothing);
  });

  testWidgets('delete account surfaces auth errors without navigating', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildScreen(
        deleteAccount: ({required String password}) async {
          throw const AuthException('Invalid login credentials');
        },
      ),
    );

    await _enterValidDeletionForm(tester);
    await _setPermanentCheckbox(tester);
    await _tapDeleteAccount(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(TextButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(
      find.text('Please confirm your account password and try again.'),
      findsOneWidget,
    );
    expect(find.text('Welcome route'), findsNothing);
  });

  testWidgets('delete account page cancel button pops back', (tester) async {
    await tester.pumpWidget(
      _buildRoutedScreen(deleteAccount: ({required String password}) async {}),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.widgetWithText(OutlinedButton, 'Cancel'));
    await tester.tap(find.widgetWithText(OutlinedButton, 'Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Profile route'), findsOneWidget);
  });
}

Widget _buildScreen({required DeleteAccountAction deleteAccount}) {
  return MaterialApp(
    home: DeleteAccountScreen(deleteAccount: deleteAccount),
    routes: {'/welcome': (_) => const Scaffold(body: Text('Welcome route'))},
  );
}

Widget _buildRoutedScreen({required DeleteAccountAction deleteAccount}) {
  return MaterialApp(
    initialRoute: '/delete-account',
    routes: {
      '/': (_) => const Scaffold(body: Text('Profile route')),
      '/delete-account': (_) =>
          DeleteAccountScreen(deleteAccount: deleteAccount),
      '/welcome': (_) => const Scaffold(body: Text('Welcome route')),
    },
  );
}

Future<void> _enterValidDeletionForm(WidgetTester tester) async {
  await tester.enterText(
    find.widgetWithText(TextFormField, 'DELETE'),
    'DELETE',
  );
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Account password'),
    'current-password-123',
  );
}

Future<void> _setPermanentCheckbox(WidgetTester tester) async {
  await tester.ensureVisible(find.byType(Checkbox));
  await tester.tap(find.byType(Checkbox));
  await tester.pumpAndSettle();
}

Future<void> _tapDeleteAccount(WidgetTester tester) async {
  final button = find.widgetWithText(ElevatedButton, 'Delete My Account');
  await tester.ensureVisible(button);
  await tester.pumpAndSettle();
  await tester.tap(button);
}
