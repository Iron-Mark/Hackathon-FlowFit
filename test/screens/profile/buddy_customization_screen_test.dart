import 'package:flowfit/models/buddy_profile.dart';
import 'package:flowfit/providers/buddy_profile_provider.dart';
import 'package:flowfit/screens/profile/buddy_customization_screen.dart';
import 'package:flowfit/utils/buddy_customization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Buddy customization Save persists hydrated selections', (
    tester,
  ) async {
    final saved = <_SavedBuddyCustomization>[];

    await tester.pumpWidget(
      _harness(
        profile: _profile(
          name: 'Splashy',
          color: 'purple',
          accessories: const {
            buddyAccessoryKey: 'crown',
            buddyBackgroundKey: 'ocean',
            'favorite_food': 'kelp',
          },
        ),
        onSave: (userId, updates) async {
          saved.add(_SavedBuddyCustomization(userId, updates));
        },
      ),
    );
    await tester.pump();

    expect(find.text('Splashy'), findsOneWidget);
    expect(find.text('👑'), findsOneWidget);

    await tester.tap(find.text('Rename'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), '  Wavey  ');
    await tester.tap(find.widgetWithText(TextButton, 'Save'));
    await tester.pumpAndSettle();

    expect(saved, hasLength(1));
    expect(saved.single.userId, 'user-1');
    expect(saved.single.updates['name'], 'Wavey');
    expect(saved.single.updates['color'], 'purple');
    expect(saved.single.updates['accessories'], const {
      buddyAccessoryKey: 'crown',
      buddyBackgroundKey: 'ocean',
      'favorite_food': 'kelp',
    });
    expect(find.text('Root Route'), findsOneWidget);
  });

  testWidgets('Buddy customization rejects blank rename before save', (
    tester,
  ) async {
    var saveCalls = 0;

    await tester.pumpWidget(
      _harness(
        profile: _profile(),
        onSave: (_, __) async {
          saveCalls++;
        },
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Rename'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), '   ');
    await tester.tap(find.widgetWithText(TextButton, 'Save'));
    await tester.pump();

    expect(saveCalls, 0);
    expect(find.text('Buddy name must be 1-20 characters.'), findsOneWidget);
    expect(find.text('Customize Your Buddy'), findsOneWidget);
  });

  testWidgets('Buddy customization tabs update saved visual selections', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final saved = <_SavedBuddyCustomization>[];

    await tester.pumpWidget(
      _harness(
        profile: _profile(level: 10),
        onSave: (userId, updates) async {
          saved.add(_SavedBuddyCustomization(userId, updates));
        },
      ),
    );
    await tester.pump();

    try {
      await tester.tap(find.bySemanticsLabel('Buddy color Fresh Green'));
    } finally {
      semantics.dispose();
    }
    await tester.pump();
    await tester.tap(find.text('Accessories'));
    await tester.pump();
    await tester.tap(find.text('Top Hat'));
    await tester.pump();
    await tester.tap(find.text('Background'));
    await tester.pump();
    await tester.tap(find.text('Sunset'));
    await tester.pump();
    await tester.tap(find.widgetWithText(TextButton, 'Save'));
    await tester.pumpAndSettle();

    expect(saved, hasLength(1));
    expect(saved.single.updates['color'], 'green');
    expect(saved.single.updates['accessories'], {
      buddyAccessoryKey: 'hat',
      buddyBackgroundKey: 'sunset',
    });
    expect(find.text('Root Route'), findsOneWidget);
  });

  testWidgets('Buddy customization surfaces save failures with retry action', (
    tester,
  ) async {
    var saveCalls = 0;

    await tester.pumpWidget(
      _harness(
        profile: _profile(),
        onSave: (_, __) async {
          saveCalls++;
          throw StateError('network down');
        },
      ),
    );
    await tester.pump();

    await tester.tap(find.widgetWithText(TextButton, 'Save'));
    await tester.pump();

    expect(saveCalls, 1);
    expect(find.textContaining('Failed to save:'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(find.text('Customize Your Buddy'), findsOneWidget);
  });
}

Widget _harness({
  required BuddyProfile profile,
  required BuddyCustomizationSave onSave,
}) {
  return ProviderScope(
    overrides: [
      buddyCustomizationCurrentUserIdProvider.overrideWithValue('user-1'),
      buddyCustomizationSaveProvider.overrideWithValue(onSave),
      buddyProfileNotifierProvider.overrideWith((ref, userId) {
        return _TestBuddyProfileNotifier(userId, profile);
      }),
    ],
    child: MaterialApp(
      initialRoute: '/customize',
      routes: {
        '/': (_) => const Scaffold(body: Center(child: Text('Root Route'))),
        '/customize': (_) => const BuddyCustomizationScreen(),
        '/buddy-welcome': (_) =>
            const Scaffold(body: Center(child: Text('Buddy Welcome Route'))),
      },
    ),
  );
}

BuddyProfile _profile({
  String name = 'Buddy',
  String color = 'blue',
  int level = 10,
  Map<String, dynamic>? accessories,
}) {
  return BuddyProfile(
    id: 'buddy-1',
    userId: 'user-1',
    name: name,
    color: color,
    level: level,
    xp: 900,
    accessories: accessories,
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
  );
}

class _TestBuddyProfileNotifier extends BuddyProfileNotifier {
  _TestBuddyProfileNotifier(super.userId, this.profile);

  final BuddyProfile profile;

  @override
  Future<void> loadProfile() async {
    state = AsyncValue.data(profile);
  }
}

class _SavedBuddyCustomization {
  const _SavedBuddyCustomization(this.userId, this.updates);

  final String userId;
  final Map<String, dynamic> updates;
}
