import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Raw Supabase auth events. onAuthStateChange is a broadcast stream, so this
/// coexists safely with the existing listeners in DeepLinkHandler and the
/// email verification screen.
final supabaseAuthEventsProvider = StreamProvider<AuthState>(
  (ref) => Supabase.instance.client.auth.onAuthStateChange,
);

/// Live read of the signed-in user id, overridable in tests so
/// [currentUserIdProvider]'s rebuild behavior can be exercised without an
/// initialized Supabase instance.
final supabaseUserIdReaderProvider = Provider<String? Function()>(
  (ref) =>
      () => Supabase.instance.client.auth.currentUser?.id,
);

/// Single source of truth for the signed-in user id. Rebuilds on every auth
/// event (INITIAL_SESSION / SIGNED_IN / SIGNED_OUT / TOKEN_REFRESHED), so it
/// can never cache a stale or null id for the process lifetime.
final currentUserIdProvider = Provider<String?>((ref) {
  ref.watch(supabaseAuthEventsProvider);
  return ref.watch(supabaseUserIdReaderProvider)();
});
