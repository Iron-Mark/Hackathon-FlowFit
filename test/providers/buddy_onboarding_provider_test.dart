import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flowfit/providers/buddy_onboarding_provider.dart';
import 'package:flowfit/providers/shared_preferences_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BuddyOnboardingNotifier', () {
    late ProviderContainer container;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state is empty', () {
      final state = container.read(buddyOnboardingProvider);

      expect(state.selectedColor, isNull);
      expect(state.buddyName, isNull);
      expect(state.userNickname, isNull);
      expect(state.userAge, isNull);
      expect(state.isComplete, false);
    });

    test('selectColor updates selectedColor', () {
      final notifier = container.read(buddyOnboardingProvider.notifier);

      notifier.selectColor('blue');

      final state = container.read(buddyOnboardingProvider);
      expect(state.selectedColor, 'blue');
    });

    test('selectColor can be changed multiple times', () {
      final notifier = container.read(buddyOnboardingProvider.notifier);

      notifier.selectColor('blue');
      expect(container.read(buddyOnboardingProvider).selectedColor, 'blue');

      notifier.selectColor('green');
      expect(container.read(buddyOnboardingProvider).selectedColor, 'green');

      notifier.selectColor('purple');
      expect(container.read(buddyOnboardingProvider).selectedColor, 'purple');
    });

    test('setBuddyName updates buddyName', () {
      final notifier = container.read(buddyOnboardingProvider.notifier);

      notifier.setBuddyName('Sparky');

      final state = container.read(buddyOnboardingProvider);
      expect(state.buddyName, 'Sparky');
    });

    test('setUserInfo updates nickname and age', () {
      final notifier = container.read(buddyOnboardingProvider.notifier);

      notifier.setUserInfo('Alex', 10);

      final state = container.read(buddyOnboardingProvider);
      expect(state.userNickname, 'Alex');
      expect(state.userAge, 10);
    });

    test('setUserInfo accepts null values', () {
      final notifier = container.read(buddyOnboardingProvider.notifier);

      notifier.setUserInfo(null, null);

      final state = container.read(buddyOnboardingProvider);
      expect(state.userNickname, isNull);
      expect(state.userAge, isNull);
    });

    test('setUserInfo can set only nickname', () {
      final notifier = container.read(buddyOnboardingProvider.notifier);

      notifier.setUserInfo('Sam', null);

      final state = container.read(buddyOnboardingProvider);
      expect(state.userNickname, 'Sam');
      expect(state.userAge, isNull);
    });

    test('setUserInfo can set only age', () {
      final notifier = container.read(buddyOnboardingProvider.notifier);

      notifier.setUserInfo(null, 12);

      final state = container.read(buddyOnboardingProvider);
      expect(state.userNickname, isNull);
      expect(state.userAge, 12);
    });

    group('validateBuddyName', () {
      test('returns error for empty name', () {
        final notifier = container.read(buddyOnboardingProvider.notifier);

        final error = notifier.validateBuddyName('');

        expect(error, isNotNull);
        expect(error, contains('name'));
      });

      test('returns error for whitespace-only name', () {
        final notifier = container.read(buddyOnboardingProvider.notifier);

        final error = notifier.validateBuddyName('   ');

        expect(error, isNotNull);
        expect(error, contains('name'));
      });

      test('returns error for name longer than 20 characters', () {
        final notifier = container.read(buddyOnboardingProvider.notifier);

        final error = notifier.validateBuddyName(
          'ThisNameIsWayTooLongForABuddy',
        );

        expect(error, isNotNull);
        expect(error, contains('long'));
      });

      test('returns null for valid name', () {
        final notifier = container.read(buddyOnboardingProvider.notifier);

        final error = notifier.validateBuddyName('Sparky');

        expect(error, isNull);
      });

      test('returns null for name with exactly 20 characters', () {
        final notifier = container.read(buddyOnboardingProvider.notifier);

        final error = notifier.validateBuddyName('12345678901234567890');

        expect(error, isNull);
      });

      test('returns null for single character name', () {
        final notifier = container.read(buddyOnboardingProvider.notifier);

        final error = notifier.validateBuddyName('A');

        expect(error, isNull);
      });

      test('trims whitespace before validation', () {
        final notifier = container.read(buddyOnboardingProvider.notifier);

        final error = notifier.validateBuddyName('  Sparky  ');

        expect(error, isNull);
      });
    });

    test('reset clears all state', () {
      final notifier = container.read(buddyOnboardingProvider.notifier);

      // Set some state
      notifier.selectColor('blue');
      notifier.setBuddyName('Sparky');
      notifier.setUserInfo('Alex', 10);

      // Verify state is set
      var state = container.read(buddyOnboardingProvider);
      expect(state.selectedColor, 'blue');
      expect(state.buddyName, 'Sparky');
      expect(state.userNickname, 'Alex');
      expect(state.userAge, 10);

      // Reset
      notifier.reset();

      // Verify state is cleared
      state = container.read(buddyOnboardingProvider);
      expect(state.selectedColor, isNull);
      expect(state.buddyName, isNull);
      expect(state.userNickname, isNull);
      expect(state.userAge, isNull);
      expect(state.isComplete, false);
    });

    test('state updates are independent', () {
      final notifier = container.read(buddyOnboardingProvider.notifier);

      notifier.selectColor('blue');
      expect(container.read(buddyOnboardingProvider).selectedColor, 'blue');
      expect(container.read(buddyOnboardingProvider).buddyName, isNull);

      notifier.setBuddyName('Flash');
      expect(container.read(buddyOnboardingProvider).selectedColor, 'blue');
      expect(container.read(buddyOnboardingProvider).buddyName, 'Flash');
      expect(container.read(buddyOnboardingProvider).userNickname, isNull);

      notifier.setUserInfo('Jordan', 11);
      expect(container.read(buddyOnboardingProvider).selectedColor, 'blue');
      expect(container.read(buddyOnboardingProvider).buddyName, 'Flash');
      expect(container.read(buddyOnboardingProvider).userNickname, 'Jordan');
      expect(container.read(buddyOnboardingProvider).userAge, 11);
    });
  });
}
