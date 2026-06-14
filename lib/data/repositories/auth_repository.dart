import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/user.dart' as domain;
import '../../domain/repositories/i_auth_repository.dart';
import '../../domain/exceptions/auth_exceptions.dart' as domain_exceptions;
import '../../core/utils/error_logger.dart';
import '../../core/config/flowfit_runtime_config.dart';

/// Implementation of IAuthRepository using Supabase as the backend.
class AuthRepository implements IAuthRepository {
  final SupabaseClient _client;

  AuthRepository(this._client);

  /// Email validation regex pattern.
  static final _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  @override
  Future<domain.User> signUp({
    required String email,
    required String password,
    required String fullName,
    required Map<String, dynamic> metadata,
  }) async {
    try {
      // Validate email format locally before making API call
      if (!_emailRegex.hasMatch(email)) {
        ErrorLogger.logWarning(
          'AuthRepository.signUp',
          'Invalid email format provided',
        );
        throw domain_exceptions.InvalidEmailException();
      }

      // Validate password length
      if (password.length < 8) {
        ErrorLogger.logWarning('AuthRepository.signUp', 'Password too short');
        throw domain_exceptions.WeakPasswordException();
      }

      // Prepare user metadata
      final userMetadata = {'full_name': fullName, ...metadata};

      // Call Supabase signUp with deep link redirect
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: userMetadata,
        emailRedirectTo: FlowFitRuntimeConfig.authRedirectUrl(),
      );

      if (response.user == null) {
        ErrorLogger.logError(
          'AuthRepository.signUp',
          'Supabase returned null user after signup',
          StackTrace.current,
        );
        throw domain_exceptions.UnknownException();
      }

      // Convert Supabase user to domain User
      return _mapSupabaseUserToDomain(response.user!);
    } on domain_exceptions.AuthException {
      rethrow;
    } on AuthApiException catch (e, stackTrace) {
      ErrorLogger.logError('AuthRepository.signUp', e, stackTrace);
      throw _mapSupabaseError(e);
    } catch (e, stackTrace) {
      ErrorLogger.logError('AuthRepository.signUp', e, stackTrace);
      if (e.toString().contains('network') ||
          e.toString().contains('connection')) {
        throw domain_exceptions.NetworkException();
      }
      throw domain_exceptions.UnknownException();
    }
  }

  @override
  Future<domain.User> signIn({
    required String email,
    required String password,
  }) async {
    try {
      // Call Supabase signInWithPassword
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        ErrorLogger.logWarning(
          'AuthRepository.signIn',
          'Supabase returned null user after sign in',
        );
        throw domain_exceptions.InvalidCredentialsException();
      }

      // Convert Supabase user to domain User
      return _mapSupabaseUserToDomain(response.user!);
    } on domain_exceptions.AuthException {
      rethrow;
    } on AuthApiException catch (e, stackTrace) {
      ErrorLogger.logError('AuthRepository.signIn', e, stackTrace);
      throw _mapSupabaseError(e);
    } catch (e, stackTrace) {
      ErrorLogger.logError('AuthRepository.signIn', e, stackTrace);
      if (e.toString().contains('network') ||
          e.toString().contains('connection')) {
        throw domain_exceptions.NetworkException();
      }
      throw domain_exceptions.UnknownException();
    }
  }

  @override
  Future<void> signOut() async {
    try {
      // Call Supabase signOut to clear session
      await _client.auth.signOut();
    } on AuthApiException catch (e, stackTrace) {
      ErrorLogger.logError('AuthRepository.signOut', e, stackTrace);
      throw _mapSupabaseError(e);
    } catch (e, stackTrace) {
      ErrorLogger.logError('AuthRepository.signOut', e, stackTrace);
      if (e.toString().contains('network') ||
          e.toString().contains('connection')) {
        throw domain_exceptions.NetworkException();
      }
      throw domain_exceptions.UnknownException();
    }
  }

  @override
  Future<domain.User?> getCurrentUser() async {
    try {
      final session = _client.auth.currentSession;
      if (session == null) {
        return null;
      }

      final user = _client.auth.currentUser;
      if (user == null) {
        return null;
      }

      return _mapSupabaseUserToDomain(user);
    } catch (e, stackTrace) {
      // If there's an error getting current user, log it and return null
      ErrorLogger.logError('AuthRepository.getCurrentUser', e, stackTrace);
      return null;
    }
  }

  @override
  Stream<domain.User?> authStateChanges() {
    return _client.auth.onAuthStateChange.map((event) {
      final user = event.session?.user;
      if (user == null) {
        return null;
      }
      return _mapSupabaseUserToDomain(user);
    });
  }

  /// Maps a Supabase User to a domain User entity.
  domain.User _mapSupabaseUserToDomain(User supabaseUser) {
    return domain.User(
      id: supabaseUser.id,
      email: supabaseUser.email ?? '',
      fullName: supabaseUser.userMetadata?['full_name'] as String?,
      createdAt: DateTime.parse(supabaseUser.createdAt),
      emailConfirmedAt: supabaseUser.emailConfirmedAt != null
          ? DateTime.parse(supabaseUser.emailConfirmedAt!)
          : null,
    );
  }

  /// Maps Supabase errors to domain exceptions.
  domain_exceptions.AuthException _mapSupabaseError(AuthApiException error) {
    final message = error.message.toLowerCase();

    if (message.contains('email') && message.contains('already')) {
      return domain_exceptions.EmailAlreadyExistsException();
    }

    if (message.contains('invalid') &&
        (message.contains('credentials') ||
            message.contains('email') ||
            message.contains('password'))) {
      return domain_exceptions.InvalidCredentialsException();
    }

    if (message.contains('weak') || message.contains('password')) {
      return domain_exceptions.WeakPasswordException();
    }

    if (message.contains('network') || message.contains('connection')) {
      return domain_exceptions.NetworkException();
    }

    return domain_exceptions.UnknownException();
  }
}
