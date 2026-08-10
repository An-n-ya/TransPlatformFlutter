import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/models/user.dart';
import 'user_header.dart';
import 'user_tabs.dart';

/// User detail/profile page.
///
/// Displays cover image, avatar, user info, tabs (posts/liked/saved),
/// and a content feed.
class UserDetailPage extends StatelessWidget {
  final User user;
  final bool isMe;

  const UserDetailPage({super.key, required this.user, this.isMe = false});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        body: LayoutBuilder(
          builder: (context, constraints) {
            // Adapt the expanded header height to the available screen space.
            final maxHeader =
                constraints.maxHeight - kToolbarHeight - kTextTabBarHeight - 120;
            final expandedHeight =
                math.min(382.0, math.max(260.0, maxHeader));

            return NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                SliverOverlapAbsorber(
                  handle:
                      NestedScrollView.sliverOverlapAbsorberHandleFor(context),
                  sliver: SliverAppBar(
                    expandedHeight: expandedHeight,
                    collapsedHeight: kToolbarHeight,
                    floating: false,
                    pinned: true,
                    backgroundColor: cs.surface,
                    flexibleSpace: FlexibleSpaceBar(
                      background: UserHeaderSection(user: user, isMe: isMe),
                    ),
                  ),
                ),
                // ── Sticky TabBar ──
                SliverPersistentHeader(
                  pinned: true,
                  delegate: UserTabBarDelegate(cs: cs),
                ),
              ],
              body: TabBarView(
                children: [
                  UserPostsTab(
                    userId: user.id,
                    pinnedPostId: user.pinnedPostId,
                    isMe: isMe,
                  ),
                  UserLikedPostsTab(isMe: isMe),
                  UserCollectedPostsTab(isMe: isMe),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
