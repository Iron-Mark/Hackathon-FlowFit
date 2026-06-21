import 'package:flowfit/screens/font_demo_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('font demo renders manifest status and typography samples', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const MaterialApp(home: FontDemoScreen()));
    await tester.pumpAndSettle();

    expect(find.textContaining('Font Demo'), findsOneWidget);
    expect(find.textContaining('Default fontFamily:'), findsOneWidget);
    expect(
      find.textContaining('GeneralSans present in FontManifest:'),
      findsOneWidget,
    );
    expect(find.text('Display Large'), findsOneWidget);
    expect(find.text('Headline Small'), findsOneWidget);
    expect(find.text('Title Large'), findsOneWidget);
    expect(find.text('Body Medium'), findsOneWidget);
    expect(find.text('Label Small'), findsOneWidget);
  });
}
