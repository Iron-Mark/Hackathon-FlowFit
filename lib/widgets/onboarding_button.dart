import 'package:flutter/material.dart';

/// A consistent button widget for the Buddy onboarding flow.
///
/// Supports primary and secondary styles with proper accessibility
/// features including minimum touch targets and disabled states.
class OnboardingButton extends StatelessWidget {
  /// The button label text
  final String label;

  /// Callback when the button is pressed (null for disabled state)
  final VoidCallback? onPressed;

  /// Whether this is a primary button (true) or secondary button (false)
  final bool isPrimary;

  /// Optional custom color (overrides default primary/secondary colors)
  final Color? customColor;

  const OnboardingButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isPrimary = true,
    this.customColor,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null;

    // Define colors based on button type
    final Color buttonColor;
    if (customColor != null) {
      buttonColor = customColor!;
    } else if (isPrimary) {
      // Primary buttons use green (#4CAF50) or Primary Blue (#3B82F6)
      buttonColor = const Color(0xFF4CAF50); // Green for primary actions
    } else {
      // Secondary buttons use Primary Blue
      buttonColor = const Color(0xFF3B82F6);
    }

    if (isPrimary) {
      return Semantics(
        button: true,
        enabled: isEnabled,
        label: label,
        hint: isEnabled ? 'Double tap to activate' : 'Button is disabled',
        child: SizedBox(
          height: 56, // Minimum 48px for accessibility, using 56px for comfort
          child: ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: isEnabled ? buttonColor : Colors.grey.shade300,
              foregroundColor: isEnabled ? Colors.white : Colors.grey.shade500,
              disabledBackgroundColor: Colors.grey.shade300,
              disabledForegroundColor: Colors.grey.shade500,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              minimumSize: const Size(48, 56), // Ensure minimum touch target
            ),
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 0,
              ),
            ),
          ),
        ),
      );
    } else {
      // Secondary button (outlined style)
      return Semantics(
        button: true,
        enabled: isEnabled,
        label: label,
        hint: isEnabled ? 'Double tap to activate' : 'Button is disabled',
        child: SizedBox(
          height: 56,
          child: OutlinedButton(
            onPressed: onPressed,
            style: OutlinedButton.styleFrom(
              foregroundColor: isEnabled ? buttonColor : Colors.grey.shade400,
              side: BorderSide(
                color: isEnabled ? buttonColor : Colors.grey.shade300,
                width: 2,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              minimumSize: const Size(48, 56), // Ensure minimum touch target
            ),
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 0,
              ),
            ),
          ),
        ),
      );
    }
  }
}
