import 'package:flutter/material.dart';

/// Convenience text styles reused across pages.
///
/// Prefer `Theme.of(context).textTheme` when a semantic role exists; these
/// helpers cover the small set of fixed-size captions / labels that recur in
/// forms and error states.
abstract final class AppTextStyles {
  const AppTextStyles._();

  static TextStyle error(BuildContext context) => TextStyle(
        color: Theme.of(context).colorScheme.error,
        fontSize: 13,
      );

  static TextStyle hint(BuildContext context) =>
      TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant);

  static TextStyle buttonLabel = const TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );
}