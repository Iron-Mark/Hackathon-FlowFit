import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flowfit/domain/repositories/i_auth_repository.dart';
import 'package:flowfit/data/repositories/auth_repository.dart';
import 'package:flowfit/presentation/notifiers/auth_notifier.dart';
import 'package:flowfit/presentation/notifiers/survey_notifier.dart';
import 'package:flowfit/domain/entities/auth_state.dart' as domain;
import 'package:flowfit/presentation/providers/profile_providers.dart';

// Export profile providers from dedicated file. supabaseClientProvider and
// the unified profileRepositoryProvider come from there — this file no
// longer declares shadowing duplicates.
export 'package:flowfit/presentation/providers/profile_providers.dart';

/// Provider for authentication repository.
///
/// Creates an instance of AuthRepository with the Supabase client.
///
/// Requirement 8.1: Use Riverpod providers for state management
/// Requirement 8.2: Use repository pattern to abstract Supabase operations
final authRepositoryProvider = Provider<IAuthRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return AuthRepository(client);
});

/// StateNotifier provider for authentication state.
///
/// Manages authentication state including sign up, sign in, sign out,
/// and session restoration.
///
/// Requirement 8.1: Use Riverpod providers for state management
/// Requirement 8.4: Consume state through providers without direct service dependencies
final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, domain.AuthState>((ref) {
      final authRepository = ref.watch(authRepositoryProvider);
      return AuthNotifier(authRepository);
    });

/// StateNotifier provider for survey state.
///
/// Manages survey data collection, validation, and submission.
///
/// Requirement 8.1: Use Riverpod providers for state management
/// Requirement 8.4: Consume state through providers without direct service dependencies
final surveyNotifierProvider =
    StateNotifierProvider<SurveyNotifier, SurveyState>((ref) {
      return SurveyNotifier();
    });
