import 'package:flutter/material.dart';

import 'package:flowfit/screens/wear/wear_colors.dart';

/// Start/Stop button with WCAG-compliant touch target (48x48dp minimum)
/// Uses primaryBlue for Start button, errorRed for Stop button
/// Requirements: 4.1, 4.5
class WearStartButton extends StatelessWidget {
  const WearStartButton({
    super.key,
    required this.isMonitoring,
    required this.isBusy,
    required this.onPressed,
  });

  final bool isMonitoring;
  final bool isBusy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      height: 48, // WCAG 2.1 Level AA: minimum 48dp touch target
      child: ElevatedButton.icon(
        onPressed: isBusy ? null : onPressed,
        style:
            ElevatedButton.styleFrom(
              backgroundColor: isMonitoring
                  ? WearColors.errorRed
                  : WearColors.primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ).copyWith(
              // Apply darkBlue to pressed/active states (Requirements: 4.2)
              backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
                if (states.contains(WidgetState.pressed)) {
                  return isMonitoring
                      ? WearColors.errorRed.withValues(alpha: 0.8)
                      : WearColors.darkBlue;
                }
                return isMonitoring
                    ? WearColors.errorRed
                    : WearColors.primaryBlue;
              }),
            ),
        icon: isBusy
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Icon(isMonitoring ? Icons.pause : Icons.play_arrow, size: 20),
        label: Text(
          isBusy ? 'Wait' : (isMonitoring ? 'Stop' : 'Start'),
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

/// Send to phone button with WCAG-compliant touch target (48x48dp minimum)
/// Uses primaryBlue for enabled state, lightBlueGrey for disabled state
/// Requirements: 4.1, 4.2, 4.3
class WearSendButton extends StatelessWidget {
  const WearSendButton({
    super.key,
    required this.isSending,
    required this.onPressed,
  });

  final bool isSending;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      height: 48, // WCAG 2.1 Level AA: minimum 48dp touch target
      child: ElevatedButton.icon(
        onPressed: isSending ? null : onPressed,
        style:
            ElevatedButton.styleFrom(
              backgroundColor: WearColors.primaryBlue,
              foregroundColor: Colors.white,
              disabledBackgroundColor: WearColors.lightBlueGrey.withValues(
                alpha: 0.6,
              ), // Requirements: 4.3
              disabledForegroundColor: Colors.white.withValues(alpha: 0.6),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ).copyWith(
              // Apply darkBlue to pressed/active states (Requirements: 4.2)
              backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
                if (states.contains(WidgetState.disabled)) {
                  return WearColors.lightBlueGrey.withValues(alpha: 0.6);
                }
                if (states.contains(WidgetState.pressed)) {
                  return WearColors.darkBlue;
                }
                return WearColors.primaryBlue;
              }),
            ),
        icon: isSending
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.phone_android, size: 18),
        label: Text(
          isSending ? 'Sending' : 'Send',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

/// Error display widget with icon and descriptive text
/// Meets WCAG requirements: minimum 14sp font, sufficient contrast
/// Requirements: 5.5, 6.5 - Display error with retry option
class WearErrorDisplay extends StatelessWidget {
  const WearErrorDisplay({
    super.key,
    required this.errorMessage,
    required this.isSimulatedFallback,
    required this.onRetry,
  });

  final String? errorMessage;
  final bool isSimulatedFallback;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final showRetry = errorMessage?.contains('retry') ?? false;
    final accentColor = isSimulatedFallback
        ? WearColors.teal
        : WearColors.errorRed;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accentColor, width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSimulatedFallback ? Icons.science : Icons.error_outline,
                color: accentColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  errorMessage ?? 'An error occurred',
                  style: const TextStyle(
                    fontSize: 14, // Meets minimum 14sp requirement
                    color: Colors.white,
                  ),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (showRetry) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 36,
              child: ElevatedButton.icon(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: WearColors.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Retry', style: TextStyle(fontSize: 12)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
