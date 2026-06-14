import 'package:flowfit/utils/deep_link_handler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  tearDown(() {
    DeepLinkHandler.resetInternalAuthFlowSuppressionForTest();
  });

  test(
    'verified sign-in can navigate to survey outside internal auth flows',
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

  test('account deletion reauth sign-in does not navigate to survey', () {
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

  test('unverified and non-sign-in auth events do not navigate to survey', () {
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
  });
}
