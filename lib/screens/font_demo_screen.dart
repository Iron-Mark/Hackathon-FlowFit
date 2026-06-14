import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FontDemoScreen extends StatelessWidget {
  const FontDemoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Font Demo — FlowFit')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FutureBuilder<String>(
              future: rootBundle.loadString('FontManifest.json'),
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const SizedBox.shrink();
                }
                if (snapshot.hasError) {
                  return Text(
                    'Error reading FontManifest.json: ${snapshot.error}',
                  );
                }
                final manifest = jsonDecode(snapshot.data ?? '[]');
                final found = (manifest as List).any((entry) {
                  final map = entry as Map<String, dynamic>;
                  return map['family'] == 'GeneralSans';
                });

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Default fontFamily: ${DefaultTextStyle.of(context).style.fontFamily ?? 'not set'}',
                    ),
                    Text(
                      'GeneralSans present in FontManifest: ${found ? 'yes' : 'no'}',
                    ),
                    const SizedBox(height: 16),
                  ],
                );
              },
            ),
            Text(
              'Display Large',
              style: Theme.of(context).textTheme.displayLarge,
            ),
            const SizedBox(height: 12),
            Text(
              'Headline Small',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Text('Title Large', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Text('Body Medium', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 12),
            Text('Label Small', style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(height: 24),
            Text(
              'This text uses the configured `fontFamily` in AppTheme. If you don\'t see the font, be sure you added the ttf/otf files under `assets/fonts/GeneralSans` and registered them in `pubspec.yaml`.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            const Text(
              'Compare with a system font: This should look different if GeneralSans is applied.',
              style: TextStyle(fontFamily: 'Roboto', fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
