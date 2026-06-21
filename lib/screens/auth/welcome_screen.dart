import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../presentation/providers/providers.dart';

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  bool _isRedirectingAuthenticatedUser = false;

  @override
  void initState() {
    super.initState();
    // Check if user is already authenticated
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _checkAuthState();
    });
  }

  Future<void> _checkAuthState() async {
    final authState = ref.read(authNotifierProvider);
    final user = authState.user;

    if (user != null && mounted) {
      await _navigateAfterAuthentication(user.id);
    }
  }

  Future<void> _navigateAfterAuthentication(String userId) async {
    if (_isRedirectingAuthenticatedUser) return;
    _isRedirectingAuthenticatedUser = true;

    try {
      final hasCompletedSurvey = await ref
          .read(profileRepositoryProvider)
          .hasCompletedSurvey(userId);

      if (!mounted) return;

      if (hasCompletedSurvey) {
        Navigator.of(context).pushReplacementNamed('/dashboard');
      } else {
        Navigator.of(
          context,
        ).pushReplacementNamed('/age-gate', arguments: {'userId': userId});
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not check onboarding status. Check your connection and try again.',
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      _isRedirectingAuthenticatedUser = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authNotifierProvider, (previous, next) async {
      final user = next.user;
      if (user != null) {
        await _navigateAfterAuthentication(user.id);
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF2F7FF),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),
            // Header Logo
            SvgPicture.asset('assets/flowfit_logo_header.svg', height: 32),

            const SizedBox(height: 20),

            // Hero Image
            Expanded(
              flex: 5,
              child: SizedBox(
                width: double.infinity,
                child: SvgPicture.asset(
                  'assets/images/onboarding_hero.svg',
                  fit: BoxFit.cover,
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  Text(
                    'Find Your Flow',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: AppTheme.primaryBlue,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Your journey to a healthier, happier you starts here. We’re all about gentle encouragement and celebrating every step.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.text,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/signup');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text('Get Started'),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Login Link
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  'Already have an account? ',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppTheme.text),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(context, '/login');
                  },
                  child: Text(
                    'Log In',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.primaryBlue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Footer
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.watch, size: 20, color: AppTheme.darkGray),
                const SizedBox(width: 8),
                Text(
                  'Compatible with Galaxy Watch',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.darkGray,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
