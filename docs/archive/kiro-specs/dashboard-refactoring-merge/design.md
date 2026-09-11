# Design Document

## Overview

This design outlined the approach for merging features from the monolithic dashboard (previously `dashboard_screen-mark-old.dart`, now removed) into the modular dashboard structure while avoiding code duplication and choosing the best implementations where features overlap. The refactoring has successfully maintained all existing functionality while improving code organization and maintainability.

## Architecture

### Migration Complete

**Previous Monolithic Dashboard** (removed):

- Single file containing `DashboardScreen` and all tab widgets (HomeTab, HealthTab, TrackTab, ProgressTab, ProfileTab)
- ProfileTab included complete profile management with photo picker, sync status, refresh, edit, and logout
- Supported initial tab navigation via route arguments
- Used `/welcome` route for auth redirects

**Current Modular Dashboard** (`dashboard_screen.dart`):

- Main `DashboardScreen` references separate screen files
- Includes initial tab navigation support via route arguments
- Uses `/welcome` route for auth redirects
- All tab content loaded from modular screen components

**Current Profile Screen** (`lib/screens/profile/profile_screen.dart`):

- Enhanced with SharedPreferences persistence for profile photos
- Includes sync status bar display
- Supports pull-to-refresh functionality
- Proper edit profile navigation with haptic feedback
- Logout with confirmation dialog
- Complete loading/error/empty state handling
- All features from monolithic version successfully migrated

## Components and Interfaces

### 1. DashboardScreen (Main Container)

**Location**: `lib/screens/dashboard_screen.dart`

**Enhancements Needed**:

- Add `_checkInitialTab()` method to support route-based tab navigation
- Keep existing auth guard functionality
- Decide on auth route: `/welcome` vs `/login`

**Interface**:

```dart
class DashboardScreen extends ConsumerStatefulWidget {
  // Existing: _currentIndex, _screens list, _checkAuthState()
  // Add: _checkInitialTab()
}
```

### 2. ProfileScreen (Enhanced Profile Management)

**Location**: `lib/screens/profile/profile_screen.dart`

**Current State**:

- Has basic photo picker methods
- Simple logout without confirmation
- No SharedPreferences persistence
- No sync status display
- No refresh functionality
- No edit profile navigation

**Enhancements Needed**:

- Add SharedPreferences persistence for profile photos
- Add `_loadProfileImage()` and `_saveProfileImage()` methods
- Replace simple logout with confirmation dialog version
- Add sync status bar display
- Add pull-to-refresh functionality
- Add edit profile navigation
- Integrate with ProfileView component (if exists) or build profile display

**Interface**:

```dart
class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  String? _profileImagePath;

  // Existing methods (keep):
  // - _pickImageFromCamera()
  // - _pickImageFromGallery()
  // - _showPhotoPickerDialog()

  // Enhanced methods (modify):
  // - _removePhoto() - add SharedPreferences cleanup

  // New methods (add from old):
  // - _loadProfileImage() - load from SharedPreferences
  // - _saveProfileImage() - save to SharedPreferences
  // - _handleLogout() - with confirmation dialog
  // - _navigateToEditProfile() - navigate to survey
  // - _handleRefresh() - pull-to-refresh
  // - _buildSyncStatusBar() - sync status display
  // - _buildProfileView() - profile display with all features
  // - _buildLoadingState() - loading indicator
  // - _buildErrorState() - error display
  // - _buildEmptyState() - empty profile prompt
}
```

### 3. ProfileView Component

**Check if exists**: `lib/screens/profile/profile_view.dart`

If ProfileView exists, it should accept:

- `profile`: UserProfile data
- `profileImagePath`: Local image path
- `userEmail`: User's email
- `onPhotoTap`: Callback for photo picker
- `onEditTap`: Callback for edit profile
- `onLogout`: Callback for logout

If it doesn't exist, profile display will be built directly in ProfileScreen.

## Data Models

### Profile Image Storage

**Storage Mechanism**: SharedPreferences
**Key Format**: `profile_image_{userId}`
**Value**: Absolute file path to locally stored image

**Data Flow**:

1. User selects/captures photo → ImagePicker returns XFile
2. Save path to SharedPreferences with user-specific key
3. On app restart, load path from SharedPreferences
4. Verify file still exists before displaying
5. If file missing, clean up SharedPreferences entry

### Initial Tab Navigation

**Route Arguments Format**:

```dart
{
  'initialTab': int  // 0-4 for Home, Health, Track, Progress, Profile
}
```

**Navigation Example**:

```dart
Navigator.pushNamed(
  context,
  '/dashboard',
  arguments: {'initialTab': 4}, // Navigate to Profile tab
);
```

### Sync Status

**Provider**: `syncStatusProvider(userId)` from profile_providers.dart
**States**:

- `SyncStatus.synced` - Hide status bar
- `SyncStatus.syncing` - Show "Syncing..." with primary color
- `SyncStatus.pendingSync` - Show "Pending sync (count)" with orange
- `SyncStatus.syncFailed` - Show "Sync failed" with red
- `SyncStatus.offline` - Show "Offline" with neutral color

## Correctness Properties

_A property is a characteristic or behavior that should hold true across all valid executions of a system-essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees._

### Property Reflection

After analyzing all acceptance criteria, I've identified several redundancies and opportunities for consolidation:

**Redundancies to eliminate:**

- 2.2 is redundant with 2.1 (both test initial tab navigation)
- 2.4 is redundant with 1.2 (UI update is implicit in screen display)
- 6.2 and 6.3 can be combined into one property about refresh invalidating providers

**Properties to consolidate:**

- 5.1-5.5 are all examples of the same property: sync status determines UI display (5.6)
- 4.3 and 4.4 are similar examples that can be covered by one property about image picker parameters
- 10.1-10.3 are examples of the same time-based greeting logic

**Final property set** will focus on unique, non-redundant properties that provide comprehensive coverage.

### Correctness Properties

Property 1: Tab selection displays correct screen
_For any_ valid tab index (0-4), when that tab is selected, the corresponding modular screen component should be displayed
**Validates: Requirements 1.2**

Property 2: Initial tab navigation from route arguments
_For any_ valid initialTab parameter in route arguments, the dashboard should set its current index to that value
**Validates: Requirements 2.1**

Property 3: Profile photo persistence round-trip
_For any_ user ID and photo file path, saving the photo path to SharedPreferences and then loading it should return the same path
**Validates: Requirements 3.1, 3.2**

Property 4: Profile photo display when file exists
_For any_ valid photo file path that exists on disk, the profile view should display that photo
**Validates: Requirements 3.3**

Property 5: Invalid photo path cleanup
_For any_ saved photo path where the file no longer exists, loading the profile should remove that path from SharedPreferences
**Validates: Requirements 3.4**

Property 6: Photo removal clears persistence
_For any_ user with a saved profile photo, removing the photo should delete the path from SharedPreferences
**Validates: Requirements 3.5**

Property 7: Haptic feedback on photo picker
_For any_ photo picker modal open action, the system should trigger haptic feedback
**Validates: Requirements 4.2**

Property 8: Photo operation success feedback
_For any_ successful photo operation (camera or gallery), the system should display a success message
**Validates: Requirements 4.6**

Property 9: Photo operation error feedback
_For any_ failed photo operation, the system should display an error message containing failure details
**Validates: Requirements 4.7**

Property 10: Sync status determines UI display
_For any_ sync status value, the sync status bar should display the appropriate UI elements (message, color, visibility) corresponding to that status
**Validates: Requirements 5.1, 5.2, 5.3, 5.4, 5.5, 5.6**

Property 11: Refresh invalidates providers
_For any_ refresh action, the system should invalidate both profile and sync status providers to trigger reload
**Validates: Requirements 6.2, 6.3**

Property 12: Haptic feedback on edit profile
_For any_ edit profile button tap, the system should trigger haptic feedback
**Validates: Requirements 7.1**

Property 13: Logout confirmation triggers signOut
_For any_ confirmed logout action, the authentication service signOut method should be called
**Validates: Requirements 8.2**

Property 14: Auth state change triggers redirect
_For any_ change in auth state from authenticated to unauthenticated, the system should redirect to the welcome/login screen
**Validates: Requirements 9.2**

Property 15: User name extraction for greeting
_For any_ user profile with a full name, the greeting should display the first name extracted from the full name
**Validates: Requirements 10.4**

## Error Handling

### Profile Photo Management

**File Not Found**:

- When loading profile photo, check if file exists
- If file missing, remove path from SharedPreferences
- Display default avatar instead of error

**ImagePicker Failures**:

- Wrap all ImagePicker operations in try-catch
- Display user-friendly error messages
- Log errors for debugging
- Allow user to retry operation

**SharedPreferences Failures**:

- Silently fail on load errors (use default avatar)
- Log errors for debugging
- Don't block UI rendering

### Sync Status

**Provider Errors**:

- Display offline status if provider fails to load
- Don't crash app on sync status errors
- Allow manual retry through refresh

**Network Failures**:

- Show appropriate offline status
- Queue changes for later sync
- Provide manual sync option

### Navigation

**Missing Route Arguments**:

- Default to tab 0 (Home) if initialTab is null or invalid
- Validate tab index is in range 0-4
- Log warning for invalid indices

**Auth State Errors**:

- Default to unauthenticated if auth state is unclear
- Redirect to login/welcome screen
- Clear navigation stack to prevent back navigation

### Logout

**SignOut Failures**:

- Display error message with details
- Don't navigate away from current screen
- Allow user to retry
- Log error for debugging

## Testing Strategy

### Unit Testing

**Profile Photo Management**:

- Test `_loadProfileImage()` with valid and invalid paths
- Test `_saveProfileImage()` saves correct key format
- Test `_removePhoto()` clears SharedPreferences
- Mock SharedPreferences for isolated testing

**Initial Tab Navigation**:

- Test `_checkInitialTab()` with various route arguments
- Test default behavior when arguments are null
- Test boundary values (0, 4, -1, 5)

**Greeting Logic**:

- Test `_getGreeting()` at different times of day
- Test name extraction from full names
- Test fallback to "there" when profile is null

**Logout**:

- Test confirmation dialog appears
- Test signOut is called on confirmation
- Test navigation occurs after successful logout
- Test error handling on signOut failure

### Property-Based Testing

This feature will use **fast_check** (Dart/Flutter property-based testing library) for property-based tests. Each property-based test will run a minimum of 100 iterations.

**Property Tests to Implement**:

1. **Tab Navigation Property** (Property 1)

   - Generate random tab indices (0-4)
   - Verify correct screen is displayed
   - Tag: `**Feature: dashboard-refactoring-merge, Property 1: Tab selection displays correct screen**`

2. **Initial Tab Route Property** (Property 2)

   - Generate random valid tab indices
   - Create route arguments with initialTab
   - Verify dashboard sets correct index
   - Tag: `**Feature: dashboard-refactoring-merge, Property 2: Initial tab navigation from route arguments**`

3. **Photo Persistence Round-Trip** (Property 3)

   - Generate random user IDs and file paths
   - Save then load, verify same path returned
   - Tag: `**Feature: dashboard-refactoring-merge, Property 3: Profile photo persistence round-trip**`

4. **Photo Display Property** (Property 4)

   - Generate random valid file paths
   - Verify photo is displayed when file exists
   - Tag: `**Feature: dashboard-refactoring-merge, Property 4: Profile photo display when file exists**`

5. **Invalid Path Cleanup** (Property 5)

   - Generate paths to non-existent files
   - Verify SharedPreferences is cleaned up
   - Tag: `**Feature: dashboard-refactoring-merge, Property 5: Invalid photo path cleanup**`

6. **Photo Removal Property** (Property 6)

   - Generate random user IDs with saved photos
   - Remove photo, verify SharedPreferences cleared
   - Tag: `**Feature: dashboard-refactoring-merge, Property 6: Photo removal clears persistence**`

7. **Haptic Feedback Properties** (Properties 7, 12)

   - Verify haptic service called on photo picker open
   - Verify haptic service called on edit profile tap
   - Tag: `**Feature: dashboard-refactoring-merge, Property 7: Haptic feedback on photo picker**`
   - Tag: `**Feature: dashboard-refactoring-merge, Property 12: Haptic feedback on edit profile**`

8. **Photo Operation Feedback** (Properties 8, 9)

   - Generate successful and failed photo operations
   - Verify appropriate messages displayed
   - Tag: `**Feature: dashboard-refactoring-merge, Property 8: Photo operation success feedback**`
   - Tag: `**Feature: dashboard-refactoring-merge, Property 9: Photo operation error feedback**`

9. **Sync Status UI Property** (Property 10)

   - Generate all possible SyncStatus values
   - Verify correct UI elements for each status
   - Tag: `**Feature: dashboard-refactoring-merge, Property 10: Sync status determines UI display**`

10. **Refresh Invalidation** (Property 11)

    - Trigger refresh action
    - Verify both providers invalidated
    - Tag: `**Feature: dashboard-refactoring-merge, Property 11: Refresh invalidates providers**`

11. **Logout SignOut Property** (Property 13)

    - Generate confirmed logout actions
    - Verify signOut method called
    - Tag: `**Feature: dashboard-refactoring-merge, Property 13: Logout confirmation triggers signOut**`

12. **Auth State Redirect** (Property 14)

    - Generate auth state changes
    - Verify redirect occurs on unauthenticated
    - Tag: `**Feature: dashboard-refactoring-merge, Property 14: Auth state change triggers redirect**`

13. **Name Extraction Property** (Property 15)
    - Generate random full names
    - Verify first name correctly extracted
    - Tag: `**Feature: dashboard-refactoring-merge, Property 15: User name extraction for greeting**`

### Integration Testing

**End-to-End Flows**:

- Complete profile photo upload flow (camera → save → persist → reload)
- Complete logout flow (tap → confirm → signOut → navigate)
- Complete edit profile flow (tap → navigate → edit → return → refresh)
- Initial tab navigation flow (route with args → dashboard opens on correct tab)

**Widget Testing**:

- Test ProfileScreen renders correctly with various states
- Test sync status bar displays correctly for each status
- Test photo picker modal displays all options
- Test confirmation dialogs appear and function correctly

### Manual Testing Checklist

- [ ] Profile photo persists across app restarts
- [ ] Photo picker shows camera, gallery, and remove options
- [ ] Sync status bar displays correctly for all states
- [ ] Pull-to-refresh updates profile data
- [ ] Edit profile navigates to survey with correct arguments
- [ ] Logout shows confirmation and signs out correctly
- [ ] Initial tab navigation works from deep links
- [ ] Greeting changes based on time of day
- [ ] User's first name displays in greeting
- [ ] All haptic feedback triggers feel appropriate

## Implementation Notes

### Code Reuse Strategy

1. **Photo Picker Methods**: Keep existing implementations in ProfileScreen, enhance with SharedPreferences
2. **Logout**: Replace simple logout with confirmation dialog version from old dashboard
3. **Sync Status Bar**: Move `_buildSyncStatusBar()` from old ProfileTab to new ProfileScreen
4. **Refresh Handler**: Move `_handleRefresh()` from old ProfileTab to new ProfileScreen
5. **Edit Navigation**: Move `_navigateToEditProfile()` from old ProfileTab to new ProfileScreen
6. **Initial Tab Check**: Move `_checkInitialTab()` from old DashboardScreen to new DashboardScreen

### Auth Route Decision

**Options**:

- `/welcome` - Used in old monolithic version
- `/login` - Used in new modular version

**Recommendation**: Use `/welcome` for consistency with existing app flow, as it likely includes onboarding for new users. Update new dashboard to use `/welcome` instead of `/login`.

### SharedPreferences Key Format

**Pattern**: `profile_image_{userId}`
**Example**: `profile_image_abc123-def456-ghi789`

This ensures:

- User-specific storage (multi-user support)
- Clear naming convention
- Easy to query and clean up

### Haptic Feedback

Use `HapticFeedback.lightImpact()` for:

- Photo picker modal open
- Photo selection actions

Use `HapticFeedback.mediumImpact()` for:

- Edit profile button tap
- Logout button tap

This provides appropriate tactile feedback for different action weights.
