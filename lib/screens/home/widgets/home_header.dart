import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:solar_icons/solar_icons.dart';
import '../../../providers/dashboard_providers.dart';

/// HomeHeader widget displays the app branding and notification indicator
///
/// Features:
/// - App branding ("FlowFit")
/// - Notification bell icon with badge
/// - Badge displays count (or "9+" for counts > 9)
/// - Navigation to notification settings on tap
///
/// Requirements: 7.1, 7.2, 7.3, 7.4, 7.5, 7.6
class HomeHeader extends ConsumerWidget implements PreferredSizeWidget {
  const HomeHeader({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final unreadCount = ref.watch(unreadNotificationsProvider);

    return AppBar(
      backgroundColor: theme.colorScheme.surface,
      elevation: 0,
      title: Text(
        'FlowFit',
        style: theme.textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.onSurface,
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: _NotificationButton(unreadCount: unreadCount),
        ),
      ],
    );
  }
}

/// Notification button with badge indicator
class _NotificationButton extends StatelessWidget {
  final int unreadCount;

  const _NotificationButton({required this.unreadCount});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return IconButton(
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(
            SolarIconsOutline.bell,
            size: 24,
            color: theme.colorScheme.onSurface,
          ),
          if (unreadCount > 0)
            Positioned(
              right: -2,
              top: -2,
              child: _NotificationBadge(count: unreadCount),
            ),
        ],
      ),
      tooltip: 'Notifications',
      onPressed: () =>
          Navigator.of(context).pushNamed('/notification-settings'),
    );
  }
}

/// Notification badge displaying unread count
///
/// Displays:
/// - Exact count when count <= 9
/// - "9+" when count > 9
/// - Hidden when count = 0
class _NotificationBadge extends StatelessWidget {
  final int count;

  const _NotificationBadge({required this.count});

  String get _badgeText {
    if (count > 9) return '9+';
    return count.toString();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.error,
        borderRadius: BorderRadius.circular(10),
      ),
      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
      child: Text(
        _badgeText,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onError,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
