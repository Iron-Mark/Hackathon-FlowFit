import 'package:flutter/material.dart';
import 'package:flowfit/theme/app_theme.dart';

class SurveyAppBar extends StatelessWidget implements PreferredSizeWidget {
  final int currentStep;
  final int totalSteps;
  final VoidCallback? onBack;
  final bool showProgressText;
  final String? title;

  const SurveyAppBar({
    super.key,
    required this.currentStep,
    this.totalSteps = 3,
    this.onBack,
    this.showProgressText = true,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: currentStep > 0
          ? IconButton(
              icon: const Icon(Icons.arrow_back, color: Color(0xFF314158)),
              onPressed: onBack ?? () => Navigator.pop(context),
            )
          : null,
      automaticallyImplyLeading: false,
      title: title != null
          ? Text(
              title!,
              style: const TextStyle(
                color: Color(0xFF314158),
                fontWeight: FontWeight.w600,
              ),
            )
          : null,
      actions: showProgressText
          ? [
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Center(
                  child: Text(
                    '$currentStep/$totalSteps',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ]
          : null,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class SurveyProgressIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const SurveyProgressIndicator({
    super.key,
    required this.currentStep,
    this.totalSteps = 3,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(totalSteps, (index) {
        final isCompleted = index < currentStep;
        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? AppTheme.primaryBlue
                        : Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              if (index < totalSteps - 1) const SizedBox(width: 8),
            ],
          ),
        );
      }),
    );
  }
}
