import 'package:flowfit/widgets/debug_route_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('debug route menu opens quick routes and navigates by name', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: const Scaffold(
          body: DebugRouteMenu(
            routes: [
              {'route': '/target', 'label': 'Target Screen'},
            ],
          ),
        ),
        routes: {
          '/target': (_) =>
              const Scaffold(body: Center(child: Text('Target Route'))),
        },
      ),
    );

    await tester.tap(find.byIcon(Icons.bug_report));
    await tester.pumpAndSettle();

    expect(find.text('Debug Navigation'), findsOneWidget);
    expect(find.text('Target Screen'), findsOneWidget);
    expect(find.text('/target'), findsOneWidget);

    await tester.tap(find.text('Target Screen'));
    await tester.pumpAndSettle();

    expect(find.text('Target Route'), findsOneWidget);
  });
}
