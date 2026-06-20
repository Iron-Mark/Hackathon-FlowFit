import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/supabase_service.dart';
import '../data_sources/supabase_data_source_provider.dart';

/// Provider for activity data operations backed by Supabase.
///
/// Activity features currently share [SupabaseService] directly instead of a
/// dedicated repository wrapper.
final activityRepositoryProvider = Provider<SupabaseService>((ref) {
  return ref.watch(supabaseDataSourceProvider);
});
