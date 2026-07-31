import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/user/user_repository.dart';
import '../../data/services/current_user_provider.dart';
import '../../domain/models/user.dart';
import '../../utils/result.dart';
import '../settings/profile_page.dart';

/// Follow / Unfollow button — checks follow status on init.
class UserFollowButton extends StatefulWidget {
  final User targetUser;

  const UserFollowButton({super.key, required this.targetUser});

  @override
  State<UserFollowButton> createState() => _UserFollowButtonState();
}

class _UserFollowButtonState extends State<UserFollowButton> {
  bool? _isFollowing;
  bool? _isMe;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _checkFollowStatus();
  }

  Future<void> _checkFollowStatus() async {
    final provider = context.read<CurrentUserProvider>();
    final userId = provider.userId;
    if (userId == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    // Lazily load the follow list once and cache it globally
    if (provider.followeeIds.isEmpty) {
      final result =
          await context.read<UserRepository>().getFollowees(userId);
      if (!mounted) return;
      switch (result) {
        case Ok<List<User>>(:final value):
          provider.setFolloweeIds(value.map((u) => u.id));
        case Error<List<User>>():
          if (mounted) setState(() => _loading = false);
          return;
      }
    }

    if (mounted) {
      setState(() {
        _isFollowing = provider.isFollowing(widget.targetUser.id);
        _isMe = userId == widget.targetUser.id;
        _loading = false;
      });
    }
  }

  Future<void> _toggleFollow() async {
    final repo = context.read<UserRepository>();
    final provider = context.read<CurrentUserProvider>();
    final result = _isFollowing == true
        ? await repo.unfollow(widget.targetUser.id)
        : await repo.follow(widget.targetUser.id);

    if (!mounted) return;
    switch (result) {
      case Ok<void>():{
        setState(() => _isFollowing = !(_isFollowing ?? false));
        if (_isFollowing == true) {
          provider.addFollowee(widget.targetUser.id);
        } else {
          provider.removeFollowee(widget.targetUser.id);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isFollowing == true ? '已关注' : '已取消关注')),
        );
      }
      case Error<void>():{
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('操作失败')),
        );
      }
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

    if (_loading) {
      return FilledButton.icon(
        style: style,
        onPressed: null,
        icon: SizedBox(
          width: 16, height: 16,
          child: CircularProgressIndicator(strokeWidth: 2, color: cs.onPrimary),
        ),
        label: const SizedBox.shrink(),
      );
    }
    
    if (_isMe == true) return const SizedBox.shrink();

    return FilledButton.icon(
      style: _isFollowing == true ? unfollowStyle : style,
      onPressed: _toggleFollow,
      icon: Icon(
        _isFollowing == true ? Icons.person_remove : Icons.person_add_alt,
        size: 18,
      ),
      label: Text(_isFollowing == true ? '取关' : '关注'),
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
