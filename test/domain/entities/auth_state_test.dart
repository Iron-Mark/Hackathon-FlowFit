import 'package:flutter_test/flutter_test.dart';
import 'package:flowfit/domain/entities/auth_state.dart';
import 'package:flowfit/domain/entities/user.dart';

void main() {
  group('AuthState', () {
    late User testUser;

    setUp(() {
      testUser = User(
        id: 'user_123',
        email: 'test@example.com',
        fullName: 'Test User',
        createdAt: DateTime(2024, 1, 1),
        emailConfirmedAt: DateTime(2024, 1, 1, 12, 0, 0),
      );
    });

    group('Factory Constructors', () {
      test('initial creates loading state', () {
        final state = AuthState.initial();

        expect(state.status, equals(AuthStatus.loading));
        expect(state.user, isNull);
        expect(state.errorMessage, isNull);
      });

      test('authenticated creates authenticated state with user', () {
        final state = AuthState.authenticated(testUser);

        expect(state.status, equals(AuthStatus.authenticated));
        expect(state.user, equals(testUser));
        expect(state.errorMessage, isNull);
      });

      test('unauthenticated creates unauthenticated state', () {
        final state = AuthState.unauthenticated();

        expect(state.status, equals(AuthStatus.unauthenticated));
        expect(state.user, isNull);
        expect(state.errorMessage, isNull);
      });

      test('error creates state with error message', () {
        final state = AuthState.error('Invalid credentials');

        expect(state.status, equals(AuthStatus.unauthenticated));
        expect(state.user, isNull);
        expect(state.errorMessage, equals('Invalid credentials'));
      });

      test('error can specify custom status', () {
        final state = AuthState.error(
          'Network error',
          status: AuthStatus.loading,
        );

        expect(state.status, equals(AuthStatus.loading));
        expect(state.errorMessage, equals('Network error'));
      });
    });

    group('copyWith', () {
      test('creates copy with updated status', () {
        final original = AuthState.authenticated(testUser);
        final copy = original.copyWith(status: AuthStatus.loading);

        expect(copy.status, equals(AuthStatus.loading));
        expect(copy.user, equals(testUser));
        expect(copy.errorMessage, isNull);
      });

      test('creates copy with updated user', () {
        final original = AuthState.authenticated(testUser);
        final newUser = testUser.copyWith(fullName: 'Updated Name');
        final copy = original.copyWith(user: newUser);

        expect(copy.status, equals(AuthStatus.authenticated));
        expect(copy.user, equals(newUser));
        expect(copy.user?.fullName, equals('Updated Name'));
      });

      test('creates copy with updated error message', () {
        final original = AuthState.authenticated(testUser);
        final copy = original.copyWith(errorMessage: 'New error');

        expect(copy.status, equals(AuthStatus.authenticated));
        expect(copy.user, equals(testUser));
        expect(copy.errorMessage, equals('New error'));
      });

      test('clears error when clearError is true', () {
        final original = AuthState.error('Some error');
        final copy = original.copyWith(clearError: true);

        expect(copy.errorMessage, isNull);
        expect(copy.status, equals(original.status));
      });

      test('clears user when clearUser is true', () {
        final original = AuthState.authenticated(testUser);
        final copy = original.copyWith(
          status: AuthStatus.unauthenticated,
          clearUser: true,
        );

        expect(copy.user, isNull);
        expect(copy.status, equals(AuthStatus.unauthenticated));
      });

      test('preserves values when no parameters provided', () {
        final original = AuthState.authenticated(testUser);
        final copy = original.copyWith();

        expect(copy.status, equals(original.status));
        expect(copy.user, equals(original.user));
        expect(copy.errorMessage, equals(original.errorMessage));
      });

      test('can update multiple fields at once', () {
        final original = AuthState.authenticated(testUser);
        final copy = original.copyWith(
          status: AuthStatus.loading,
          errorMessage: 'Refreshing...',
        );

        expect(copy.status, equals(AuthStatus.loading));
        expect(copy.user, equals(testUser));
        expect(copy.errorMessage, equals('Refreshing...'));
      });
    });

    group('Equality', () {
      test('two states with same values are equal', () {
        final state1 = AuthState.authenticated(testUser);
        final state2 = AuthState.authenticated(testUser);

        expect(state1, equals(state2));
        expect(state1.hashCode, equals(state2.hashCode));
      });

      test('two states with different status are not equal', () {
        final state1 = AuthState(
          status: AuthStatus.authenticated,
          user: testUser,
        );
        final state2 = AuthState(status: AuthStatus.loading, user: testUser);

        expect(state1, isNot(equals(state2)));
      });

      test('two states with different users are not equal', () {
        final user2 = testUser.copyWith(fullName: 'Different User');
        final state1 = AuthState.authenticated(testUser);
        final state2 = AuthState.authenticated(user2);

        expect(state1, isNot(equals(state2)));
      });

      test('two states with different error messages are not equal', () {
        final state1 = AuthState.error('Error 1');
        final state2 = AuthState.error('Error 2');

        expect(state1, isNot(equals(state2)));
      });

      test('state is equal to itself', () {
        final state = AuthState.authenticated(testUser);

        expect(state, equals(state));
      });

      test('initial states are equal', () {
        final state1 = AuthState.initial();
        final state2 = AuthState.initial();

        expect(state1, equals(state2));
      });

      test('unauthenticated states are equal', () {
        final state1 = AuthState.unauthenticated();
        final state2 = AuthState.unauthenticated();

        expect(state1, equals(state2));
      });
    });

    group('toString', () {
      test('includes all fields in string representation', () {
        final state = AuthState.authenticated(testUser);
        final string = state.toString();

        expect(string, contains('AuthState'));
        expect(string, contains('authenticated'));
        expect(string, contains(testUser.toString()));
      });

      test('shows null for missing fields', () {
        final state = AuthState.unauthenticated();
        final string = state.toString();

        expect(string, contains('null'));
      });

      test('includes error message when present', () {
        final state = AuthState.error('Test error');
        final string = state.toString();

        expect(string, contains('Test error'));
      });
    });

    group('State Transitions', () {
      test('can transition from initial to authenticated', () {
        final initial = AuthState.initial();
        final authenticated = initial.copyWith(
          status: AuthStatus.authenticated,
          user: testUser,
        );

        expect(authenticated.status, equals(AuthStatus.authenticated));
        expect(authenticated.user, equals(testUser));
      });

      test('can transition from authenticated to unauthenticated', () {
        final authenticated = AuthState.authenticated(testUser);
        final unauthenticated = authenticated.copyWith(
          status: AuthStatus.unauthenticated,
          clearUser: true,
        );

        expect(unauthenticated.status, equals(AuthStatus.unauthenticated));
        expect(unauthenticated.user, isNull);
      });

      test('can transition to error state', () {
        final loading = AuthState.initial();
        final error = loading.copyWith(
          status: AuthStatus.unauthenticated,
          errorMessage: 'Login failed',
        );

        expect(error.status, equals(AuthStatus.unauthenticated));
        expect(error.errorMessage, equals('Login failed'));
      });

      test('can recover from error state', () {
        final error = AuthState.error('Network error');
        final recovered = error.copyWith(
          status: AuthStatus.authenticated,
          user: testUser,
          clearError: true,
        );

        expect(recovered.status, equals(AuthStatus.authenticated));
        expect(recovered.user, equals(testUser));
        expect(recovered.errorMessage, isNull);
      });
    });

    group('Edge Cases', () {
      test('handles empty error message', () {
        final state = AuthState.error('');

        expect(state.errorMessage, equals(''));
        expect(state.status, equals(AuthStatus.unauthenticated));
      });

      test('handles very long error messages', () {
        final longError = 'Error: ' * 100;
        final state = AuthState.error(longError);

        expect(state.errorMessage, equals(longError));
      });

      test('clearError and clearUser can be used together', () {
        final original = AuthState(
          status: AuthStatus.authenticated,
          user: testUser,
          errorMessage: 'Warning',
        );
        final copy = original.copyWith(clearError: true, clearUser: true);

        expect(copy.user, isNull);
        expect(copy.errorMessage, isNull);
      });

      test('can have user and error message simultaneously', () {
        final state = AuthState(
          status: AuthStatus.authenticated,
          user: testUser,
          errorMessage: 'Warning: Session expiring soon',
        );

        expect(state.user, equals(testUser));
        expect(state.errorMessage, isNotNull);
      });
    });
  });

  group('AuthStatus', () {
    test('has all expected statuses', () {
      expect(AuthStatus.values.length, equals(3));
      expect(AuthStatus.values, contains(AuthStatus.authenticated));
      expect(AuthStatus.values, contains(AuthStatus.unauthenticated));
      expect(AuthStatus.values, contains(AuthStatus.loading));
    });

    test('can be compared', () {
      expect(AuthStatus.authenticated, equals(AuthStatus.authenticated));
      expect(AuthStatus.authenticated, isNot(equals(AuthStatus.loading)));
    });

    test('can be used in switch statements', () {
      String getMessage(AuthStatus status) {
        switch (status) {
          case AuthStatus.authenticated:
            return 'Logged in';
          case AuthStatus.unauthenticated:
            return 'Logged out';
          case AuthStatus.loading:
            return 'Loading...';
        }
      }

      expect(getMessage(AuthStatus.authenticated), equals('Logged in'));
      expect(getMessage(AuthStatus.loading), equals('Loading...'));
    });
  });
}
