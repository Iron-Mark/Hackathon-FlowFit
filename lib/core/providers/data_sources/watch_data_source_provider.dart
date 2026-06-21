import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/watch_bridge.dart';

/// Provider for the watch data source
///
/// This wraps the WatchBridgeService as a data source in our clean architecture.
final watchDataSourceProvider = Provider((ref) {
  return WatchBridgeService();
});
