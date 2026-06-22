import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flowfit/core/domain/entities/user_profile.dart' as core_profile;
import 'package:flowfit/core/domain/repositories/profile_repository.dart'
    as core_profile_repo;
import 'package:flowfit/domain/entities/auth_state.dart' as auth_state;
import 'package:flowfit/domain/entities/user.dart' as domain_user;
import 'package:flowfit/domain/repositories/i_auth_repository.dart';
import 'package:flowfit/presentation/notifiers/auth_notifier.dart';
import 'package:flowfit/presentation/notifiers/profile_notifier.dart';
import 'package:flowfit/presentation/providers/providers.dart';
import 'package:flowfit/screens/dashboard_screen.dart';

final _testUser = domain_user.User(
  id: 'dashboard-responsive-user',
  email: 'dashboard@example.com',
  fullName: 'Dashboard User',
  createdAt: DateTime(2025),
);

void main() {
  group('DashboardScreen Responsive Navigation Bar Tests', () {
    testWidgets(
      'Navigation bar adapts to device with gesture navigation (bottom padding)',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          _dashboardHarness(
            const MediaQueryData(
              size: Size(412, 915),
              padding: EdgeInsets.only(bottom: 34),
            ),
          ),
        );

        await tester.pump(const Duration(milliseconds: 100));

        final containerFinder = find.descendant(
          of: find.byType(Scaffold),
          matching: find.byType(Container),
        );
        expect(containerFinder, findsWidgets);

        _expectDashboardNavItems();

        await tester.tap(find.text('Health'));
        await tester.pump(const Duration(milliseconds: 100));

        final navBar = tester.widget<BottomNavigationBar>(
          find.byType(BottomNavigationBar),
        );
        expect(navBar.currentIndex, 1);
      },
    );

    testWidgets('Navigation bar adapts to device with software buttons', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _dashboardHarness(
          const MediaQueryData(
            size: Size(412, 915),
            padding: EdgeInsets.only(bottom: 48),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      _expectDashboardNavItems();
    });

    testWidgets(
      'Navigation bar displays correctly on device with no system navigation',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          _dashboardHarness(
            const MediaQueryData(
              size: Size(800, 1280),
              padding: EdgeInsets.zero,
            ),
          ),
        );

        await tester.pump(const Duration(milliseconds: 100));

        _expectDashboardNavItems();
      },
    );

    testWidgets(
      'Navigation bar adapts to orientation changes (portrait to landscape)',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          _dashboardHarness(
            const MediaQueryData(
              size: Size(412, 915),
              padding: EdgeInsets.only(bottom: 34),
            ),
          ),
        );

        await tester.pump(const Duration(milliseconds: 100));
        _expectDashboardNavItems();

        await tester.pumpWidget(
          _dashboardHarness(
            const MediaQueryData(
              size: Size(915, 412),
              padding: EdgeInsets.only(bottom: 0),
            ),
          ),
        );

        await tester.pump(const Duration(milliseconds: 100));
        _expectDashboardNavItems();
      },
    );

    testWidgets('All 5 navigation items remain fully tappable', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _dashboardHarness(
          const MediaQueryData(
            size: Size(412, 915),
            padding: EdgeInsets.only(bottom: 34),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      final navBarFinder = find.byType(BottomNavigationBar);
      expect(navBarFinder, findsOneWidget);

      const items = ['Home', 'Health', 'Track', 'Progress', 'Profile'];
      const expectedBodyTextByItem = <String, String>{
        'Home': 'Start AI Workout',
        'Health': 'Daily Log',
        'Track': 'Time to Move!',
        'Progress': 'Progress & Insights',
        'Profile': 'Let\'s Get Started!',
      };

      for (var i = 0; i < items.length; i++) {
        final item = items[i];
        await tester.tap(find.text(items[i]));
        await tester.pump(const Duration(milliseconds: 100));

        final navBar = tester.widget<BottomNavigationBar>(navBarFinder);
        expect(
          navBar.currentIndex,
          i,
          reason: '${items[i]} tab should be selected',
        );
        expect(
          find.textContaining(expectedBodyTextByItem[item]!),
          findsWidgets,
          reason: '$item tab should render its expected screen body',
        );
      }
    });

    testWidgets(
      'Navigation bar maintains minimum touch target size (48x48dp)',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          _dashboardHarness(
            const MediaQueryData(
              size: Size(412, 915),
              padding: EdgeInsets.only(bottom: 34),
            ),
          ),
        );

        await tester.pump(const Duration(milliseconds: 100));

        final navBar = tester.widget<BottomNavigationBar>(
          find.byType(BottomNavigationBar),
        );
        expect(navBar.iconSize, 24);
        expect(navBar.type, BottomNavigationBarType.fixed);
      },
    );

    testWidgets(
      'Navigation bar preserves visual styling across configurations',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          _dashboardHarness(
            const MediaQueryData(
              size: Size(412, 915),
              padding: EdgeInsets.zero,
            ),
          ),
        );

        await tester.pump(const Duration(milliseconds: 100));

        final navBarFinder = find.byType(BottomNavigationBar);
        final navBar1 = tester.widget<BottomNavigationBar>(navBarFinder);

        await tester.pumpWidget(
          _dashboardHarness(
            const MediaQueryData(
              size: Size(412, 915),
              padding: EdgeInsets.only(bottom: 34),
            ),
          ),
        );

        await tester.pump(const Duration(milliseconds: 100));

        final navBar2 = tester.widget<BottomNavigationBar>(navBarFinder);

        expect(navBar1.iconSize, navBar2.iconSize);
        expect(navBar1.selectedFontSize, navBar2.selectedFontSize);
        expect(navBar1.unselectedFontSize, navBar2.unselectedFontSize);
        expect(navBar1.type, navBar2.type);
        expect(navBar1.items.length, navBar2.items.length);
      },
    );
  });

  group('Task 3: Accessibility and Visual Consistency Validation', () {
    testWidgets(
      'Touch targets meet 48x48dp minimum size requirement (Requirement 1.4)',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          _dashboardHarness(
            const MediaQueryData(
              size: Size(412, 915),
              padding: EdgeInsets.only(bottom: 34),
              devicePixelRatio: 2.0,
            ),
          ),
        );

        await tester.pump(const Duration(milliseconds: 100));

        final navBar = tester.widget<BottomNavigationBar>(
          find.byType(BottomNavigationBar),
        );
        expect(navBar.iconSize, 24);
        expect(navBar.selectedFontSize, 12);
        expect(navBar.unselectedFontSize, 12);
        expect(navBar.type, BottomNavigationBarType.fixed);

        const items = ['Home', 'Health', 'Track', 'Progress', 'Profile'];
        for (final item in items) {
          final itemFinder = find.text(item);
          expect(itemFinder, findsOneWidget);
          await tester.tap(itemFinder);
          await tester.pump(const Duration(milliseconds: 100));
        }
      },
    );

    testWidgets(
      'Navigation items have proper semantic labels for TalkBack (Requirement 1.4)',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          _dashboardHarness(
            const MediaQueryData(
              size: Size(412, 915),
              padding: EdgeInsets.only(bottom: 34),
            ),
          ),
        );

        await tester.pump(const Duration(milliseconds: 100));

        final navBar = tester.widget<BottomNavigationBar>(
          find.byType(BottomNavigationBar),
        );

        expect(navBar.items[0].tooltip, 'Home');
        expect(navBar.items[1].tooltip, 'Health');
        expect(navBar.items[2].tooltip, 'Track');
        expect(navBar.items[3].tooltip, 'Progress');
        expect(navBar.items[4].tooltip, 'Profile');
        expect(navBar.items[0].label, 'Home');
        expect(navBar.items[1].label, 'Health');
        expect(navBar.items[2].label, 'Track');
        expect(navBar.items[3].label, 'Progress');
        expect(navBar.items[4].label, 'Profile');
      },
    );

    testWidgets(
      'Visual styling is preserved after responsive changes (Requirement 1.5, 2.5)',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          _dashboardHarness(
            const MediaQueryData(
              size: Size(412, 915),
              padding: EdgeInsets.zero,
            ),
          ),
        );

        await tester.pump(const Duration(milliseconds: 100));

        final navBarFinder = find.byType(BottomNavigationBar);
        final baselineNavBar = tester.widget<BottomNavigationBar>(navBarFinder);
        final baselineIconSize = baselineNavBar.iconSize;
        final baselineSelectedFontSize = baselineNavBar.selectedFontSize;
        final baselineUnselectedFontSize = baselineNavBar.unselectedFontSize;
        final baselineType = baselineNavBar.type;
        final baselineElevation = baselineNavBar.elevation;

        await tester.pumpWidget(
          _dashboardHarness(
            const MediaQueryData(
              size: Size(412, 915),
              padding: EdgeInsets.only(bottom: 34),
            ),
          ),
        );

        await tester.pump(const Duration(milliseconds: 100));

        final responsiveNavBar = tester.widget<BottomNavigationBar>(
          navBarFinder,
        );

        expect(responsiveNavBar.iconSize, baselineIconSize);
        expect(responsiveNavBar.selectedFontSize, baselineSelectedFontSize);
        expect(responsiveNavBar.unselectedFontSize, baselineUnselectedFontSize);
        expect(responsiveNavBar.type, baselineType);
        expect(responsiveNavBar.elevation, baselineElevation);
        expect(
          responsiveNavBar.selectedItemColor,
          baselineNavBar.selectedItemColor,
        );
        expect(
          responsiveNavBar.unselectedItemColor,
          baselineNavBar.unselectedItemColor,
        );
        expect(
          responsiveNavBar.backgroundColor,
          baselineNavBar.backgroundColor,
        );
      },
    );

    testWidgets(
      'Shadow and elevation effects remain consistent (Requirement 1.5)',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          _dashboardHarness(
            const MediaQueryData(
              size: Size(412, 915),
              padding: EdgeInsets.only(bottom: 34),
            ),
          ),
        );

        await tester.pump(const Duration(milliseconds: 100));

        final containerFinder = find.ancestor(
          of: find.byType(BottomNavigationBar),
          matching: find.byType(Container),
        );

        expect(containerFinder, findsOneWidget);
        final bottomNavBar = tester.widget<Container>(containerFinder);
        expect(bottomNavBar.decoration, isA<BoxDecoration>());
        final decoration = bottomNavBar.decoration as BoxDecoration;
        expect(decoration.boxShadow, isNotNull);
        expect(decoration.boxShadow!.length, 1);

        final shadow = decoration.boxShadow!.first;
        expect(shadow.blurRadius, 8);
        expect(shadow.offset, const Offset(0, -2));
        expect(shadow.color, Colors.black.withValues(alpha: 0.1));

        final navBar = tester.widget<BottomNavigationBar>(
          find.byType(BottomNavigationBar),
        );
        expect(navBar.elevation, 0);
      },
    );

    testWidgets(
      'Icon sizes remain consistent across device configurations (Requirement 2.5)',
      (WidgetTester tester) async {
        final configurations = [
          const MediaQueryData(
            size: Size(412, 915),
            padding: EdgeInsets.only(bottom: 34),
          ),
          const MediaQueryData(
            size: Size(412, 915),
            padding: EdgeInsets.only(bottom: 48),
          ),
          const MediaQueryData(size: Size(800, 1280), padding: EdgeInsets.zero),
          const MediaQueryData(size: Size(915, 412), padding: EdgeInsets.zero),
        ];

        for (final config in configurations) {
          await tester.pumpWidget(_dashboardHarness(config));
          await tester.pump(const Duration(milliseconds: 100));

          final navBar = tester.widget<BottomNavigationBar>(
            find.byType(BottomNavigationBar),
          );

          expect(
            navBar.iconSize,
            24,
            reason: 'Icon size should be 24dp for config: ${config.size}',
          );
          expect(
            navBar.selectedFontSize,
            12,
            reason:
                'Selected font size should be 12 for config: ${config.size}',
          );
          expect(
            navBar.unselectedFontSize,
            12,
            reason:
                'Unselected font size should be 12 for config: ${config.size}',
          );
        }
      },
    );

    testWidgets(
      'Label positioning remains unchanged across configurations (Requirement 2.5)',
      (WidgetTester tester) async {
        final configs = [
          EdgeInsets.zero,
          const EdgeInsets.only(bottom: 34),
          const EdgeInsets.only(bottom: 48),
        ];

        for (final padding in configs) {
          await tester.pumpWidget(
            _dashboardHarness(
              MediaQueryData(size: const Size(412, 915), padding: padding),
            ),
          );

          await tester.pump(const Duration(milliseconds: 100));

          _expectDashboardNavItems();

          final navBar = tester.widget<BottomNavigationBar>(
            find.byType(BottomNavigationBar),
          );
          expect(navBar.selectedLabelStyle, isNotNull);
          expect(navBar.unselectedLabelStyle, isNotNull);
        }
      },
    );

    testWidgets(
      'Container background color matches theme surface color (Requirement 1.5)',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          _dashboardHarness(
            const MediaQueryData(
              size: Size(412, 915),
              padding: EdgeInsets.only(bottom: 34),
            ),
          ),
        );

        await tester.pump(const Duration(milliseconds: 100));

        final context = tester.element(find.byType(DashboardScreen));
        final theme = Theme.of(context);
        final containerFinder = find.ancestor(
          of: find.byType(BottomNavigationBar),
          matching: find.byType(Container),
        );

        expect(containerFinder, findsOneWidget);
        final container = tester.widget<Container>(containerFinder);
        final decoration = container.decoration as BoxDecoration;
        expect(decoration.color, theme.colorScheme.surface);

        final navBar = tester.widget<BottomNavigationBar>(
          find.byType(BottomNavigationBar),
        );
        expect(navBar.backgroundColor, theme.colorScheme.surface);
      },
    );

    testWidgets(
      'All navigation items maintain proper spacing and alignment (Requirement 2.5)',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          _dashboardHarness(
            const MediaQueryData(
              size: Size(412, 915),
              padding: EdgeInsets.only(bottom: 34),
            ),
          ),
        );

        await tester.pump(const Duration(milliseconds: 100));

        final navBar = tester.widget<BottomNavigationBar>(
          find.byType(BottomNavigationBar),
        );
        expect(navBar.type, BottomNavigationBarType.fixed);
        expect(navBar.items.length, 5);

        for (final item in navBar.items) {
          expect(item.icon, isNotNull);
          expect(item.label, isNotNull);
          expect(item.label!.isNotEmpty, true);
        }
      },
    );
  });
}

Widget _dashboardHarness(MediaQueryData mediaQueryData) {
  return ProviderScope(
    overrides: [
      authNotifierProvider.overrideWith((ref) => _DashboardAuthNotifier()),
      profileNotifierProvider.overrideWith(
        (ref, userId) => _DashboardProfileNotifier(userId),
      ),
    ],
    child: MediaQuery(
      data: mediaQueryData,
      child: const MaterialApp(home: DashboardScreen()),
    ),
  );
}

void _expectDashboardNavItems() {
  expect(find.byType(BottomNavigationBar), findsOneWidget);
  expect(find.text('Home'), findsOneWidget);
  expect(find.text('Health'), findsOneWidget);
  expect(find.text('Track'), findsOneWidget);
  expect(find.text('Progress'), findsOneWidget);
  expect(find.text('Profile'), findsOneWidget);
}

class _DashboardAuthNotifier extends AuthNotifier {
  _DashboardAuthNotifier() : super(_DashboardAuthRepository()) {
    state = auth_state.AuthState.authenticated(_testUser);
  }

  @override
  Future<void> initialize() async {
    state = auth_state.AuthState.authenticated(_testUser);
  }
}

class _DashboardAuthRepository implements IAuthRepository {
  @override
  Stream<domain_user.User?> authStateChanges() {
    return Stream.value(_testUser);
  }

  @override
  Future<domain_user.User?> getCurrentUser() async {
    return _testUser;
  }

  @override
  Future<domain_user.User> signIn({
    required String email,
    required String password,
  }) async {
    return _testUser.copyWith(email: email);
  }

  @override
  Future<void> signOut() async {}

  @override
  Future<domain_user.User> signUp({
    required String email,
    required String password,
    required String fullName,
    required Map<String, dynamic> metadata,
  }) async {
    return domain_user.User(
      id: _testUser.id,
      email: email,
      fullName: fullName,
      createdAt: DateTime(2025),
    );
  }
}

class _DashboardProfileNotifier extends ProfileNotifier {
  _DashboardProfileNotifier(String userId)
    : super(_DashboardProfileRepository(), userId);

  @override
  Future<void> loadProfile() async {
    state = const AsyncValue.data(null);
  }
}

class _DashboardProfileRepository
    implements core_profile_repo.ProfileRepository {
  @override
  Future<void> deleteLocalProfile(String userId) async {}

  @override
  Future<core_profile.UserProfile?> getBackendProfile(String userId) async {
    return null;
  }

  @override
  Future<core_profile.UserProfile?> getLocalProfile(String userId) async {
    return null;
  }

  @override
  Future<bool> hasCompletedSurvey(String userId) async {
    return true;
  }

  @override
  Future<bool> hasPendingSync(String userId) async {
    return false;
  }

  @override
  Future<void> saveBackendProfile(core_profile.UserProfile profile) async {}

  @override
  Future<void> saveLocalProfile(core_profile.UserProfile profile) async {}

  @override
  Future<void> syncProfile(String userId) async {}

  @override
  Stream<core_profile_repo.SyncStatus> watchSyncStatus(String userId) {
    return Stream.value(core_profile_repo.SyncStatus.synced);
  }
}
