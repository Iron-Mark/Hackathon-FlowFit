import 'package:flowfit/screens/wear/wear_dashboard.dart';
import 'package:flowfit/screens/wear/wear_heart_rate_screen.dart';
import 'package:flowfit/screens/wear/workout_screen.dart';
import 'package:flowfit/screens/wear/relax_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wear_plus/wear_plus.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const permissionChannel = MethodChannel('com.flowfit.watch/data');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(permissionChannel, (call) async {
          if (call.method == 'checkPermission') {
            return 'granted';
          }
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(permissionChannel, null);
  });

  testWidgets('active Wear dashboard opens heart rate tracking', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: WearDashboard(shape: WearShape.round, mode: WearMode.active),
      ),
    );

    expect(find.text('FlowFit'), findsOneWidget);
    expect(find.text('Heart Rate'), findsOneWidget);
    expect(find.byType(WearHeartRateScreen), findsNothing);

    await tester.tap(find.text('Heart Rate'));
    await tester.pump();
    await tester.pump();

    expect(find.byType(WearHeartRateScreen), findsOneWidget);
  });

  testWidgets('active Wear dashboard opens workout and relax tools', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: WearDashboard(shape: WearShape.round, mode: WearMode.active),
      ),
    );

    expect(find.text('Workout'), findsOneWidget);
    expect(find.text('Relax'), findsOneWidget);

    await tester.tap(find.text('Workout'));
    await tester.pump();
    await tester.pump();

    expect(find.byType(WorkoutScreen), findsOneWidget);

    Navigator.of(tester.element(find.byType(WorkoutScreen))).pop();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Relax'));
    await tester.pump();
    await tester.pump();

    expect(find.byType(RelaxScreen), findsOneWidget);
  });

  testWidgets('ambient Wear dashboard avoids interactive controls', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: WearDashboard(shape: WearShape.round, mode: WearMode.ambient),
      ),
    );

    expect(find.text('FlowFit'), findsOneWidget);
    expect(find.text('Heart Rate'), findsNothing);
    expect(find.byType(ElevatedButton), findsNothing);
  });
}
