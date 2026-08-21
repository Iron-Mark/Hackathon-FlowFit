import 'dart:io';

import 'package:flowfit/utils/deep_link_handler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  tearDown(() {
    DeepLinkHandler.resetInternalAuthFlowSuppressionForTest();
  });

  test('email-link handler routes verified users through the age gate', () {
    final source = File('lib/utils/deep_link_handler.dart').readAsStringSync();
    expect(source, contains("'/age-gate'"));
    expect(source, contains("arguments: {'userId': user.id}"));
    expect(source, isNot(contains("'/survey_intro'")));
    expect(source, isNot(contains("'email': user.email")));
  });

  test(
    'verified sign-in can navigate to age gate outside internal auth flows',
    () {
      expect(
        DeepLinkHandler.shouldNavigateToSurveyForAuthEvent(
          event: AuthChangeEvent.signedIn,
          hasSession: true,
          emailConfirmed: true,
        ),
        isTrue,
      );
    },
  );

  test('account deletion reauth sign-in does not navigate to age gate', () {
    DeepLinkHandler.beginInternalAuthFlow();

    expect(
      DeepLinkHandler.shouldNavigateToSurveyForAuthEvent(
        event: AuthChangeEvent.signedIn,
        hasSession: true,
        emailConfirmed: true,
      ),
      isFalse,
    );
  });

  test(
    'unverified and non-sign-in auth events do not navigate to age gate',
    () {
      expect(
        DeepLinkHandler.shouldNavigateToSurveyForAuthEvent(
          event: AuthChangeEvent.signedIn,
          hasSession: true,
          emailConfirmed: false,
        ),
        isFalse,
      );
      expect(
        DeepLinkHandler.shouldNavigateToSurveyForAuthEvent(
          event: AuthChangeEvent.tokenRefreshed,
          hasSession: true,
          emailConfirmed: true,
        ),
        isFalse,
      );
    },
  );
}
