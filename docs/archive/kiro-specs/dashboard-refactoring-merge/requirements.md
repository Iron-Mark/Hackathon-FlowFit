# Requirements Document

## Introduction

This feature involved refactoring the dashboard screen from a monolithic structure to a modular architecture while preserving all existing functionality. The monolithic dashboard (previously `dashboard_screen-mark-old.dart`, now removed) contained inline tab implementations (HomeTab, HealthTab, TrackTab, ProgressTab, ProfileTab) and additional features that have been successfully integrated into the new modular structure that uses separate screen files.

**Implementation Approach**: This is a code enhancement and migration task. The modular structure already exists with some basic functionality. We will:

1. **Compare implementations** - Both old and new versions may have the same feature; choose the better implementation
2. **Enhance existing code** in modular files (like `ProfileScreen`) by adding missing features from the monolithic version
3. **Reuse existing implementations** where they already exist to avoid code duplication
4. **Move unique features** from the monolithic dashboard to the appropriate modular locations
5. **Avoid creating redundant code** - if functionality already exists elsewhere in the codebase, we reference it rather than duplicate it

**Examples of overlapping features to compare:**

- **Logout**: New version has simple logout; old version has confirmation dialog (better UX - use old)
- **Photo picker**: Both have it; new version is simpler but old version has SharedPreferences persistence (use old)
- **Initial tab navigation**: Only in old version (add to new)
- **Sync status bar**: Only in old version (add to new)
- **Profile refresh**: Only in old version (add to new)

## Glossary

- **Dashboard Screen**: The main navigation container with bottom navigation bar that hosts all primary app tabs
- **Tab Widget**: Individual tab content widgets (HomeTab, HealthTab, TrackTab, ProgressTab, ProfileTab) currently defined inline in the monolithic file
- **Modular Screen**: Separate screen files located in dedicated directories (home/, health/, track/, progress/, profile/)
- **Profile Image Management**: Local storage and display of user profile photos using SharedPreferences and ImagePicker
- **Sync Status**: Visual indicator showing the synchronization state of profile data with backend
- **Initial Tab Navigation**: Ability to navigate to a specific tab when opening the dashboard via route arguments
- **Auth Guard**: Authentication state checking that redirects unauthenticated users to login/welcome screen

## Requirements

### Requirement 1

**User Story:** As a developer, I want the dashboard to use modular screen components, so that the codebase is maintainable and follows separation of concerns.

#### Acceptance Criteria

1. WHEN the dashboard screen is rendered THEN the system SHALL load tab content from separate modular screen files
2. WHEN a tab is selected THEN the system SHALL display the corresponding modular screen component
3. WHEN the modular screens are loaded THEN the system SHALL maintain all existing functionality from the monolithic implementation
4. WHEN imports are declared THEN the system SHALL retain all imports for future use even if not currently active
5. WHEN the dashboard initializes THEN the system SHALL use the modular screen components from separate files

### Requirement 2

**User Story:** As a user, I want to navigate directly to a specific tab when opening the dashboard, so that I can quickly access the feature I need.

#### Acceptance Criteria

1. WHEN the dashboard receives route arguments with an initialTab parameter THEN the system SHALL navigate to the specified tab index
2. WHEN the initialTab parameter is valid THEN the system SHALL update the current index to match the requested tab
3. WHEN the initialTab parameter is null THEN the system SHALL default to the first tab (Home)
4. WHEN the tab navigation occurs THEN the system SHALL update the UI to reflect the selected tab

### Requirement 3

**User Story:** As a user, I want my profile photo to persist across app sessions, so that I don't have to re-upload it every time.

#### Acceptance Criteria

1. WHEN a user uploads a profile photo THEN the system SHALL save the file path to SharedPreferences with a user-specific key
2. WHEN the profile tab loads THEN the system SHALL retrieve the saved photo path from SharedPreferences
3. WHEN the saved photo file exists THEN the system SHALL display the photo in the profile view
4. WHEN the saved photo file does not exist THEN the system SHALL remove the invalid path from SharedPreferences
5. WHEN a user removes their profile photo THEN the system SHALL delete the path from SharedPreferences

### Requirement 4

**User Story:** As a user, I want to change my profile photo using my camera or gallery, so that I can personalize my profile.

#### Acceptance Criteria

1. WHEN a user taps the profile photo THEN the system SHALL display a modal bottom sheet with photo options
2. WHEN the photo picker modal opens THEN the system SHALL provide haptic feedback
3. WHEN a user selects "Take Photo" THEN the system SHALL open the device camera with image quality constraints
4. WHEN a user selects "Choose from Gallery" THEN the system SHALL open the device photo gallery with image quality constraints
5. WHEN a user selects "Remove Photo" THEN the system SHALL clear the profile photo and show confirmation
6. WHEN a photo operation completes successfully THEN the system SHALL display a success message
7. WHEN a photo operation fails THEN the system SHALL display an error message with details

### Requirement 5

**User Story:** As a user, I want to see the sync status of my profile data, so that I know when my changes are saved to the cloud.

#### Acceptance Criteria

1. WHEN profile data is synced THEN the system SHALL hide the sync status bar
2. WHEN profile data is syncing THEN the system SHALL display a status bar with "Syncing..." message and primary color
3. WHEN profile data has pending sync THEN the system SHALL display a status bar with pending count and orange color
4. WHEN profile sync fails THEN the system SHALL display a status bar with error message and red color
5. WHEN the device is offline THEN the system SHALL display a status bar with "Offline" message and neutral color
6. WHEN sync status changes THEN the system SHALL update the status bar display accordingly

### Requirement 6

**User Story:** As a user, I want to manually trigger profile sync, so that I can ensure my data is up-to-date.

#### Acceptance Criteria

1. WHEN a user pulls down on the profile screen THEN the system SHALL trigger a refresh action
2. WHEN the refresh action is triggered THEN the system SHALL reload the profile data from the backend
3. WHEN the refresh action is triggered THEN the system SHALL invalidate and refresh sync status providers
4. WHEN the refresh completes successfully THEN the system SHALL display a success message
5. WHEN the refresh fails THEN the system SHALL display an error message with failure details

### Requirement 7

**User Story:** As a user, I want to edit my profile information, so that I can keep my personal details current.

#### Acceptance Criteria

1. WHEN a user taps the edit profile button THEN the system SHALL provide haptic feedback
2. WHEN the edit action is triggered THEN the system SHALL navigate to the onboarding survey flow
3. WHEN navigating to edit mode THEN the system SHALL pass the user ID and fromEdit flag as route arguments
4. WHEN the survey screens load in edit mode THEN the system SHALL pre-populate existing profile data
5. WHEN the user completes editing THEN the system SHALL automatically refresh the profile display

### Requirement 8

**User Story:** As a user, I want to log out of my account, so that I can secure my data when not using the app.

#### Acceptance Criteria

1. WHEN a user initiates logout THEN the system SHALL display a confirmation dialog
2. WHEN the user confirms logout THEN the system SHALL sign out from the authentication service
3. WHEN logout completes successfully THEN the system SHALL navigate to the welcome screen and clear navigation history
4. WHEN logout fails THEN the system SHALL display an error message and remain on the current screen
5. WHEN the user cancels logout THEN the system SHALL close the dialog and remain logged in

### Requirement 9

**User Story:** As a user, I want to be automatically redirected to login when not authenticated, so that my data remains secure.

#### Acceptance Criteria

1. WHEN the dashboard initializes without an authenticated user THEN the system SHALL redirect to the welcome screen
2. WHEN the auth state changes to unauthenticated THEN the system SHALL redirect to the welcome screen
3. WHEN redirecting to welcome THEN the system SHALL clear all navigation history
4. WHEN the auth check occurs THEN the system SHALL use the correct route path for the environment

### Requirement 10

**User Story:** As a user, I want to see personalized greetings on the home tab, so that the app feels welcoming and personal.

#### Acceptance Criteria

1. WHEN the home tab loads before noon THEN the system SHALL display "Good Morning" greeting
2. WHEN the home tab loads between noon and 5 PM THEN the system SHALL display "Good Afternoon" greeting
3. WHEN the home tab loads after 5 PM THEN the system SHALL display "Good Evening" greeting
4. WHEN the user profile is loaded THEN the system SHALL display the user's first name in the greeting
5. WHEN the user profile is not available THEN the system SHALL display "there" as the default name
