import 'package:flowfit/screens/loading_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('loading screen replaces itself with welcome after delay', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: const LoadingScreen(),
        routes: {
          '/welcome': (_) => const Scaffold(body: Text('route:welcome')),
        },
      ),
    );

    expect(find.text('FlowFit'), findsOneWidget);
    expect(find.text('route:welcome'), findsNothing);

    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    expect(find.text('route:welcome'), findsOneWidget);
    expect(find.byType(LoadingScreen), findsNothing);
  });
}
