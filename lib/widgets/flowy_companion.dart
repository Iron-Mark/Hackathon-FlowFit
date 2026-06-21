import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Animated companion widget featuring Flowy
/// Provides engaging, beginner-friendly guidance through simple animations
class FlowyCompanion extends StatefulWidget {
  final String? message;
  final double size;
  final bool showMessage;

  const FlowyCompanion({
    super.key,
    this.message,
    this.size = 120,
    this.showMessage = true,
  });

  @override
  State<FlowyCompanion> createState() => _FlowyCompanionState();
}

class _FlowyCompanionState extends State<FlowyCompanion>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _floatingAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();

    // Create floating animation controller
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    // Floating up and down animation
    _floatingAnimation = Tween<double>(
      begin: -8.0,
      end: 8.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    // Subtle rotation animation for liveliness
    _rotationAnimation = Tween<double>(
      begin: -0.02,
      end: 0.02,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Animated Flowy SVG
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _floatingAnimation.value),
              child: Transform.rotate(
                angle: _rotationAnimation.value,
                child: child,
              ),
            );
          },
          child: SvgPicture.asset(
            'assets/flowy.svg',
            width: widget.size,
            height: widget.size,
            fit: BoxFit.contain,
          ),
        ),

        // Optional message bubble
        if (widget.showMessage && widget.message != null) ...[
          const SizedBox(height: 12),
          _buildMessageBubble(context),
        ],
      ],
    );
  }

  Widget _buildMessageBubble(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      constraints: const BoxConstraints(maxWidth: 280),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        widget.message!,
        textAlign: TextAlign.center,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

/// Small Flowy widget for inline usage
class FlowyMini extends StatelessWidget {
  final double size;

  const FlowyMini({super.key, this.size = 40});

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/flowy.svg',
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}
