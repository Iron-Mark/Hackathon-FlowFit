import 'package:flowfit/domain/entities/user_profile.dart';
import 'package:flowfit/domain/repositories/i_profile_repository.dart';
import 'package:flowfit/presentation/providers/providers.dart';
import 'package:flowfit/screens/onboarding/survey_basic_info_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('continue is disabled until required signup data is selected', (
    tester,
  ) async {
    final container = _container();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      _harness(container, args: const {'name': 'Test Member'}),
    );
    await _openSurvey(tester);

    var continueButton = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Continue'),
    );
    expect(continueButton.onPressed, isNull);

    await tester.tap(find.text('Male'));
    await tester.pumpAndSettle();

    continueButton = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Continue'),
    );
    expect(continueButton.onPressed, isNotNull);

    await tester.ensureVisible(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('route:body-measurements'), findsOneWidget);
    expect(container.read(surveyNotifierProvider).surveyData, {
      'fullName': 'Test Member',
      'age': 18,
      'gender': 'male',
    });
  });

  testWidgets('continue ignores duplicate taps before navigation settles', (
    tester,
  ) async {
    final container = _container();
    final routeObserver = _CountingNavigatorObserver();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      _harness(
        container,
        args: const {'name': 'Test Member'},
        navigatorObservers: [routeObserver],
      ),
    );
    await _openSurvey(tester);

    await tester.tap(find.text('Male'));
    await tester.pumpAndSettle();

    final continueButton = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Continue'),
    );
    expect(continueButton.onPressed, isNotNull);

    continueButton.onPressed!();
    continueButton.onPressed!();
    await tester.pumpAndSettle();

    expect(find.text('route:body-measurements'), findsOneWidget);
    expect(
      routeObserver.pushedNames
          .where((name) => name == '/survey_body_measurements')
          .length,
      1,
    );
  });

  testWidgets('age stepper increments, decrements, and respects bounds', (
    tester,
  ) async {
    final container = _container();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      _harness(container, args: const {'name': 'Test Member'}),
    );
    await _openSurvey(tester);

    expect(find.text('18'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pumpAndSettle();
    expect(find.text('19'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.remove_rounded));
    await tester.pumpAndSettle();
    expect(find.text('18'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).first, '120');
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pumpAndSettle();
    expect(find.text('120'), findsOneWidget);
    expect(find.text('121'), findsNothing);

    await tester.enterText(find.byType(TextFormField).first, '7');
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.remove_rounded));
    await tester.pumpAndSettle();
    expect(find.text('7'), findsOneWidget);
    expect(find.text('6'), findsNothing);
  });

  testWidgets('invalid age keeps the user on the basic info step', (
    tester,
  ) async {
    final container = _container();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      _harness(container, args: const {'name': 'Test Member'}),
    );
    await _openSurvey(tester);

    await tester.tap(find.text('Other'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, '6');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Tell us about yourself'), findsOneWidget);
    expect(find.text('route:body-measurements'), findsNothing);
  });

  testWidgets('edit mode requires a name before continuing', (tester) async {
    final container = _container();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      _harness(container, args: const {'fromEdit': true}),
    );
    await _openSurvey(tester);

    await tester.tap(find.text('Female'));
    await tester.pumpAndSettle();

    var continueButton = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Continue'),
    );
    expect(continueButton.onPressed, isNull);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Enter your full name'),
      'Edited Member',
    );
    await tester.pumpAndSettle();

    continueButton = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Continue'),
    );
    expect(continueButton.onPressed, isNotNull);

    await tester.ensureVisible(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('route:body-measurements'), findsOneWidget);
    expect(
      container.read(surveyNotifierProvider).surveyData['fullName'],
      'Edited Member',
    );
  });
}

ProviderContainer _container() {
  return ProviderContainer(
    overrides: [
      profileRepositoryProvider.overrideWithValue(_FakeProfileRepository()),
    ],
  );
}

Widget _harness(
  ProviderContainer container, {
  required Map<String, dynamic> args,
  List<NavigatorObserver> navigatorObservers = const [],
}) {
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      navigatorObservers: navigatorObservers,
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/survey_basic_info',
                  arguments: args,
                );
              },
              child: const Text('Open Survey'),
            ),
          ),
        ),
      ),
      onGenerateRoute: (settings) {
        if (settings.name == '/survey_basic_info') {
          return MaterialPageRoute<void>(
            settings: settings,
            builder: (_) => const SurveyBasicInfoScreen(),
          );
        }

        if (settings.name == '/survey_body_measurements') {
          return MaterialPageRoute<void>(
            settings: settings,
            builder: (_) =>
                const Scaffold(body: Text('route:body-measurements')),
          );
        }

        return null;
      },
    ),
  );
}

Future<void> _openSurvey(WidgetTester tester) async {
  await tester.tap(find.text('Open Survey'));
  await tester.pumpAndSettle();
  expect(find.text('Tell us about yourself'), findsOneWidget);
}

class _FakeProfileRepository implements IProfileRepository {
  @override
  Future<UserProfile> createProfile(UserProfile profile) async => profile;

  @override
  Future<UserProfile?> getProfile(String userId) async => null;

  @override
  Future<bool> hasCompletedSurvey(String userId) async => false;

  @override
  Future<UserProfile> updateProfile(UserProfile profile) async => profile;
}

class _CountingNavigatorObserver extends NavigatorObserver {
  final List<String?> pushedNames = [];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushedNames.add(route.settings.name);
    super.didPush(route, previousRoute);
  }
}
