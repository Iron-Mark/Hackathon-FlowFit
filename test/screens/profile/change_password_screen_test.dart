import 'package:flowfit/screens/profile/settings/change_password_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  testWidgets('change password button calls the real action with form values', (
    tester,
  ) async {
    String? submittedCurrentPassword;
    String? submittedNewPassword;

    await tester.pumpWidget(
      MaterialApp(
        home: ChangePasswordScreen(
          changePassword:
              ({
                required String currentPassword,
                required String newPassword,
              }) async {
                submittedCurrentPassword = currentPassword;
                submittedNewPassword = newPassword;
              },
        ),
      ),
    );

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Enter current password'),
      'old-password-123',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Enter new password'),
      'new-password-123',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Confirm new password'),
      'new-password-123',
    );

    await _tapChangePassword(tester);
    await tester.pumpAndSettle();

    expect(submittedCurrentPassword, 'old-password-123');
    expect(submittedNewPassword, 'new-password-123');
  });

  testWidgets('change password shows auth errors without success feedback', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ChangePasswordScreen(
          changePassword:
              ({
                required String currentPassword,
                required String newPassword,
              }) async {
                throw const AuthException('Invalid login credentials');
              },
        ),
      ),
    );

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Enter current password'),
      'wrong-password',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Enter new password'),
      'new-password-123',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Confirm new password'),
      'new-password-123',
    );

    await _tapChangePassword(tester);
    await tester.pumpAndSettle();

    expect(
      find.text('Please confirm your current password and try again.'),
      findsOneWidget,
    );
    expect(find.text('Password changed successfully'), findsNothing);
  });

  testWidgets('change password rejects reusing the current password', (
    tester,
  ) async {
    var actionCalled = false;

    await tester.pumpWidget(
      MaterialApp(
        home: ChangePasswordScreen(
          changePassword:
              ({
                required String currentPassword,
                required String newPassword,
              }) async {
                actionCalled = true;
              },
        ),
      ),
    );

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Enter current password'),
      'same-password',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Enter new password'),
      'same-password',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Confirm new password'),
      'same-password',
    );

    await _tapChangePassword(tester);
    await tester.pumpAndSettle();

    expect(find.text('New password must be different'), findsOneWidget);
    expect(actionCalled, isFalse);
  });
}

Future<void> _tapChangePassword(WidgetTester tester) async {
  final button = find.widgetWithText(ElevatedButton, 'Change Password');
  await tester.ensureVisible(button);
  await tester.pumpAndSettle();
  await tester.tap(button);
}
