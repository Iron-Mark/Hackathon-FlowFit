import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/supabase_service.dart';
import '../data_sources/supabase_data_source_provider.dart';

/// Provider for sleep data operations backed by Supabase.
///
/// Sleep features currently share [SupabaseService] directly instead of a
/// dedicated repository wrapper.
final sleepRepositoryProvider = Provider<SupabaseService>((ref) {
  return ref.watch(supabaseDataSourceProvider);
});
