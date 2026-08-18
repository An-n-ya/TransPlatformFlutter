import 'package:flutter/material.dart';

/// A step progress indicator for the password reset flow.
///
/// Shows a series of dots/pills indicating which step the user is on.
/// [currentStep] is 0-indexed. Total steps is [totalSteps].
class StepProgressIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const StepProgressIndicator({
    super.key,
    required this.currentStep,
    this.totalSteps = 3,
  });

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF6750A4);
    const surfaceVariant = Color(0xFFE7E0EC);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalSteps, (index) {
        final isCurrent = index == currentStep;
        final isCompleted = index < currentStep;

        return Container(
          margin: EdgeInsets.only(right: index < totalSteps - 1 ? 4 : 0),
          width: isCurrent ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isCurrent || isCompleted ? primaryColor : surfaceVariant,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}