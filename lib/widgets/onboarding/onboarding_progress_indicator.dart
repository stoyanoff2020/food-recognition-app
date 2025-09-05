import 'package:flutter/material.dart';
import '../../config/app_theme.dart';

class OnboardingProgressIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final double? progress;

  const OnboardingProgressIndicator({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveProgress = progress ?? (currentStep + 1) / totalSteps;

    return Column(
      children: [
        // Progress bar
        Container(
          height: 4,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusS),
            color: theme.colorScheme.surfaceContainerHighest,
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: effectiveProgress,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppTheme.radiusS),
                gradient: AppTheme.primaryGradient,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppTheme.spacingS),
        
        // Step indicators
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(totalSteps, (index) {
            final isActive = index == currentStep;
            final isCompleted = index < currentStep;
            
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacingXS),
              child: AnimatedContainer(
                duration: AppTheme.animationMedium,
                width: isActive ? 12 : 8,
                height: isActive ? 12 : 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompleted || isActive
                      ? theme.colorScheme.primary
                      : theme.colorScheme.surfaceContainerHighest,
                  border: isActive
                      ? Border.all(
                          color: theme.colorScheme.primary.withValues(alpha: 0.3),
                          width: 2,
                        )
                      : null,
                ),
              ),
            );
          }),
        ),
        
        const SizedBox(height: AppTheme.spacingS),
        
        // Step counter text
        Text(
          '${currentStep + 1} of $totalSteps',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}