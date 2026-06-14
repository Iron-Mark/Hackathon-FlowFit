import 'package:flowfit/core/config/flowfit_runtime_config.dart';
import 'package:flowfit/core/config/supabase_runtime_config.dart';
import 'package:flowfit/utils/deep_link_handler.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('auth redirect URLs use build-time mobile schemes by default', () {
    expect(
      FlowFitRuntimeConfig.authRedirectUrl(),
      'com.oldstlabs.flowfit://auth-callback',
    );
    expect(
      FlowFitRuntimeConfig.authRedirectUrl(isDevelopment: true),
      'com.oldstlabs.flowfit.dev://auth-callback',
    );
  });

  test('deep link helper delegates to the runtime redirect config', () {
    expect(
      DeepLinkHandler.getRedirectUrl(),
      FlowFitRuntimeConfig.authRedirectUrl(),
    );
    expect(
      DeepLinkHandler.getRedirectUrl(isDevelopment: true),
      FlowFitRuntimeConfig.authRedirectUrl(isDevelopment: true),
    );
  });

  test('support email has a store-ready default', () {
    expect(FlowFitRuntimeConfig.supportEmail, 'support@flowfit.com');
  });

  test('Supabase client config is supplied through build-time defines', () {
    expect(SupabaseRuntimeConfig.url, 'https://YOUR_PROJECT_REF.supabase.co');
    expect(SupabaseRuntimeConfig.publishableKey, 'sb_publishable_YOUR_KEY');
    expect(SupabaseRuntimeConfig.anonKey, SupabaseRuntimeConfig.publishableKey);
    expect(SupabaseRuntimeConfig.validate, throwsStateError);
  });
}
