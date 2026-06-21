import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/config/supabase_tables.dart';
import '../models/workout_session.dart';

/// Service for managing workout session CRUD operations with Supabase
class WorkoutSessionService {
  SupabaseClient get _client => Supabase.instance.client;

  /// Creates a new workout session in the database
  Future<String> createSession(WorkoutSession session) async {
    final data = session.toJson();
    final response = await _client
        .from(SupabaseTables.workoutSessions)
        .insert(data)
        .select('id')
        .single();

    return response['id'] as String;
  }

  /// Gets a workout session by ID
  Future<WorkoutSession?> getSession(String sessionId) async {
    final response = await _client
        .from(SupabaseTables.workoutSessions)
        .select()
        .eq('id', sessionId)
        .maybeSingle();

    if (response == null) return null;

    return parseWorkoutSession(response);
  }

  /// Updates an existing workout session
  Future<void> updateSession(WorkoutSession session) async {
    final data = session.toJson();
    await _client
        .from(SupabaseTables.workoutSessions)
        .update(data)
        .eq('id', session.id);
  }

  /// Saves a workout session (creates if new, updates if exists)
  Future<void> saveSession(WorkoutSession session) async {
    final data = session.toJson();
    await _client.from(SupabaseTables.workoutSessions).upsert(data);
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
        .from(SupabaseTables.workoutSessions)
        .select()
        .eq('user_id', user.id);

    if (type != null) {
      query = query.eq('workout_type', type.name);
    }

    final response = await query
        .order('start_time', ascending: false)
        .limit(limit);

    return (response as List)
        .map((json) => parseWorkoutSession(json as Map<String, dynamic>))
        .toList();
  }

  /// Deletes a workout session
  Future<void> deleteSession(String sessionId) async {
    await _client
        .from(SupabaseTables.workoutSessions)
        .delete()
        .eq('id', sessionId);
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
        .from(SupabaseTables.workoutSessions)
        .select()
        .eq('user_id', user.id)
        .gte('start_time', startDate.toIso8601String())
        .lte('start_time', endDate.toIso8601String())
        .order('start_time', ascending: false);

    return (response as List)
        .map((json) => parseWorkoutSession(json as Map<String, dynamic>))
        .toList();
  }

  /// Parses a Supabase workout row into the appropriate session subtype.
  static WorkoutSession parseWorkoutSession(Map<String, dynamic> json) {
    return WorkoutSession.fromJson(json);
  }
}
