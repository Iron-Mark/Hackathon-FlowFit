import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Supabase client configuration files', () {
    test('secrets example documents publishable-key client config', () {
      final example = File('lib/secrets.dart.example').readAsStringSync();

      expect(example, contains('class SupabaseConfig'));
      expect(example, contains('static const String url'));
      expect(example, contains('static const String publishableKey'));
      expect(example, contains('anonKey = publishableKey'));
      expect(example, isNot(contains('service_role')));
      expect(example, isNot(contains('sb_secret_')));
    });

    test('app uses tracked build-time Supabase config', () {
      final main = File('lib/main.dart').readAsStringSync();
      final runtimeConfig = File(
        'lib/core/config/supabase_runtime_config.dart',
      ).readAsStringSync();

      expect(main, isNot(contains("import 'secrets.dart';")));
      expect(main, contains('SupabaseRuntimeConfig.url'));
      expect(main, contains('SupabaseRuntimeConfig.publishableKey'));
      expect(runtimeConfig, contains("String.fromEnvironment("));
      expect(runtimeConfig, contains("'SUPABASE_URL'"));
      expect(runtimeConfig, contains("'SUPABASE_PUBLISHABLE_KEY'"));
      expect(main, contains('SupabaseRuntimeConfig.validate();'));
      expect(runtimeConfig, contains('service_role'));
      expect(runtimeConfig, contains('sb_secret_'));
      expect(runtimeConfig, isNot(contains("defaultValue: 'service_role")));
      expect(runtimeConfig, isNot(contains("defaultValue: 'sb_secret_")));
    });

    test('ignored local secrets file does not contain server-only keys', () {
      final localSecrets = File('lib/secrets.dart');
      if (!localSecrets.existsSync()) {
        return;
      }

      final source = localSecrets.readAsStringSync();
      expect(source, isNot(contains('service_role')));
      expect(source, isNot(contains('sb_secret_')));
      expect(source, isNot(contains('dnasghxxqwibwqnljvxr')));
    });

    test(
      'store release wrapper requires production Supabase client config',
      () {
        final script = File(
          'scripts/store_release_build.ps1',
        ).readAsStringSync();

        expect(script, contains('function Assert-SupabaseClientConfig'));
        expect(script, contains('Assert-SupabaseClientConfig'));
        expect(script, contains('SUPABASE_URL'));
        expect(script, contains('SUPABASE_PUBLISHABLE_KEY'));
        expect(script, contains('--dart-define=SUPABASE_URL='));
        expect(script, contains('--dart-define=SUPABASE_PUBLISHABLE_KEY='));
        expect(
          script,
          contains('YOUR_|REPLACE_WITH|<your-|dnasghxxqwibwqnljvxr'),
        );
        expect(script, contains('sb_publishable_'));

        final assertionIndex = script.lastIndexOf(
          'Assert-SupabaseClientConfig',
        );
        final pubGetIndex = script.lastIndexOf(
          "Invoke-CheckedCommand 'Flutter dependencies'",
        );
        final androidIndex = script.lastIndexOf('Invoke-AndroidReleaseBuild');
        final iosIndex = script.lastIndexOf('Invoke-IosReleaseBuild');
        final webIndex = script.lastIndexOf('Invoke-WebReleaseBuild');

        expect(assertionIndex, greaterThanOrEqualTo(0));
        expect(pubGetIndex, greaterThanOrEqualTo(0));
        expect(androidIndex, greaterThanOrEqualTo(0));
        expect(iosIndex, greaterThanOrEqualTo(0));
        expect(webIndex, greaterThanOrEqualTo(0));
        expect(assertionIndex, lessThan(pubGetIndex));
        expect(assertionIndex, lessThan(androidIndex));
        expect(assertionIndex, lessThan(iosIndex));
        expect(assertionIndex, lessThan(webIndex));
      },
    );
  });
}
