import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Canonical SharedPreferences provider for the whole app.
///
/// main.dart overrides this with the awaited instance at startup; tests
/// override it with mock prefs. It throws by design when un-overridden so a
/// missing override fails loudly instead of silently self-initializing a
/// second SharedPreferences path.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw StateError('SharedPreferences must be overridden in main.dart');
});
