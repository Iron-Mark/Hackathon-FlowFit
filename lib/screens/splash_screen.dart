import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../presentation/providers/providers.dart';
import '../domain/entities/auth_state.dart';

typedef SplashRouteResolver = Future<SplashRoute> Function(WidgetRef ref);

class SplashRoute {
  const SplashRoute(this.name, {this.arguments});

  final String name;
  final Object? arguments;
}

/// Splash screen shown while checking authentication state.
///
/// Requirements: 5.1 - Check auth state on app start
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({
    super.key,
    this.resolveRoute,
    this.minimumDisplayDuration = const Duration(seconds: 3),
  });

  final SplashRouteResolver? resolveRoute;
  final Duration minimumDisplayDuration;

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  bool _isRetrying = false;
  String? _startupError;

  @override
  void initState() {
    super.initState();

    // Setup animations
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
      ),
    );

    // Start animation
    _animationController.forward();

    _checkAuthState();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkAuthState() async {
    // Wait for animation and minimum splash time
    await Future.delayed(widget.minimumDisplayDuration);

    if (!mounted) return;

    setState(() {
      _isRetrying = true;
      _startupError = null;
    });

    try {
      final resolveRoute = widget.resolveRoute ?? _resolveDefaultRoute;
      final route = await resolveRoute(ref);

      if (!mounted) return;
      Navigator.pushReplacementNamed(
        context,
        route.name,
        arguments: route.arguments,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isRetrying = false;
        _startupError =
            'Could not check your account setup. Check your connection and try again.';
      });
    }
  }

  Future<SplashRoute> _resolveDefaultRoute(WidgetRef ref) async {
    final authNotifier = ref.read(authNotifierProvider.notifier);
    await authNotifier.initialize();

    final updatedAuthState = ref.read(authNotifierProvider);
    final user = updatedAuthState.user;

    if (updatedAuthState.status != AuthStatus.authenticated || user == null) {
      return const SplashRoute('/welcome');
    }

    final hasCompletedSurvey = await ref
        .read(profileRepositoryProvider)
        .hasCompletedSurvey(user.id);

    if (hasCompletedSurvey) {
      return const SplashRoute('/dashboard');
    }

    return SplashRoute('/age-gate', arguments: {'userId': user.id});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F7FF), // Light blue background
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // Animated Logo
              AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: child,
                    ),
                  );
                },
                child: SvgPicture.asset(
                  'assets/flowfit_logo.svg',
                  width: 120,
                  height: 120,
                ),
              ),

              const Spacer(),

              // App Name at the bottom
              FadeTransition(
                opacity: _fadeAnimation,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 48.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'FlowFit',
                        style: Theme.of(context).textTheme.displayMedium
                            ?.copyWith(
                              color: const Color(0xFF3183E8), // Brand Blue
                              fontWeight: FontWeight.bold,
                              fontFamily: 'GeneralSans',
                              letterSpacing: 0,
                            ),
                      ),
                      if (_startupError != null) ...[
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            _startupError!,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: Colors.red[700]),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _isRetrying ? null : _checkAuthState,
                          child: const Text('Try Again'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
