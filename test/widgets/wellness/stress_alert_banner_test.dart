import 'package:flowfit/widgets/wellness/stress_alert_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('stress alert banner wires route, snooze, and dismiss actions', (
    tester,
  ) async {
    var showRoutesCalls = 0;
    var snoozeCalls = 0;
    var dismissCalls = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              StressAlertBanner(
                onShowRoutes: () => showRoutesCalls++,
                onSnooze: () => snoozeCalls++,
                onDismiss: () => dismissCalls++,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('High stress levels detected'), findsOneWidget);
    expect(
      find.text('Recommendation: Take a walk to clear your mind'),
      findsOneWidget,
    );

    await tester.tap(find.text('Show Routes'));
    await tester.pump();
    await tester.tap(find.text('Not Now'));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.close));
    await tester.pump();

    expect(showRoutesCalls, 1);
    expect(snoozeCalls, 1);
    expect(dismissCalls, 1);
  });
}
