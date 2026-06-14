/// Build-time Supabase client configuration.
///
/// Production, store, and web builds should pass these values with:
/// --dart-define=SUPABASE_URL=https://PROJECT_REF.supabase.co
/// --dart-define=SUPABASE_PUBLISHABLE_KEY=REPLACE_WITH_SUPABASE_PUBLISHABLE_KEY
class SupabaseRuntimeConfig {
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://YOUR_PROJECT_REF.supabase.co',
  );

  static const String publishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: 'sb_publishable_YOUR_KEY',
  );

  @Deprecated('Use publishableKey instead.')
  static const String anonKey = publishableKey;

  static void validate() {
    if (!_isValidSupabaseUrl(url)) {
      throw StateError(
        'SUPABASE_URL must be a real Supabase Project URL passed with '
        '--dart-define=SUPABASE_URL=...',
      );
    }

    if (!_isValidPublishableKey(publishableKey)) {
      throw StateError(
        'SUPABASE_PUBLISHABLE_KEY must be a real sb_publishable_ client key '
        'passed with --dart-define=SUPABASE_PUBLISHABLE_KEY=...',
      );
    }
  }

  static bool _isValidSupabaseUrl(String value) {
    if (_isPlaceholder(value)) {
      return false;
    }
    return RegExp(r'^https://[a-z0-9-]+\.supabase\.co$').hasMatch(value);
  }

  static bool _isValidPublishableKey(String value) {
    if (_isPlaceholder(value)) {
      return false;
    }
    return RegExp(r'^sb_publishable_[A-Za-z0-9_-]{20,}$').hasMatch(value);
  }

  static bool _isPlaceholder(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized.isEmpty) {
      return true;
    }
    return normalized.contains('your_') ||
        normalized.contains('replace_with') ||
        normalized.contains('<your-') ||
        normalized.contains('project_ref') ||
        normalized.contains('placeholder') ||
        normalized.contains('...') ||
        normalized.contains('dnasghxxqwibwqnljvxr') ||
        normalized.contains('sb_secret_') ||
        normalized.contains('service_role') ||
        normalized.contains('localhost') ||
        normalized.contains('127.0.0.1') ||
        normalized.contains('example.supabase.co') ||
        normalized.contains('smoke');
  }
}
