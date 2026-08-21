import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart';
import 'package:trans_platform/ui/user/user_buttons.dart';

import '../../data/services/current_user_provider.dart';
import '../../domain/models/user.dart';

/// Small helper for like / comment / collect buttons.
class PostActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onPressed;

  const PostActionBtn({
    super.key,
    required this.icon,
    required this.label,
    this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return TextButton.icon(
      style: TextButton.styleFrom(
        foregroundColor: color ?? cs.onSurface,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
    );
  }
}


/// "More" menu for a post card: pin/unpin + delete, for own posts only.
///
/// Mirrors [UserIconMoreButton]: the entries are derived from state via
/// [MoreMenuButtonMixin] and the button hides itself when there is nothing
/// to show. Ownership is checked against [author] and the signed-in user, so
/// the menu can never drift from the actual author.
class PostMoreButton extends ConsumerStatefulWidget {
  final User author;
  final bool isPinned;
  final VoidCallback onDelete;
  final VoidCallback onTogglePin;

  const PostMoreButton({
    super.key,
    required this.author,
    required this.isPinned,
    required this.onDelete,
    required this.onTogglePin,
  });

  @override
  ConsumerState<PostMoreButton> createState() => _PostMoreButtonState();
}

class _PostMoreButtonState extends ConsumerState<PostMoreButton>
    with MoreMenuButtonMixin<PostMoreButton> {
  @override
  List<PopupMenuEntry<String>> buildMoreMenuItems(BuildContext context) {
    // Only the post author gets the menu.
    if (context.read<CurrentUserProvider>().userId != widget.author.id) {
      return const [];
    }
    return [
      PopupMenuItem(
        value: 'pin',
        child: Row(
          children: [
            Icon(
              widget.isPinned ? Icons.push_pin_outlined : Icons.push_pin,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(widget.isPinned ? '取消置顶' : '置顶'),
          ],
        ),
      ),
      const PopupMenuItem(
        value: 'delete',
        child: Row(
          children: [
            Icon(Icons.delete_outline, size: 20, color: Colors.red),
            SizedBox(width: 8),
            Text('删除', style: TextStyle(color: Colors.red)),
          ],
        ),
      ),
    ];
  }

  @override
  void onMoreMenuSelected(String value) {
    switch (value) {
      case 'delete':
        widget.onDelete();
      case 'pin':
        widget.onTogglePin();
    }
  }

  @override
  Widget build(BuildContext context) {
    return buildMoreMenuButton(context, icon: Icons.more_vert);
  }
}
