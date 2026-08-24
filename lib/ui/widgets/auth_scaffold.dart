import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';
import 'step_progress_indicator.dart';

/// Shared scaffold shell for the auth / onboarding flows.
///
/// Provides the standard light surface background, transparent app bar with an
/// optional back button and trailing action, an optional step indicator, and
/// the centered column layout (header / form fields, pushed apart by fillers,
/// followed by primary actions).
class AuthScaffold extends StatelessWidget {
  /// 0-based step index shown by [StepProgressIndicator]; hides it when null.
  final int? currentStep;
  final Widget header;
  final List<Widget> children;
  final List<Widget> actions;
  final bool backEnabled;
  final VoidCallback? onBack;
  final Widget? appBarAction;

  /// Extra vertical padding inserted above [header].
  final double topGap;

  const AuthScaffold({
    super.key,
    this.currentStep,
    required this.header,
    this.children = const [],
    this.actions = const [],
    this.backEnabled = true,
    this.onBack,
    this.appBarAction,
    this.topGap = 0,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: backEnabled ? BackButton(onPressed: onBack) : null,
        actions: [?appBarAction],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (currentStep != null) ...[
                      StepProgressIndicator(currentStep: currentStep!),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                    if (topGap > 0) SizedBox(height: topGap),
                    header,
                    const Spacer(),
                    ...children,
                    const Spacer(),
                    ...actions,
                    const SizedBox(height: AppSpacing.xxl),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}