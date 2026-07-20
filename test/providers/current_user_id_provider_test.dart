import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:flowfit/providers/current_user_id_provider.dart';
import 'package:flowfit/providers/running_session_provider.dart';

void main() {
  test('re-reads the live user id on every auth event '
      '(signed-out cold start cannot poison a null id)', () async {
    final events = StreamController<AuthState>.broadcast();
    addTearDown(events.close);

    String? liveUserId; // starts signed out
    final container = ProviderContainer(
      overrides: [
        supabaseAuthEventsProvider.overrideWith((ref) => events.stream),
        supabaseUserIdReaderProvider.overrideWithValue(() => liveUserId),
      ],
    );
    addTearDown(container.dispose);

    expect(container.read(currentUserIdProvider), isNull);

    // User signs in mid-process; an auth event fires.
    liveUserId = 'auth-user-1';
    events.add(const AuthState(AuthChangeEvent.signedIn, null));
    await Future<void>.delayed(Duration.zero);

    expect(container.read(currentUserIdProvider), 'auth-user-1');

    // Sign-out must clear it again.
    liveUserId = null;
    events.add(const AuthState(AuthChangeEvent.signedOut, null));
    await Future<void>.delayed(Duration.zero);

    expect(container.read(currentUserIdProvider), isNull);
  });

  test('workoutSessionUserIdProvider reflects the auth-reactive source', () {
    final container = ProviderContainer(
      overrides: [currentUserIdProvider.overrideWithValue('auth-user-2')],
    );
    addTearDown(container.dispose);

    expect(container.read(workoutSessionUserIdProvider), 'auth-user-2');
  });
}
