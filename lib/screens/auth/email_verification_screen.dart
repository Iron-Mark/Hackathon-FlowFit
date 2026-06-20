import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:solar_icons/solar_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gotrue/gotrue.dart' as gotrue;
import '../../theme/app_theme.dart';
import 'dart:async';

typedef EmailVerificationStatusChecker = Future<bool> Function();
typedef EmailVerificationEmailResender = Future<void> Function(String email);
typedef EmailVerificationAuthStateStream = Stream<gotrue.AuthState> Function();

class EmailVerificationScreen extends ConsumerStatefulWidget {
  const EmailVerificationScreen({
    super.key,
    this.checkVerificationStatus,
    this.resendVerificationEmail,
    this.authStateChanges,
    this.autoCheckInterval = const Duration(seconds: 5),
    this.navigationDelay = const Duration(milliseconds: 500),
  });

  final EmailVerificationStatusChecker? checkVerificationStatus;
  final EmailVerificationEmailResender? resendVerificationEmail;
  final EmailVerificationAuthStateStream? authStateChanges;
  final Duration? autoCheckInterval;
  final Duration navigationDelay;

  @override
  ConsumerState<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState
    extends ConsumerState<EmailVerificationScreen> {
  bool _isChecking = false;
  bool _isResending = false;
  Timer? _autoCheckTimer;
  int _resendCountdown = 0;
  Timer? _countdownTimer;
  StreamSubscription<gotrue.AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();
    // Auto-check verification status every 3 seconds
    _startAutoCheck();
    // Listen for auth state changes (deep link verification)
    _listenToAuthChanges();
  }

  @override
  void dispose() {
    _autoCheckTimer?.cancel();
    _countdownTimer?.cancel();
    _authSubscription?.cancel();
    super.dispose();
  }

  void _listenToAuthChanges() {
    // Listen to Supabase auth state changes for deep link verification
    final authStateChanges =
        widget.authStateChanges ??
        () => Supabase.instance.client.auth.onAuthStateChange;
    _authSubscription = authStateChanges().listen((data) {
      if (data.event == AuthChangeEvent.signedIn && data.session != null) {
        final user = data.session!.user;
        // Check if email is verified
        if (user.emailConfirmedAt != null) {
          debugPrint('Email verified via deep link!');
          // Deep link handler will handle navigation, so we just cancel timers
          _autoCheckTimer?.cancel();
          _countdownTimer?.cancel();
        }
      }
    });
  }

  void _startAutoCheck() {
    final autoCheckInterval = widget.autoCheckInterval;
    if (autoCheckInterval == null) return;

    // Auto-check verification status every 5 seconds
    _autoCheckTimer = Timer.periodic(autoCheckInterval, (timer) {
      _checkVerification(silent: true);
    });
  }

  Future<void> _checkVerification({bool silent = false}) async {
    if (!silent) {
      setState(() => _isChecking = true);
    }

    try {
      // Refresh session to get latest user data
      final checkStatus =
          widget.checkVerificationStatus ??
          () async {
            final response = await Supabase.instance.client.auth
                .refreshSession();
            return response.user?.emailConfirmedAt != null;
          };
      final isVerified = await checkStatus();

      if (mounted) {
        if (!silent) {
          setState(() => _isChecking = false);
        }

        if (isVerified) {
          // Email verified! Navigate to survey
          _onVerificationSuccess();
        } else if (!silent) {
          // Only show message when manually checking
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Email not verified yet. Please check your inbox.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted && !silent) {
        setState(() => _isChecking = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error checking verification: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _onVerificationSuccess() {
    _autoCheckTimer?.cancel();

    // Get user data passed from signup
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Email verified successfully!'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );

    // Navigate to age gate to choose onboarding flow
    Future.delayed(widget.navigationDelay, () {
      if (mounted) {
        Navigator.pushReplacementNamed(
          context,
          '/age-gate',
          arguments: {'userId': args?['userId']},
        );
      }
    });
  }

  Future<void> _resendVerificationEmail() async {
    if (_resendCountdown > 0) return;

    setState(() => _isResending = true);

    try {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      final email = args?['email'] as String?;

      if (email == null || email.trim().isEmpty) {
        throw StateError('Missing email address for verification resend.');
      }

      final resendEmail =
          widget.resendVerificationEmail ??
          (String email) => Supabase.instance.client.auth.resend(
            type: OtpType.signup,
            email: email,
          );
      await resendEmail(email);

      if (mounted) {
        setState(() {
          _isResending = false;
          _resendCountdown = 60; // 60 second cooldown
        });

        // Start countdown
        _countdownTimer?.cancel();
        _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (_resendCountdown > 0) {
            setState(() => _resendCountdown--);
          } else {
            timer.cancel();
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📧 Verification email sent!'),
            backgroundColor: AppTheme.primaryBlue,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isResending = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending email: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final email = args?['email'] as String? ?? 'your email';

    return Scaffold(
      backgroundColor: const Color(0xFFF2F7FF),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // Logo
              Center(
                child: SvgPicture.asset(
                  'assets/flowfit_logo_header.svg',
                  height: 32,
                ),
              ),

              const SizedBox(height: 40),

              // Email Icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  SolarIconsBold.letter,
                  size: 60,
                  color: AppTheme.primaryBlue,
                ),
              ),

              const SizedBox(height: 32),

              // Title
              Text(
                'Verify Your Email',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryBlue,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              // Description
              Text(
                'We sent a verification link to',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: AppTheme.text),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),

              // Email
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  email,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryBlue,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 24),

              // Instructions
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          SolarIconsBold.infoCircle,
                          color: AppTheme.primaryBlue,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Next Steps:',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.text,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildStep('1', 'Check your email inbox'),
                    const SizedBox(height: 12),
                    _buildStep('2', 'Click the verification link'),
                    const SizedBox(height: 12),
                    _buildStep('3', 'Return here to continue'),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Check Status Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _isChecking ? null : () => _checkVerification(),
                  icon: _isChecking
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Icon(SolarIconsBold.checkCircle),
                  label: Text(
                    _isChecking ? 'Checking...' : 'I\'ve Verified My Email',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Resend Email
              TextButton.icon(
                onPressed: _isResending || _resendCountdown > 0
                    ? null
                    : _resendVerificationEmail,
                icon: _isResending
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppTheme.primaryBlue,
                          ),
                        ),
                      )
                    : const Icon(SolarIconsOutline.refresh),
                label: Text(
                  _resendCountdown > 0
                      ? 'Resend in ${_resendCountdown}s'
                      : _isResending
                      ? 'Sending...'
                      : 'Resend Verification Email',
                  style: TextStyle(
                    fontSize: 14,
                    color: _resendCountdown > 0
                        ? Colors.grey
                        : AppTheme.primaryBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Help Text
              Text(
                'Didn\'t receive the email? Check your spam folder',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep(String number, String text) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: AppTheme.primaryBlue.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryBlue,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 14, color: Colors.grey[800]),
          ),
        ),
      ],
    );
  }
}
