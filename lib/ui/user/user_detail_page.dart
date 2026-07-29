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
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            // ── Cover & user info header ──
            SliverOverlapAbsorber(
              handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
              sliver: SliverAppBar(
                expandedHeight: 352,
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
              UserPostsTab(userId: user.id, isMe: isMe),
              _buildPlaceholder(context),
              _buildPlaceholder(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      color: cs.surfaceDim,
      child: const SafeArea(
        top: false,
        child: Center(child: Text('Coming soon')),
      ),
    );
  }
}
