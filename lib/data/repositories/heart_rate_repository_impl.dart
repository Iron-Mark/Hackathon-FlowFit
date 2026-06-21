import '../../domain/entities/heart_rate_data.dart';
import '../../domain/repositories/heart_rate_repository.dart';
import '../../services/watch_bridge.dart';
import '../../services/supabase_service.dart';

/// Implementation of HeartRateRepository
///
/// This connects the domain layer to the data sources (watch and Supabase).
class HeartRateRepositoryImpl implements HeartRateRepository {
  final WatchBridgeService _watchBridge;
  final SupabaseService _supabaseService;

  HeartRateRepositoryImpl({
    required WatchBridgeService watchBridge,
    required SupabaseService supabaseService,
  }) : _watchBridge = watchBridge,
       _supabaseService = supabaseService;

  @override
  Stream<HeartRateData> get heartRateStream {
    // WatchBridgeService already returns HeartRateData objects
    return _watchBridge.heartRateStream.map((data) {
      // Convert from models/heart_rate_data.dart to domain/entities/heart_rate_data.dart
      return HeartRateData(
        bpm: data.bpm,
        ibiValues: data.ibiValues,
        timestamp: data.timestamp,
        status: _convertStatus(data.status.name),
      );
    });
  }

  HeartRateStatus _convertStatus(String status) {
    return HeartRateStatus.fromString(status);
  }

  @override
  Future<void> startTracking() async {
    await _watchBridge.startHeartRateTracking();
  }

  @override
  Future<void> stopTracking() async {
    await _watchBridge.stopHeartRateTracking();
  }

  @override
  Future<void> saveHeartRateData(HeartRateData data) async {
    await _supabaseService.saveHeartRateData(data.toJson());
  }

  @override
  Future<List<HeartRateData>> getHistoricalData({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final jsonData = await _supabaseService.getHeartRateData(
      startDate: startDate,
      endDate: endDate,
    );

    return jsonData.map((json) => HeartRateData.fromJson(json)).toList();
  }
}
