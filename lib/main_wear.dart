import 'package:flutter/material.dart';
import 'package:wear_plus/wear_plus.dart';
import 'screens/wear/wear_dashboard.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const WearApp());
}

class WearApp extends StatelessWidget {
  const WearApp({super.key});

  @override
  Widget build(BuildContext context) {
    return WatchShape(
      builder: (context, shape, child) {
        return AmbientMode(
          builder: (context, mode, child) {
            // Adapt theme based on ambient mode (VGV best practice)
            final isAmbient = mode == WearMode.ambient;

            return MaterialApp(
              title: 'FlowFit Wear',
              debugShowCheckedModeBanner: false,
              theme: ThemeData(
                useMaterial3: true, // Use Material 3 (VGV recommendation)
                visualDensity:
                    VisualDensity.compact, // Compact for small screens
                colorScheme: isAmbient
                    ? const ColorScheme.dark(
                        // Monochromatic for ambient mode (battery saving)
                        primary: Colors.white24,
                        surface: Colors.black,
                        onSurface: Colors.white10,
                      )
                    : const ColorScheme.dark(
                        // Colorful for active mode
                        primary: Color(0xFF00B5FF),
                        secondary: Colors.blueAccent,
                        surface: Colors.black,
                        onSurface: Colors.white,
                      ),
                scaffoldBackgroundColor: Colors.black,
                elevatedButtonTheme: ElevatedButtonThemeData(
                  style: ElevatedButton.styleFrom(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                // Optimize text for small screens
                textTheme: const TextTheme(
                  displayLarge: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                  displayMedium: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  bodyLarge: TextStyle(fontSize: 16),
                  bodyMedium: TextStyle(fontSize: 14),
                ),
              ),
              home: WearDashboard(shape: shape, mode: mode),
            );
          },
        );
      },
    );
  }
}
