import 'dart:async';

import 'package:flowfit/screens/profile/settings/change_password_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solar_icons/solar_icons.dart';
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

  testWidgets('change password ignores duplicate in-flight submissions', (
    tester,
  ) async {
    final actionCompleter = Completer<void>();
    var actionCalls = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: ChangePasswordScreen(
          changePassword:
              ({
                required String currentPassword,
                required String newPassword,
              }) async {
                actionCalls++;
                await actionCompleter.future;
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

    await tester.ensureVisible(
      find.widgetWithText(ElevatedButton, 'Change Password'),
    );
    final button = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Change Password'),
    );
    final onPressed = button.onPressed!;

    onPressed();
    onPressed();
    await tester.pump();

    expect(actionCalls, 1);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    actionCompleter.complete();
    await tester.pumpAndSettle();

    expect(actionCalls, 1);
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

  testWidgets('password visibility buttons toggle every password field', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ChangePasswordScreen(
          changePassword:
              ({
                required String currentPassword,
                required String newPassword,
              }) async {},
        ),
      ),
    );

    expect(_isObscured(tester, 'Enter current password'), isTrue);
    expect(_isObscured(tester, 'Enter new password'), isTrue);
    expect(_isObscured(tester, 'Confirm new password'), isTrue);

    await tester.tap(find.byIcon(SolarIconsOutline.eyeClosed).at(0));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(SolarIconsOutline.eyeClosed).at(0));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(SolarIconsOutline.eyeClosed).at(0));
    await tester.pumpAndSettle();

    expect(_isObscured(tester, 'Enter current password'), isFalse);
    expect(_isObscured(tester, 'Enter new password'), isFalse);
    expect(_isObscured(tester, 'Confirm new password'), isFalse);

    await tester.tap(find.byIcon(SolarIconsOutline.eye).at(0));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(SolarIconsOutline.eye).at(0));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(SolarIconsOutline.eye).at(0));
    await tester.pumpAndSettle();

    expect(_isObscured(tester, 'Enter current password'), isTrue);
    expect(_isObscured(tester, 'Enter new password'), isTrue);
    expect(_isObscured(tester, 'Confirm new password'), isTrue);
  });

  testWidgets('change password validates mismatched confirmation', (
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
      'old-password-123',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Enter new password'),
      'new-password-123',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Confirm new password'),
      'different-password-123',
    );

    await _tapChangePassword(tester);
    await tester.pumpAndSettle();

    expect(find.text('Passwords do not match'), findsOneWidget);
    expect(actionCalled, isFalse);
  });
}

bool _isObscured(WidgetTester tester, String hintText) {
  final editableText = find.descendant(
    of: find.widgetWithText(TextFormField, hintText),
    matching: find.byType(EditableText),
  );
  return tester.widget<EditableText>(editableText).obscureText;
}

Future<void> _tapChangePassword(WidgetTester tester) async {
  final button = find.widgetWithText(ElevatedButton, 'Change Password');
  await tester.ensureVisible(button);
  await tester.pumpAndSettle();
  await tester.tap(button);
}
