# Dashboard Refactoring Integration Tests

## Overview

This document describes the integration tests for the dashboard refactoring merge feature. These tests verify end-to-end flows for the enhanced dashboard and profile screen functionality.

## Test Coverage

The integration tests cover the following flows:

### 1. Initial Tab Navigation

- **Test**: `INTEGRATION: Initial tab navigation from route arguments`
- **Validates**: Requirements 2.1, 2.3
- **Description**: Verifies that the dashboard can navigate to a specific tab (e.g., Profile tab) when provided with route arguments containing an `initialTab` parameter.

### 2. Photo Picker Modal

- **Test**: `INTEGRATION: Photo picker modal opens with haptic feedback`
- **Validates**: Requirements 4.1, 4.2
- **Description**: Verifies that tapping the profile photo opens the photo picker modal and triggers haptic feedback.

### 3. Logout Flow

- **Test**: `INTEGRATION: Logout flow shows confirmation and navigates`
- **Validates**: Requirements 8.1, 8.2, 8.3, 8.4, 8.5
- **Description**: Verifies the complete logout flow including:
  - Confirmation dialog appears
  - Cancel button closes dialog
  - Confirm button triggers signOut
  - Auth state changes to unauthenticated

### 4. Edit Profile Navigation

- **Test**: `INTEGRATION: Edit profile navigation with haptic feedback`
- **Validates**: Requirements 7.1, 7.2, 7.3
- **Description**: Verifies that tapping the edit profile button:
  - Triggers haptic feedback
  - Navigates to the survey basic info screen
  - Passes correct route arguments

### 5. Pull-to-Refresh

- **Test**: `INTEGRATION: Pull-to-refresh updates profile data`
- **Validates**: Requirements 6.1, 6.2, 6.3, 6.4, 6.5
- **Description**: Verifies that pull-to-refresh gesture:
  - Triggers profile data reload
  - Shows success message
  - Updates UI with refreshed data

### 6. Default Tab Navigation

- **Test**: `INTEGRATION: Default tab navigation when no arguments`
- **Validates**: Requirements 2.3
- **Description**: Verifies that the dashboard defaults to the Home tab (index 0) when no initial tab argument is provided.

### 7. Invalid Tab Index Handling

- **Test**: `INTEGRATION: Invalid tab index defaults to home`
- **Validates**: Requirements 2.3
- **Description**: Verifies that invalid tab indices (e.g., 10) default to the Home tab instead of causing errors.

## Running the Tests

### Prerequisites

Before running these integration tests, you must initialize Supabase. Add the following to the `setUpAll` block:

```dart
setUpAll(() async {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase for testing
  await Supabase.initialize(
    url: SupabaseRuntimeConfig.url,
    anonKey: SupabaseRuntimeConfig.publishableKey,
  );
});
```

### Run All Integration Tests

```bash
flutter test test/integration/dashboard_refactoring_integration_test.dart
```

### Run Specific Test

```bash
flutter test test/integration/dashboard_refactoring_integration_test.dart --plain-name "Initial tab navigation"
```

## Test Architecture

### Mocking Strategy

The tests use a mocking strategy to isolate the dashboard and profile screen functionality:

1. **MockAuthNotifier**: Extends `AuthNotifier` to provide a controlled authentication state
2. **MockAuthRepository**: Implements `IAuthRepository` to avoid real Supabase calls
3. **Provider Overrides**: Uses Riverpod's provider override mechanism to inject mocks

### Test Data

Each test creates its own test profile with unique user IDs to avoid conflicts:

- `test-user-tab-nav`
- `test-user-photo`
- `test-user-logout`
- `test-user-edit`
- `test-user-refresh`
- `test-user-default-tab`
- `test-user-invalid-tab`

## Known Issues

### Supabase Initialization

The tests currently fail with:

```
You must initialize the supabase instance before calling Supabase.instance
```

**Solution**: Add Supabase initialization in the `setUpAll` block as shown in the Prerequisites section above.

### Platform Channel Mocking

Some tests mock platform channels for haptic feedback. This is done using:

```dart
TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
    .setMockMethodCallHandler(SystemChannels.platform, ...)
```

### Image Picker Limitations

The photo picker tests cannot actually test camera/gallery selection in unit tests as these require platform channels. These flows should be tested manually or with integration tests on real devices.

## Manual Testing Checklist

While the automated tests cover most scenarios, some aspects require manual verification:

- [ ] Profile photo persists across app restarts
- [ ] Camera capture works correctly
- [ ] Gallery selection works correctly
- [ ] Photo removal clears SharedPreferences
- [ ] Haptic feedback feels appropriate
- [ ] Logout navigates to welcome screen
- [ ] Edit profile pre-populates existing data
- [ ] Pull-to-refresh shows loading indicator
- [ ] Tab navigation works from deep links

## Future Improvements

1. **Add Supabase Initialization**: Update tests to properly initialize Supabase
2. **Add More Edge Cases**: Test network failures, permission denials, etc.
3. **Add Performance Tests**: Measure tab switching performance
4. **Add Accessibility Tests**: Verify screen reader support
5. **Add Visual Regression Tests**: Capture screenshots for UI verification

## Related Documentation

- [Requirements Document](../../../.kiro/specs/dashboard-refactoring-merge/requirements.md)
- [Design Document](../../../.kiro/specs/dashboard-refactoring-merge/design.md)
- [Task List](../../../.kiro/specs/dashboard-refactoring-merge/tasks.md)
- [Integration Testing Guide](./README.md)
