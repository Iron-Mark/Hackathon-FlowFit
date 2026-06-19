# User Profile Provider Usage Examples

This document provides examples of how to use the `UserProfileProvider` and `UserProfileNotifier` throughout the FlowFit app.

## Overview

The user profile service provides a centralized way to manage user profile data, including:

- Basic profile information (name, age, gender, etc.)
- Buddy onboarding data (nickname, kids mode)
- Fitness goals and targets
- Profile customization

## Basic Usage

### 1. Fetching User Profile

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flowfit/core/providers/user_profile_provider.dart';

class ProfileScreen extends ConsumerWidget {
  final String userId;

  const ProfileScreen({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider(userId));

    return profileAsync.when(
      data: (profile) {
        if (profile == null) {
          return Text('No profile found');
        }
        return Column(
          children: [
            Text('Name: ${profile.fullName ?? "Not set"}'),
            Text('Nickname: ${profile.nickname ?? "Not set"}'),
            Text('Kids Mode: ${profile.isKidsMode ? "Yes" : "No"}'),
          ],
        );
      },
      loading: () => CircularProgressIndicator(),
      error: (error, stack) => Text('Error: $error'),
    );
  }
}
```

### 2. Updating Nickname

```dart
class NicknameEditScreen extends ConsumerWidget {
  final String userId;
  final TextEditingController _controller = TextEditingController();

  const NicknameEditScreen({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        TextField(
          controller: _controller,
          decoration: InputDecoration(labelText: 'Nickname'),
        ),
        ElevatedButton(
          onPressed: () async {
            await ref
                .read(userProfileNotifierProvider(userId).notifier)
                .updateNickname(_controller.text);

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Nickname updated!')),
            );
          },
          child: Text('Save'),
        ),
      ],
    );
  }
}
```

### 3. Toggling Kids Mode

```dart
class SettingsScreen extends ConsumerWidget {
  final String userId;

  const SettingsScreen({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(userProfileNotifierProvider(userId));

    return profileState.when(
      data: (profile) {
        if (profile == null) return Text('No profile');

        return SwitchListTile(
          title: Text('Kids Mode'),
          subtitle: Text('Enable Buddy and kid-friendly features'),
          value: profile.isKidsMode,
          onChanged: (value) async {
            await ref
                .read(userProfileNotifierProvider(userId).notifier)
                .updateKidsMode(value);
          },
        );
      },
      loading: () => CircularProgressIndicator(),
      error: (error, stack) => Text('Error: $error'),
    );
  }
}
```

### 4. Updating Multiple Fields

```dart
class ProfileEditScreen extends ConsumerStatefulWidget {
  final String userId;

  const ProfileEditScreen({required this.userId});

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  final _nameController = TextEditingController();
  final _nicknameController = TextEditingController();
  int? _selectedAge;
  bool _isKidsMode = false;

  Future<void> _saveProfile() async {
    await ref
        .read(userProfileNotifierProvider(widget.userId).notifier)
        .updateProfile(
          fullName: _nameController.text,
          nickname: _nicknameController.text,
          age: _selectedAge,
          isKidsMode: _isKidsMode,
        );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile updated!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: _nameController,
          decoration: InputDecoration(labelText: 'Full Name'),
        ),
        TextField(
          controller: _nicknameController,
          decoration: InputDecoration(labelText: 'Nickname'),
        ),
        // Age selector, kids mode toggle, etc.
        ElevatedButton(
          onPressed: _saveProfile,
          child: Text('Save All Changes'),
        ),
      ],
    );
  }
}
```

## Integration with Buddy Onboarding

The user profile service is automatically used during Buddy onboarding. The `BuddyOnboardingNotifier` calls the internal `_updateUserProfile` method to save nickname and kids mode settings.

However, you can also use the `UserProfileNotifier` directly after onboarding:

```dart
// After onboarding, update user preferences
await ref
    .read(userProfileNotifierProvider(userId).notifier)
    .updateNicknameAndKidsMode(
      nickname: 'SuperKid',
      isKidsMode: true,
    );
```

## Data Consistency

The `UserProfileNotifier` ensures data consistency by:

1. Updating the Supabase database first
2. Only updating local state after successful database update
3. Handling errors gracefully with AsyncValue error states
4. Automatically updating the `updated_at` timestamp

## Error Handling

```dart
final profileState = ref.watch(userProfileNotifierProvider(userId));

profileState.when(
  data: (profile) => ProfileView(profile: profile),
  loading: () => LoadingIndicator(),
  error: (error, stack) {
    // Handle different error types
    if (error.toString().contains('network')) {
      return ErrorView(
        message: 'Network error. Please check your connection.',
        onRetry: () {
          ref.read(userProfileNotifierProvider(userId).notifier).loadProfile();
        },
      );
    }
    return ErrorView(message: 'An error occurred: $error');
  },
);
```

## Best Practices

1. **Use family providers**: Always pass the userId to the provider

   ```dart
   ref.watch(userProfileNotifierProvider(userId))
   ```

2. **Handle null profiles**: Always check if profile is null before accessing fields

   ```dart
   if (profile == null) return Text('No profile');
   ```

3. **Use notifier for updates**: Use `.notifier` when calling update methods

   ```dart
   ref.read(userProfileNotifierProvider(userId).notifier).updateNickname(...)
   ```

4. **Reload after updates**: The notifier automatically updates local state, but you can manually reload if needed

   ```dart
   await ref.read(userProfileNotifierProvider(userId).notifier).loadProfile();
   ```

5. **Dispose properly**: Riverpod handles disposal automatically, but ensure you're not holding references to disposed providers

## Testing

See `test/core/providers/user_profile_provider_test.dart` for comprehensive test examples.
