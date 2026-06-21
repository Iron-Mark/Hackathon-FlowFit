import 'package:flowfit/main_wear.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('WearApp boots to the dashboard', (tester) async {
    tester.view.physicalSize = const Size(390, 390);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const WearApp());
    await tester.pumpAndSettle();

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('FlowFit'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Heart Rate'), findsOneWidget);
  });
}
