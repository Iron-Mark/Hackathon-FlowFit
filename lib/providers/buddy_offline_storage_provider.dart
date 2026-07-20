import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flowfit/providers/shared_preferences_provider.dart';
import 'package:flowfit/services/storage/buddy_offline_storage.dart';

/// Provider for BuddyOfflineStorage service, backed by the canonical
/// SharedPreferences provider (overridden in main.dart and in tests).
final buddyOfflineStorageProvider = Provider<BuddyOfflineStorage?>((ref) {
  return BuddyOfflineStorage(ref.watch(sharedPreferencesProvider));
});
