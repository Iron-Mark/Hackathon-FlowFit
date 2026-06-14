import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Small debug-only floating button that opens a modal with pre-configured
/// routes for quick navigation while testing on a device.
/// Only included when running in debug mode.
class DebugRouteMenu extends StatelessWidget {
  const DebugRouteMenu({super.key, this.routes});

  // Default list of routes that are useful to test. You may add more.
  final List<Map<String, String>>? routes;

  List<Map<String, String>> get defaultRoutes => [
    {'route': '/font-demo', 'label': 'Font Demo'},
    {'route': '/', 'label': 'Loading'},
    {'route': '/dashboard', 'label': 'Dashboard'},
    {'route': '/trackertest', 'label': 'Tracker Test'},
  ];

  @override
  Widget build(BuildContext context) {
    // Only show this widget during debug.
    if (!kDebugMode) return const SizedBox.shrink();

    final menuRoutes = routes ?? defaultRoutes;

    return SafeArea(
      child: Align(
        alignment: Alignment.bottomRight,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: FloatingActionButton(
            heroTag: 'debugRouteMenu',
            mini: true,
            backgroundColor: Colors.black87,
            foregroundColor: Colors.white,
            child: const Icon(Icons.bug_report),
            onPressed: () => _openMenu(context, menuRoutes),
          ),
        ),
      ),
    );
  }

  void _openMenu(BuildContext context, List<Map<String, String>> routes) async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ListTile(
                title: Text('Debug Navigation'),
                subtitle: Text('Quickly jump to test screens'),
              ),
              const Divider(height: 1),
              for (final item in routes)
                ListTile(
                  title: Text(item['label'] ?? item['route']!),
                  subtitle: Text(item['route'] ?? ''),
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pushNamed(item['route']!);
                  },
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}
