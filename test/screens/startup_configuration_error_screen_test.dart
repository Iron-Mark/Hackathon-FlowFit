import 'package:flowfit/screens/startup_configuration_error_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('startup configuration error screen explains required values', (
    tester,
  ) async {
    await tester.pumpWidget(
      const FlowFitStartupErrorApp(
        message: 'SUPABASE_URL must be a real Supabase Project URL.',
      ),
    );

    expect(find.text('FlowFit setup is incomplete'), findsOneWidget);
    expect(find.textContaining('Supabase client values'), findsOneWidget);
    expect(find.textContaining('SUPABASE_URL'), findsWidgets);
    expect(find.textContaining('SUPABASE_PUBLISHABLE_KEY'), findsOneWidget);
    expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
  });
}
