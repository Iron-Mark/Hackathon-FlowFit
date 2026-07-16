/// Redacts Supabase publishable/secret keys and JWTs from startup errors
/// before they are reported or rendered on the startup error screen.
String redactStartupError(Object error) {
  return error
      .toString()
      .replaceFirst(RegExp(r'^Bad state:\s*'), '')
      .replaceAllMapped(
        RegExp(r'sb_(publishable|secret)_[A-Za-z0-9_-]+'),
        (match) => 'sb_${match.group(1)}_<redacted>',
      )
      .replaceAll(
        RegExp(r'eyJ[A-Za-z0-9_-]+(?:\.[A-Za-z0-9_-]+){2,}'),
        '<redacted-jwt>',
      );
}
