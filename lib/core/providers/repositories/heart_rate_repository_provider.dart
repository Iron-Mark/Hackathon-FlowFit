import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/repositories/heart_rate_repository.dart';
import '../../../data/repositories/heart_rate_repository_impl.dart';
import '../data_sources/watch_data_source_provider.dart';
import '../data_sources/supabase_data_source_provider.dart';

/// Provider for the heart rate repository
///
/// This creates the repository with its dependencies injected.
final heartRateRepositoryProvider = Provider<HeartRateRepository>((ref) {
  final watchBridge = ref.watch(watchDataSourceProvider);
  final supabaseService = ref.watch(supabaseDataSourceProvider);

  return HeartRateRepositoryImpl(
    watchBridge: watchBridge,
    supabaseService: supabaseService,
  );
});
