import 'dart:io';

import 'package:flowfit/widgets/buddy_pending_sync_listener.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  test('default Buddy pending sync user lookup is auto-disposed', () {
    final source = File(
      'lib/widgets/buddy_pending_sync_listener.dart',
    ).readAsStringSync();

    expect(
      source,
      contains('buddyPendingSyncUserIdProvider = Provider.autoDispose'),
    );
  });

  testWidgets('runs pending Buddy sync once on startup for a signed-in user', (
    tester,
  ) async {
    var syncCount = 0;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          buddyPendingSyncUserIdProvider.overrideWithValue('auth-user-1'),
          buddyPendingSyncActionProvider.overrideWithValue(() async {
            syncCount++;
          }),
        ],
        child: const MaterialApp(
          home: BuddyPendingSyncListener(child: Text('FlowFit')),
        ),
      ),
    );
    await tester.pump();

    expect(syncCount, 1);
  });

  testWidgets('skips pending Buddy sync when no user is signed in', (
    tester,
  ) async {
    var syncCount = 0;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          buddyPendingSyncUserIdProvider.overrideWithValue(null),
          buddyPendingSyncActionProvider.overrideWithValue(() async {
            syncCount++;
          }),
        ],
        child: const MaterialApp(
          home: BuddyPendingSyncListener(child: Text('FlowFit')),
        ),
      ),
    );
    await tester.pump();

    expect(syncCount, 0);
  });

  testWidgets('retries pending Buddy sync when the app resumes', (
    tester,
  ) async {
    var syncCount = 0;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          buddyPendingSyncUserIdProvider.overrideWithValue('auth-user-1'),
          buddyPendingSyncActionProvider.overrideWithValue(() async {
            syncCount++;
          }),
        ],
        child: const MaterialApp(
          home: BuddyPendingSyncListener(child: Text('FlowFit')),
        ),
      ),
    );
    await tester.pump();

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();

    expect(syncCount, 2);
  });
}
