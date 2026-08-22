import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/cache/user_cache.dart';
import '../../domain/models/user.dart';
import '../../providers/repository_providers.dart';
import '../../utils/result.dart';
import 'user_buttons.dart';
import 'user_header.dart';
import 'user_tabs.dart';

/// User detail/profile page.
///
/// Displays cover image, avatar, user info, tabs (posts/liked/saved),
/// and a content feed.
///
/// The profile is served from the SSOT user cache; on every entry the page
/// re-fetches the profile from the server so freshly edited data (nickname,
/// avatar, bio, …) is never stale, and upserts it back into the cache.
class UserDetailPage extends ConsumerStatefulWidget {
  final User user;
  final bool isMe;

  const UserDetailPage({super.key, required this.user, this.isMe = false});

  @override
  ConsumerState<UserDetailPage> createState() => _UserDetailPageState();
}

class _UserDetailPageState extends ConsumerState<UserDetailPage> {
  @override
  void initState() {
    super.initState();
    // Always re-fetch the full profile from the server on entry so the page
    // shows fresh data even if the user edited their profile in another flow
    // (settings) since this page was last shown. Deferred so the cache is not
    // touched while the widget tree is building; on error keep the cached /
    // passed-in profile.
    Future(() async {
      if (!mounted) return;
      final result =
          await ref.read(userRepositoryProvider).getUser(widget.user.id);
      if (!mounted) return;
      switch (result) {
        case Ok<User>(:final value):
          ref.read(userCacheProvider.notifier).upsert(value);
        case Error<User>():
          break; // keep showing the cached / passed-in profile
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // SSOT: prefer the cached entity so fresh profile data propagates.
    final user =
        ref.watch(userCacheProvider).getById(widget.user.id) ?? widget.user;
    final cs = Theme.of(context).colorScheme;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        body: LayoutBuilder(
          builder: (context, constraints) {
            // Adapt the expanded header height to the available screen space.
            final maxHeader =
                constraints.maxHeight -
                kToolbarHeight -
                kTextTabBarHeight -
                120;
            final expandedHeight = math.min(382.0, math.max(260.0, maxHeader));

            return NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                SliverOverlapAbsorber(
                  handle: NestedScrollView.sliverOverlapAbsorberHandleFor(
                    context,
                  ),
                  sliver: SliverAppBar(
                    expandedHeight: expandedHeight,
                    collapsedHeight: kToolbarHeight,
                    floating: false,
                    pinned: true,
                    backgroundColor: cs.surface,
                    actions: [
                      Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: UserIconMoreButton(targetUser: user),
                      ),
                    ],
                    flexibleSpace: FlexibleSpaceBar(
                      background: UserHeaderSection(
                        user: user,
                        isMe: widget.isMe,
                      ),
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
                  ),
                  const UserLikedPostsTab(),
                  const UserCollectedPostsTab(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
