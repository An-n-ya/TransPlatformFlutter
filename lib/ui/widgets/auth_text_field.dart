import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';

/// Standard text field for the auth / onboarding flows.
///
/// Encapsulates the recurring 56px-tall, radius-4 outlined input with a leading
/// icon, focus/error border states and an optional loading-disabled state. All
/// colors resolve from the active [Theme].
class AuthTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscure;
  final bool enabled;
  final bool hasError;
  final TextInputAction? textInputAction;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final Widget? suffix;
  final int? maxLength;
  final bool hideCounter;

  const AuthTextField({
    super.key,
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.enabled = true,
    this.hasError = false,
    this.textInputAction,
    this.keyboardType,
    this.onChanged,
    this.onSubmitted,
    this.suffix,
    this.maxLength,
    this.hideCounter = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = hasError ? cs.error : cs.outline;

    return SizedBox(
      height: AppSpacing.inputHeight,
      child: TextField(
        controller: controller,
        obscureText: obscure,
        enabled: enabled,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        maxLength: maxLength,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        style: TextStyle(fontSize: 16, color: cs.onSurface),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(fontSize: 16, color: cs.onSurfaceVariant),
          prefixIcon: Icon(icon, size: 20, color: cs.onSurfaceVariant),
          suffixIcon: suffix,
          counterText: hideCounter ? '' : null,
          contentPadding: const EdgeInsets.symmetric(horizontal: 11),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
            borderSide: BorderSide(color: color),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
            borderSide: BorderSide(
              color: hasError ? cs.error : cs.primary,
              width: AppSpacing.borderFocused,
            ),
          ),
        ),
      ),
    );
  }
}