import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/config/supabase_tables.dart';

/// Service for managing Supabase backend operations
class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Save heart rate data to Supabase
  Future<void> saveHeartRateData(Map<String, dynamic> data) async {
    await _client.from(SupabaseTables.heartRate).insert(data);
  }

  /// Save multiple heart rate records to Supabase.
  Future<void> saveHeartRateDataBatch(List<Map<String, dynamic>> data) async {
    if (data.isEmpty) return;
    await _client.from(SupabaseTables.heartRate).insert(data);
  }

  /// Get heart rate data for a date range
  Future<List<Map<String, dynamic>>> getHeartRateData({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final response = await _client
        .from(SupabaseTables.heartRate)
        .select()
        .gte('timestamp', startDate.millisecondsSinceEpoch)
        .lte('timestamp', endDate.millisecondsSinceEpoch)
        .order('timestamp', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }
}

// Restored SupabaseService implementation; supabase_flutter dependency used.
