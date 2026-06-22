import 'package:flowfit/core/config/flowfit_runtime_config.dart';
import 'package:flowfit/core/config/supabase_runtime_config.dart';
import 'package:flowfit/utils/deep_link_handler.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('auth redirect URLs use build-time mobile schemes by default', () {
    expect(
      FlowFitRuntimeConfig.authRedirectUrl(),
      'com.msiazondev.flowfit://auth-callback',
    );
    expect(
      FlowFitRuntimeConfig.authRedirectUrl(isDevelopment: true),
      'com.msiazondev.flowfit.dev://auth-callback',
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

  test('support email has a verified maintainer inbox fallback', () {
    expect(FlowFitRuntimeConfig.supportEmail, 'marksiazon.dev@gmail.com');
  });

  test('public web URL has a maintained fork fallback', () {
    expect(
      FlowFitRuntimeConfig.publicWebBaseUrl,
      'https://iron-mark.github.io/Hackathon-FlowFit',
    );
  });

  test('map tiles default to a non-OSM provider with reusable subdomains', () {
    expect(
      FlowFitRuntimeConfig.mapTileUrlTemplate,
      'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
    );
    expect(FlowFitRuntimeConfig.mapTileSubdomains, ['a', 'b', 'c']);
    expect(
      FlowFitRuntimeConfig.mapTileUrl(x: 1, y: 2, zoom: 3),
      'https://a.basemaps.cartocdn.com/rastertiles/voyager/3/1/2.png',
    );
  });

  test('public web URL honors dart define override when expected', () {
    const expectedOverride = String.fromEnvironment(
      'FLOWFIT_EXPECTED_PUBLIC_WEB_BASE_URL',
    );
    if (expectedOverride.isEmpty) {
      return;
    }

    expect(FlowFitRuntimeConfig.publicWebBaseUrl, expectedOverride);
  });

  test('Supabase client config is supplied through build-time defines', () {
    expect(SupabaseRuntimeConfig.url, 'https://YOUR_PROJECT_REF.supabase.co');
    expect(SupabaseRuntimeConfig.publishableKey, 'sb_publishable_YOUR_KEY');
    expect(SupabaseRuntimeConfig.anonKey, SupabaseRuntimeConfig.publishableKey);
    expect(SupabaseRuntimeConfig.validate, throwsStateError);
  });
}
