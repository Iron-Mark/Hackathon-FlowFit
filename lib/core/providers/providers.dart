// Core providers for the FlowFit phone app
//
// This file exports all providers used throughout the app.
// Organized by feature domain for clean architecture.
//
// Usage:
// ```dart
// import 'package:flowfit/core/providers/providers.dart';
//
// // In your ConsumerWidget:
// final heartRate = ref.watch(currentHeartRateProvider);
// ```

// Data Sources
export 'data_sources/watch_data_source_provider.dart';
export 'data_sources/supabase_data_source_provider.dart';

// Repositories
export 'repositories/heart_rate_repository_provider.dart';
export 'repositories/activity_repository_provider.dart';
export 'repositories/sleep_repository_provider.dart';

// Use Cases / Services
export 'services/heart_rate_service_provider.dart';

// UI State
export 'state/heart_rate_state_provider.dart';
export 'state/connection_state_provider.dart';

// Domain Entities (for convenience)
export '../../domain/entities/heart_rate_data.dart';
