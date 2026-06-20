import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flowfit/screens/home/home_screen.dart';

void main() {
  testWidgets('Home shows Galaxy Watch waiting state when watch disconnected', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Heart Rate'), findsOneWidget);
    expect(find.text('— BPM'), findsOneWidget);
    expect(find.text('Waiting for Galaxy Watch...'), findsOneWidget);
  });
}
