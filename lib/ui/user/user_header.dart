import 'package:easy_image_viewer/easy_image_viewer.dart';
import 'package:flutter/material.dart';
import 'package:trans_platform/ui/user/follow_info_page.dart';

import '../../domain/models/user.dart';
import 'user_buttons.dart';

/// Cover image, avatar overlay, user info, and action buttons.
class UserHeaderSection extends StatelessWidget {
  final User user;
  final bool isMe;

  const UserHeaderSection({super.key, required this.user, this.isMe = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // ── Cover image ──
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SizedBox(
            height: 236,
            child: Stack(
              children: [
                UserCoverImage(coverUrl: user.bioHeaderImg),
                Positioned(
                  top: 25,
                  right: 10,
                  child: RoundIconButton(
                    icon: Icons.more_vert,
                    onPressed: () {},
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Follow / Edit profile button ──
        Positioned(
          top: 236,
          right: 10,
          child: isMe
              ? UserEditProfileButton(user: user)
              : UserFollowButton(targetUser: user),
        ),

        // ── Avatar ──
        Positioned(top: 196, left: 24, child: UserAvatar(user: user)),

        // ── User info ──
        Positioned(
          top: 280,
          left: 24,
          right: 24,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.nickname,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '@${user.username}',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: cs.secondary,
                ),
              ),
              if (user.bio != null && user.bio!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  user.bio!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: cs.onSurface,
                    letterSpacing: 0.25,
                  ),
                ),
              ],

              if (user.followeesCount != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    _StatButton(
                      count: user.followeesCount ?? 0,
                      label: '关注',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => FollowInfoPage(
                            userId: user.id,
                            isFollowerPage: false,
                          ),
                        ),
                      ),
                    ),
                    _StatButton(
                      count: user.followersCount ?? 0,
                      label: '粉丝',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => FollowInfoPage(
                            userId: user.id,
                            isFollowerPage: true,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Stat button with bold count + label (e.g. "128 关注", "42 粉丝").
class _StatButton extends StatelessWidget {
  final int count;
  final String label;
  final VoidCallback onTap;

  const _StatButton({
    required this.count,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return TextButton(
      style: TextButton.styleFrom(
        foregroundColor: cs.secondary,
        padding: const EdgeInsets.fromLTRB(0, 8, 16, 8),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
      onPressed: onTap,
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$count ',
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
            ),
            TextSpan(text: label),
          ],
        ),
      ),
    );
  }
}

/// Cover image — loads from [bioHeaderImg] URL, falls back to local asset.
class UserCoverImage extends StatelessWidget {
  final String? coverUrl;

  const UserCoverImage({super.key, this.coverUrl});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (coverUrl != null && coverUrl!.isNotEmpty) {
      if (coverUrl!.startsWith('http')) {
        return SizedBox(
          height: 236,
          child: Image.network(
            coverUrl!,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => _fallbackCover(cs),
            loadingBuilder: (_, child, progress) =>
                progress == null ? child : _fallbackCover(cs),
          ),
        );
      }
      return SizedBox(
        height: 236,
        child: Image.asset(
          coverUrl!,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _fallbackCover(cs),
        ),
      );
    }

    return _fallbackCover(cs);
  }

  Widget _fallbackCover(ColorScheme cs) {
    return Container(
      height: 236,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        image: const DecorationImage(
          image: AssetImage('assets/images/image.png'),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

/// User avatar — loads from [user.avatar] URL, falls back to initial letter.
class UserAvatar extends StatelessWidget {
  final User user;

  const UserAvatar({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final avatarUrl = user.avatar;
    ImageProvider? image;
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      image = avatarUrl.startsWith('http')
          ? NetworkImage(avatarUrl)
          : AssetImage(avatarUrl) as ImageProvider;
    }

    return GestureDetector(
      onTap: () {
        if (image != null) {
          showImageViewer(
            context,
            image,
            swipeDismissible: true,
            doubleTapZoomable: true,
          );
        }
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(40),
          border: Border.all(color: const Color(0x22CAC4D0)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A000000),
              offset: Offset(0, 1),
              blurRadius: 3,
            ),
            BoxShadow(
              color: Color(0x1A000000),
              offset: Offset(0, 1),
              blurRadius: 2,
              spreadRadius: -1,
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: CircleAvatar(
          radius: 40,
          backgroundColor: cs.primaryContainer,
          backgroundImage: image,
          child: image == null
              ? Text(
                  user.nickname.isNotEmpty
                      ? user.nickname[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    color: cs.onPrimaryContainer,
                    fontSize: 22,
                    fontWeight: FontWeight.w500,
                  ),
                )
              : null,
        ),
      ),
    );
  }
}
