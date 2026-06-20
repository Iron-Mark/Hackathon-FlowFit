import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class FlowFitStartupErrorApp extends StatelessWidget {
  const FlowFitStartupErrorApp({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FlowFit',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: StartupConfigurationErrorScreen(message: message),
    );
  }
}

class StartupConfigurationErrorScreen extends StatelessWidget {
  const StartupConfigurationErrorScreen({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.settings_outlined,
                    color: AppTheme.primaryBlue,
                    size: 44,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'FlowFit setup is incomplete',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: AppTheme.text,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Set the Supabase client values before running this build.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: AppTheme.darkGray,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppTheme.darkGray.withValues(alpha: 0.18),
                      ),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(16),
                      child: SelectableText(
                        'flutter run --dart-define=SUPABASE_URL=... '
                        '--dart-define=SUPABASE_PUBLISHABLE_KEY=...',
                        style: TextStyle(
                          color: AppTheme.text,
                          fontFamily: 'monospace',
                          fontSize: 13,
                          height: 1.45,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    message,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.darkGray,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
