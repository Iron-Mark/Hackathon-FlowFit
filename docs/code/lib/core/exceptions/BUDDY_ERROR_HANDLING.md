# Buddy Onboarding Error Handling

This document describes the comprehensive error handling and validation system implemented for the Buddy onboarding flow.

## Overview

The error handling system provides:

- **Friendly error messages** tailored for kids (ages 7-12)
- **Network error handling** with automatic retry logic
- **Offline mode support** with local storage and sync
- **Loading states** for all async operations
- **Validation** with clear, helpful feedback

## Exception Hierarchy

### BuddyException (Base)

Base exception for all Buddy-related errors.

**Properties:**

- `message`: Technical error message for logging
- `userFriendlyMessage`: Kid-friendly message to display
- `originalError`: Original exception if wrapped
- `stackTrace`: Stack trace for debugging
- `friendlyMessage`: Getter that returns user-friendly message or default

### BuddyNameValidationException

Thrown when Buddy name validation fails.

**Default friendly message:** "Please give your buddy a valid name!"

**Validation rules:**

- Name must not be empty
- Name must be 1-20 characters
- Name should not contain special characters like `<>{}[]|`

### BuddyNetworkException

Thrown when network operations fail.

**Properties:**

- `isTimeout`: Whether the error was a timeout
- `canRetry`: Whether the operation can be retried

**Default friendly message:** "Oops! We couldn't connect. Check your internet connection."

### BuddySaveException

Thrown when saving Buddy profile fails.

**Properties:**

- `savedLocally`: Whether data was saved to local storage

**Friendly messages:**

- If saved locally: "Your Buddy is saved! We'll sync when you're back online."
- Otherwise: "Oops! We couldn't save your Buddy. Let's try again!"

### BuddyAuthException

Thrown when user is not authenticated.

**Default friendly message:** "Oops! You need to be logged in to create your Buddy."

### BuddyDataException

Thrown when required onboarding data is missing.

**Properties:**

- `missingFields`: List of field names that are missing

**Default friendly message:** "Oops! Some information is missing. Let's go back and fill it in!"

## Offline Storage

### BuddyOfflineStorage Service

Provides local persistence using SharedPreferences.

**Features:**

- Saves onboarding state locally as user progresses
- Stores pending Buddy profiles for later sync
- Automatically clears stale incomplete progress (>24 hours old)
- Retains completed pending onboarding data until the Buddy profile syncs
- Handles corrupted data gracefully

**Methods:**

- `saveOnboardingState(state)`: Save current onboarding progress
- `loadOnboardingState()`: Load saved progress (returns null if stale/corrupted)
- `clearOnboardingState()`: Clear saved progress
- `savePendingBuddyProfile(profile)`: Save profile for later sync
- `loadPendingBuddyProfile()`: Load pending profile
- `clearPendingBuddyProfile()`: Clear pending profile
- `hasPendingBuddyProfile()`: Check if there's a pending profile

### Offline Mode Flow

1. User completes onboarding
2. System checks network availability
3. If offline:
   - Save Buddy profile to local storage
   - Save onboarding state
   - Show success message: "Your Buddy is saved! We'll sync when you're back online."
   - Navigate to dashboard
4. When online:
   - App startup or app resume calls `syncPendingProfile()` for the signed-in user
   - Clear local storage on success

## Retry Logic

### Automatic Retries

The `completeOnboarding()` method includes automatic retry logic:

**Parameters:**

- `maxRetries`: Number of retry attempts (default: 3)
- `retryDelay`: Delay between retries (default: 2 seconds)

**Retry behavior:**

1. Attempt to save to Supabase
2. If network error occurs, wait `retryDelay` seconds
3. Retry up to `maxRetries` times
4. If all retries fail, save locally for offline mode

**Non-retryable errors:**

- Authentication errors (BuddyAuthException)
- Validation errors (BuddyDataException)

## Loading States

### BuddyLoadingWidget

Reusable widget for displaying loading states.

**Usage:**

```dart
BuddyLoadingWidget(
  message: 'Saving your Buddy...',
)
```

### Screen-level Loading

Screens track loading state with `_isLoading` boolean:

```dart
bool _isLoading = false;

Future<void> _handleAction() async {
  setState(() {
    _isLoading = true;
  });

  try {
    // Perform async operation
  } finally {
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
```

## Error Display

### BuddyErrorWidget

Reusable widget for displaying errors in a kid-friendly way.

**Usage:**

```dart
BuddyErrorWidget(
  message: 'Oops! Something went wrong.',
  onRetry: () => _handleRetry(),
  showRetry: true,
)
```

### Error Dialogs

For critical errors, use dialogs with retry option:

```dart
void _showErrorDialog(String message, {required bool canRetry}) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Oops!'),
      content: Text(message),
      actions: [
        if (canRetry)
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _handleRetry();
            },
            child: const Text('Try Again'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(canRetry ? 'Cancel' : 'OK'),
        ),
      ],
    ),
  );
}
```

## Validation

### Name Validation

Buddy names are validated in real-time as the user types:

```dart
void _validateAndUpdateName(String name) {
  setState(() {
    _errorMessage = ref
        .read(buddyOnboardingProvider.notifier)
        .validateBuddyName(name);
  });
}
```

**Validation rules:**

- Not empty: "Please give your buddy a name!"
- Max 20 characters: "That name is too long! Try something shorter."
- No special characters: "Please use only letters, numbers, and simple symbols."

### Field Validation

Required fields are validated before submission:

```dart
final missingFields = <String>[];
if (state.buddyName == null || state.buddyName!.isEmpty) {
  missingFields.add('buddyName');
}

if (missingFields.isNotEmpty) {
  throw BuddyDataException(
    'Required fields missing: ${missingFields.join(", ")}',
    userFriendlyMessage: 'Please give your buddy a name before continuing!',
    missingFields: missingFields,
  );
}
```

## Best Practices

### 1. Always Use Friendly Messages

```dart
// Good
throw BuddyNetworkException(
  'Connection timeout after 30s',
  userFriendlyMessage: 'Oops! That took too long. Let\'s try again!',
);

// Bad
throw Exception('Connection timeout');
```

### 2. Handle Mounted State

Always check `mounted` before calling `setState`:

```dart
if (mounted) {
  setState(() {
    _isLoading = false;
  });
}
```

### 3. Provide Retry Options

For network errors, always offer a retry option:

```dart
} on BuddyNetworkException catch (e) {
  _showErrorDialog(e.friendlyMessage, canRetry: e.canRetry);
}
```

### 4. Save Progress Frequently

Save onboarding state after each step:

```dart
void selectColor(String color) {
  state = state.copyWith(selectedColor: color);
  _saveStateLocally(); // Save immediately
}
```

### 5. Clear Sensitive Data

Clear local storage after successful sync:

```dart
await storage.clearOnboardingState();
await storage.clearPendingBuddyProfile();
```

## Testing Error Scenarios

### Simulate Network Errors

```dart
// In tests, inject a mock Supabase client that throws errors
final mockClient = MockSupabaseClient();
when(() => mockClient.from('buddy_profiles').insert(any()))
    .thenThrow(PostgrestException(message: 'Network error'));
```

### Test Offline Mode

```dart
// Disable network and verify local storage
await offlineStorage.savePendingBuddyProfile(profile);
final loaded = await offlineStorage.loadPendingBuddyProfile();
expect(loaded, equals(profile));
```

### Test Validation

```dart
final notifier = BuddyOnboardingNotifier();

// Test empty name
expect(
  notifier.validateBuddyName(''),
  equals('Please give your buddy a name!'),
);

// Test too long
expect(
  notifier.validateBuddyName('a' * 21),
  equals('That name is too long! Try something shorter.'),
);
```

## Future Enhancements

1. **Analytics**: Track error rates and types
2. **Crash Reporting**: Integrate with Sentry or Firebase Crashlytics
3. **Connectivity Events**: Add a dedicated connectivity listener in addition to the current startup/resume sync
4. **Conflict Resolution**: Handle cases where local and remote data differ
5. **Rate Limiting**: Prevent excessive retry attempts
