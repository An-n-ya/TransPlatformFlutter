import 'package:flutter/material.dart';

/// Reusable search input matching the app's design language:
/// a rounded (14px) container with a subtle fill, a search prefix icon
/// and a clear suffix button that appears while the text is non-empty.
///
/// Typing and clearing both propagate through [onChanged]; pressing the
/// keyboard's search action propagates through [onSubmitted].
class SearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final double height;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  const SearchField({
    super.key,
    required this.controller,
    required this.hintText,
    this.height = 44,
    this.focusNode,
    this.onChanged,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        textInputAction: TextInputAction.search,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(fontSize: 14, color: cs.outline),
          prefixIcon: Icon(Icons.search, size: 18, color: cs.onSurfaceVariant),
          suffixIcon: ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (_, value, _) => value.text.isEmpty
                ? const SizedBox.shrink()
                : IconButton(
                    icon: const Icon(Icons.close, size: 16),
                    onPressed: () {
                      controller.clear();
                      onChanged?.call('');
                    },
                  ),
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}
