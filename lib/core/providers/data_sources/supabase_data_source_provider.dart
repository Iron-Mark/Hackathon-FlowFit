import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/supabase_service.dart';

/// Provider for Supabase data source
///
/// This wraps the SupabaseService as a data source in our clean architecture.
final supabaseDataSourceProvider = Provider((ref) {
  return SupabaseService();
});
