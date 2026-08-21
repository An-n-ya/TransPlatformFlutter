import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart';

import '../../data/services/current_user_provider.dart';
import '../../domain/models/user.dart';
import '../../providers/follow_mutation_providers.dart';
import '../settings/profile_page.dart';

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

class _UserFollowButtonState extends ConsumerState<UserFollowButton> {
  @override
  void initState() {
    super.initState();
    // Kick off the one-time followee-list load so follow status is known.
    // Deferred so the cache/relations are not touched while building.
    final currentUserId = context.read<CurrentUserProvider>().userId;
    if (currentUserId != null) {
      Future(() {
        if (mounted) {
          ref
              .read(followRelationsProvider.notifier)
              .ensureLoaded(currentUserId);
        }
      });
    }
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

    final currentUserId = context.read<CurrentUserProvider>().userId;
    final isMe =
        currentUserId != null && currentUserId == widget.targetUser.id;
    if (isMe) return const SizedBox.shrink();

    final relations = ref.watch(followRelationsProvider);
    // While the followee list is still loading, show a spinner. When not
    // logged in there is nothing to resolve, so fall back to "not following".
    final showLoading = currentUserId != null && !relations.loaded;
    final isFollowing = currentUserId != null && relations.isFollowing(widget.targetUser.id);

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

    return FilledButton.icon(
      style: isFollowing ? unfollowStyle : style,
      onPressed: () => ref
          .read(followMutationProvider.notifier)
          .toggleFollow(widget.targetUser.id),
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
