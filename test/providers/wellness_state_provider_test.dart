import 'package:flowfit/providers/wellness_state_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('sharedPreferencesProvider fails with an override contract error', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(
      () => container.read(sharedPreferencesProvider),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          contains('must be overridden'),
        ),
      ),
    );
  });
}
