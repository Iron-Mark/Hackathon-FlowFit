import '../entities/sleep_session.dart';

/// Abstract repository interface for sleep data access
///
/// This interface defines the contract for sleep data operations.
/// Implementations can be mock repositories or real backend integrations.
abstract class SleepRepository {
  /// Get sleep sessions for a date range
  ///
  /// Returns a list of sleep sessions that occurred between [startDate] and [endDate]
  Future<List<SleepSession>> getSleepSessions({
    required DateTime startDate,
    required DateTime endDate,
  });

  /// Save a sleep session
  ///
  /// Persists the given sleep [session] to storage
  Future<void> saveSleepSession(SleepSession session);

  /// Get active sleep session (if any)
  ///
  /// Returns the currently active sleep session, or null if no session is in progress
  Future<SleepSession?> getActiveSleepSession();

  /// Update sleep session
  ///
  /// Updates the sleep session with the same ID as [session]
  Future<void> updateSleepSession(SleepSession session);
}
