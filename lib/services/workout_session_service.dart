import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/workout_session.dart';
import '../models/running_session.dart';
import '../models/walking_session.dart';
import '../models/resistance_session.dart';

/// Service for managing workout session CRUD operations with Supabase
class WorkoutSessionService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Creates a new workout session in the database
  Future<String> createSession(WorkoutSession session) async {
    final data = session.toJson();
    final response = await _client
        .from('workout_sessions')
        .insert(data)
        .select('id')
        .single();

    return response['id'] as String;
  }

  /// Gets a workout session by ID
  Future<WorkoutSession?> getSession(String sessionId) async {
    final response = await _client
        .from('workout_sessions')
        .select()
        .eq('id', sessionId)
        .maybeSingle();

    if (response == null) return null;

    return _parseWorkoutSession(response);
  }

  /// Updates an existing workout session
  Future<void> updateSession(WorkoutSession session) async {
    final data = session.toJson();
    await _client.from('workout_sessions').update(data).eq('id', session.id);
  }

  /// Saves a workout session (creates if new, updates if exists)
  Future<void> saveSession(WorkoutSession session) async {
    final data = session.toJson();
    await _client.from('workout_sessions').upsert(data);
  }

  /// Lists recent workout sessions for the current user
  Future<List<WorkoutSession>> listRecentSessions({
    int limit = 20,
    WorkoutType? type,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      return [];
    }

    var query = _client
        .from('workout_sessions')
        .select()
        .eq('user_id', user.id);

    if (type != null) {
      query = query.eq('workout_type', type.name);
    }

    final response = await query
        .order('start_time', ascending: false)
        .limit(limit);

    return (response as List)
        .map((json) => _parseWorkoutSession(json as Map<String, dynamic>))
        .toList();
  }

  /// Deletes a workout session
  Future<void> deleteSession(String sessionId) async {
    await _client.from('workout_sessions').delete().eq('id', sessionId);
  }

  /// Gets workout sessions for a specific date range
  Future<List<WorkoutSession>> getSessionsInRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      return [];
    }

    final response = await _client
        .from('workout_sessions')
        .select()
        .eq('user_id', user.id)
        .gte('start_time', startDate.toIso8601String())
        .lte('start_time', endDate.toIso8601String())
        .order('start_time', ascending: false);

    return (response as List)
        .map((json) => _parseWorkoutSession(json as Map<String, dynamic>))
        .toList();
  }

  /// Parses JSON into the appropriate WorkoutSession subclass
  WorkoutSession _parseWorkoutSession(Map<String, dynamic> json) {
    final workoutType = json['workout_type'] as String;

    switch (workoutType) {
      case 'running':
        return RunningSession.fromJson(json);
      case 'walking':
        return WalkingSession.fromJson(json);
      case 'resistance':
        return ResistanceSession.fromJson(json);
      default:
        throw Exception('Unknown workout type: $workoutType');
    }
  }
}
