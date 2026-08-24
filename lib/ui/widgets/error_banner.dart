import 'package:flutter/material.dart';

import '../../theme/app_text_styles.dart';

/// Inline error message shown below a form field.
class ErrorBanner extends StatelessWidget {
  final String message;
  final EdgeInsetsGeometry padding;

  const ErrorBanner(
    this.message, {
    super.key,
    this.padding = const EdgeInsets.only(top: 4),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Text(
        message,
        style: AppTextStyles.error(context),
      ),
    );
  }
}