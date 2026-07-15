import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flowfit/services/buddy_offline_storage.dart';

/// Provider for SharedPreferences instance
final sharedPreferencesProvider = FutureProvider<SharedPreferences>((
  ref,
) async {
  return await SharedPreferences.getInstance();
});

/// Provider for BuddyOfflineStorage service
final buddyOfflineStorageProvider = Provider<BuddyOfflineStorage?>((ref) {
  final prefsAsync = ref.watch(sharedPreferencesProvider);

  return prefsAsync.when(
    data: (prefs) => BuddyOfflineStorage(prefs),
    loading: () => null,
    error: (_, __) => null,
  );
});
