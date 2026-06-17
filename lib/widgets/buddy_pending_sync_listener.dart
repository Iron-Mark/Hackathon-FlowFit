import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../providers/buddy_onboarding_provider.dart';

final buddyPendingSyncUserIdProvider = Provider.autoDispose<String?>((ref) {
  return Supabase.instance.client.auth.currentUser?.id;
});

final buddyPendingSyncActionProvider = Provider<Future<void> Function()>((ref) {
  return () async {
    final userId = ref.read(buddyPendingSyncUserIdProvider);
    if (userId == null || userId.isEmpty) {
      return;
    }

    await ref
        .read(buddyOnboardingProvider.notifier)
        .syncPendingProfile(expectedUserId: userId);
  };
});

class BuddyPendingSyncListener extends ConsumerStatefulWidget {
  final Widget child;

  const BuddyPendingSyncListener({super.key, required this.child});

  @override
  ConsumerState<BuddyPendingSyncListener> createState() =>
      _BuddyPendingSyncListenerState();
}

class _BuddyPendingSyncListenerState
    extends ConsumerState<BuddyPendingSyncListener>
    with WidgetsBindingObserver {
  bool _syncInFlight = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncPendingBuddyProfile();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _syncPendingBuddyProfile();
    }
  }

  Future<void> _syncPendingBuddyProfile() async {
    if (_syncInFlight || !mounted) {
      return;
    }

    final userId = ref.read(buddyPendingSyncUserIdProvider);
    if (userId == null || userId.isEmpty) {
      return;
    }

    _syncInFlight = true;
    try {
      await ref.read(buddyPendingSyncActionProvider)();
    } catch (_) {
      // Pending Buddy sync is best-effort and remains queued for the next resume.
    } finally {
      _syncInFlight = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
