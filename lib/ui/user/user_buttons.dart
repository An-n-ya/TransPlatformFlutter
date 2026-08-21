import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart';

import '../../data/services/current_user_provider.dart';
import '../../domain/models/user.dart';
import '../../providers/follow_mutation_providers.dart';
import '../settings/profile_page.dart';

/// Shared follow-state logic for follow-aware widgets.
///
/// Both [UserFollowButton] and [UserIconMoreButton] read "am I following this
/// user" from the SSOT [FollowRelations], kick off the one-time followee-list
/// load, and toggle through the optimistic [FollowMutation]. Keeping this in
/// one place guarantees the two widgets can never drift apart on follow
/// semantics.
mixin FollowStateMixin<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  /// ID of the user whose follow state this widget reflects.
  late final int targetUserId;

  int? get _currentUserId => context.read<CurrentUserProvider>().userId;

  /// Whether this widget represents the signed-in user themselves.
  bool get isMe => _currentUserId != null && _currentUserId == targetUserId;

  /// True while the followee list is still loading and we're logged in.
  bool get showLoading {
    final id = _currentUserId;
    return id != null && !ref.watch(followRelationsProvider).loaded;
  }

  /// Whether the current user follows [targetUserId].
  bool get isFollowing {
    final id = _currentUserId;
    return id != null &&
        ref.watch(followRelationsProvider).isFollowing(targetUserId);
  }

  /// Kick off the one-time followee-list load so follow status is known.
  /// Deferred so the cache/relations are not touched while building.
  void ensureFolloweesLoaded() {
    final id = _currentUserId;
    if (id == null) return;
    Future(() {
      if (mounted) {
        ref.read(followRelationsProvider.notifier).ensureLoaded(id);
      }
    });
  }

  /// Optimistically toggle the follow relationship (rolls back on failure).
  void toggleFollow() {
    ref.read(followMutationProvider.notifier).toggleFollow(targetUserId);
  }
}

/// Shared shell for "more" icon buttons with a conditional dropdown.
///
/// [UserIconMoreButton] and [PostMoreButton] both render a "more" icon
/// [PopupMenuButton] whose entries depend on state, hide themselves when the
/// menu would be empty, and dispatch selections through a single callback.
/// This mixin centralizes the "build entries → hide if empty → dispatch"
/// pattern so the two widgets can never drift apart.
mixin MoreMenuButtonMixin<T extends StatefulWidget> on State<T> {
  /// Menu entries shown when the button is tapped, ordered top-to-bottom.
  /// Return an empty list to hide the button entirely.
  List<PopupMenuEntry<String>> buildMoreMenuItems(BuildContext context);

  /// Called with the [PopupMenuItem.value] of the selected entry.
  void onMoreMenuSelected(String value);

  /// The "more" icon button, or [SizedBox.shrink] when there are no entries.
  Widget buildMoreMenuButton(
    BuildContext context, {
    IconData icon = Icons.more_horiz,
  }) {
    final items = buildMoreMenuItems(context);
    if (items.isEmpty) return const SizedBox.shrink();
    return PopupMenuButton<String>(
      icon: Icon(icon, size: 20),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      onSelected: onMoreMenuSelected,
      itemBuilder: (_) => items,
    );
  }
}

/// Follow / Unfollow button.
///
/// Follow state is read from the SSOT [FollowRelations]; toggling goes through
/// [FollowMutation] which applies the change optimistically and rolls back on
/// failure.
class UserFollowButton extends ConsumerStatefulWidget {
  final User targetUser;

  const UserFollowButton({super.key, required this.targetUser});

  @override
  ConsumerState<UserFollowButton> createState() => _UserFollowButtonState();
}

class _UserFollowButtonState extends ConsumerState<UserFollowButton>
    with FollowStateMixin<UserFollowButton> {
  @override
  void initState() {
    super.initState();
    targetUserId = widget.targetUser.id;
    ensureFolloweesLoaded();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final style = FilledButton.styleFrom(
      backgroundColor: cs.primary,
      foregroundColor: cs.onPrimary,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
    );
    final unfollowStyle = FilledButton.styleFrom(
      backgroundColor: cs.secondary,
      foregroundColor: cs.onSecondary,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
    );

    if (isMe) return const SizedBox.shrink();

    // While the followee list is still loading, show a spinner. When not
    // logged in there is nothing to resolve, so fall back to "not following".
    if (showLoading) {
      return FilledButton.icon(
        style: style,
        onPressed: null,
        icon: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2, color: cs.onPrimary),
        ),
        label: const SizedBox.shrink(),
      );
    }
    
    if (isFollowing) return SizedBox.shrink();

    return FilledButton.icon(
      style: isFollowing ? unfollowStyle : style,
      onPressed: toggleFollow,
      icon: Icon(
        isFollowing ? Icons.person_remove : Icons.person_add_alt,
        size: 18,
      ),
      label: Text(isFollowing ? '取关' : '关注'),
    );
  }
}

/// Edit profile button — shown when viewing own profile.
class UserEditProfileButton extends StatelessWidget {
  final User user;

  const UserEditProfileButton({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return FilledButton.icon(
      style: FilledButton.styleFrom(
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
      ),
      onPressed: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ProfilePage(existingUser: user)),
      ),
      icon: const Icon(Icons.edit, size: 18),
      label: const Text('编辑资料'),
    );
  }
}

/// Round "more" icon button with a dropdown menu.
///
/// Menu content is derived from the shared follow state:
/// - Own profile → offers "编辑资料", which opens [ProfilePage].
/// - Following [targetUser] → offers "取消关注".
/// When the menu would have no items (logged out, or neither case applies)
/// the widget hides itself so an empty dropdown is never shown.
class UserIconMoreButton extends ConsumerStatefulWidget {
  final User targetUser;

  const UserIconMoreButton({super.key, required this.targetUser});

  @override
  ConsumerState<UserIconMoreButton> createState() =>
      _UserIconMoreButtonState();
}

class _UserIconMoreButtonState extends ConsumerState<UserIconMoreButton>
    with FollowStateMixin<UserIconMoreButton>,
        MoreMenuButtonMixin<UserIconMoreButton> {
  @override
  void initState() {
    super.initState();
    targetUserId = widget.targetUser.id;
    ensureFolloweesLoaded();
  }

  @override
  List<PopupMenuEntry<String>> buildMoreMenuItems(BuildContext context) {
    // Own profile → edit-profile item; otherwise an unfollow item while
    // following. With no applicable item the mixin hides the button.
    if (isMe) {
      return const [
        PopupMenuItem(
          value: 'editProfile',
          child: Row(
            children: [
              Icon(Icons.edit, size: 20),
              SizedBox(width: 8),
              Text('编辑资料'),
            ],
          ),
        ),
      ];
    }
    if (isFollowing) {
      return const [
        PopupMenuItem(
          value: 'unfollow',
          child: Row(
            children: [
              Icon(Icons.person_remove, size: 20, color: Colors.red),
              SizedBox(width: 8),
              Text('取消关注', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ];
    }
    return const [];
  }

  @override
  void onMoreMenuSelected(String value) {
    switch (value) {
      case 'editProfile':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ProfilePage(existingUser: widget.targetUser),
          ),
        );
      case 'unfollow':
        toggleFollow();
    }
  }

  @override
  Widget build(BuildContext context) {
    return buildMoreMenuButton(context);
  }
}

/// Small round icon button used in the cover area.
class RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const RoundIconButton({super.key, required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(100),
      ),
      child: IconButton(
        icon: Icon(icon),
        onPressed: onPressed,
        color: Colors.black,
        iconSize: 20,
      ),
    );
  }
}
