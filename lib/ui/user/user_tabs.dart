import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/post/post_repository.dart';
import '../../domain/models/post.dart';
import '../../utils/result.dart';
import '../posts/post_card.dart';

/// Tab content: list of posts by this user.
class UserPostsTab extends StatefulWidget {
  final int userId;
  final int? pinnedPostId;
  final bool isMe;

  const UserPostsTab({super.key, required this.userId, this.pinnedPostId, this.isMe = false});

  @override
  State<UserPostsTab> createState() => _UserPostsTabState();
}

class _UserPostsTabState extends State<UserPostsTab> {
  late Future<Result<List<Post>>> _postsFuture;
  late Future<Result<Post>> _pinnedPostFuture;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  void _loadPosts() {
    _postsFuture = context.read<PostRepository>().getUserPosts(widget.userId);
    if (widget.pinnedPostId != null) {
      _pinnedPostFuture = context.read<PostRepository>().getPost(widget.pinnedPostId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.pinnedPostId == null) {
      return _buildPostsList(_postsFuture);
    }

    // Combine pinned post + regular posts list
    return FutureBuilder<Result<List<Post>>>(
      future: _postsFuture,
      builder: (_, postsSnapshot) {
        if (!postsSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final postsResult = postsSnapshot.data!;
        if (postsResult is Error<List<Post>>) {
          return _buildError(postsResult.error);
        }

        final posts = (postsResult as Ok<List<Post>>).value;

        return FutureBuilder<Result<Post>>(
          future: _pinnedPostFuture,
          builder: (_, pinnedSnapshot) {
            final pinned = switch (pinnedSnapshot.data) {
              Ok<Post>(:final value) => value.copyWith(isPinned: true),
              _ => null,
            };

            // Remove pinned post from list if already present, then prepend
            final combined = <Post>[
              if (pinned != null) pinned,
              ...posts.where((p) => p.id != pinned?.id),
            ];

            return _buildPostsList(Future.value(Result.ok(combined)));
          },
        );
      },
    );
  }

  Widget _buildPostsList(Future<Result<List<Post>>> future) {
    return FutureBuilder<Result<List<Post>>>(
      future: future,
      builder: (_, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        return switch (snapshot.data!) {
          Ok<List<Post>>(:final value) => value.isEmpty
              ? const Center(child: Text('暂无贴文'))
              : Padding(
                  // Cover the full pinned header height (collapsed toolbar + TabBar)
                  padding: EdgeInsets.only(top: kToolbarHeight + kTextTabBarHeight),
                  child: PostFeed(
                    posts: value,
                    isMe: widget.isMe,
                    onPostDeleted: () => setState(_loadPosts),
                    onRefresh: _refreshPosts,
                  ),
                ),
          Error<List<Post>>(:final error) => _buildError(error),
        };
      },
    );
  }

  Future<void> _refreshPosts() async {
    final future =
        context.read<PostRepository>().getUserPosts(widget.userId);
    setState(() {
      _postsFuture = future;
    });
    await future;
  }

  Widget _buildError(Exception error) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text('加载失败', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(error.toString(),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 16),
          FilledButton.tonal(
            onPressed: () => setState(_loadPosts),
            child: const Text('重试'),
          ),
        ],
      ),
    );
  }
}

/// Tab content: list of posts liked by current user.
class UserLikedPostsTab extends StatefulWidget {
  final bool isMe;
  const UserLikedPostsTab({super.key, this.isMe = false});
  @override
  State<UserLikedPostsTab> createState() => _UserLikedPostsTabState();
}

class _UserLikedPostsTabState extends State<UserLikedPostsTab> {
  late Future<Result<List<Post>>> _postsFuture;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  void _loadPosts() {
    _postsFuture = context.read<PostRepository>().getLikedPosts();
  }

  Future<void> _refreshPosts() async {
    final future = context.read<PostRepository>().getLikedPosts();
    setState(() {
      _postsFuture = future;
    });
    await future;
  }

  @override
  Widget build(BuildContext context) {
    return _PostListBody(
      future: _postsFuture,
      isMe: widget.isMe,
      onRefresh: _refreshPosts,
    );
  }
}

/// Tab content: list of posts collected by current user.
class UserCollectedPostsTab extends StatefulWidget {
  final bool isMe;
  const UserCollectedPostsTab({super.key, this.isMe = false});
  @override
  State<UserCollectedPostsTab> createState() => _UserCollectedPostsTabState();
}

class _UserCollectedPostsTabState extends State<UserCollectedPostsTab> {
  late Future<Result<List<Post>>> _postsFuture;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  void _loadPosts() {
    _postsFuture = context.read<PostRepository>().getCollectedPosts();
  }

  Future<void> _refreshPosts() async {
    final future = context.read<PostRepository>().getCollectedPosts();
    setState(() {
      _postsFuture = future;
    });
    await future;
  }

  @override
  Widget build(BuildContext context) {
    return _PostListBody(
      future: _postsFuture,
      isMe: widget.isMe,
      onRefresh: _refreshPosts,
    );
  }
}

/// Shared body for liked / collected post tabs.
class _PostListBody extends StatelessWidget {
  final Future<Result<List<Post>>> future;
  final bool isMe;
  final Future<void> Function() onRefresh;

  const _PostListBody({
    required this.future,
    required this.isMe,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Result<List<Post>>>(
      future: future,
      builder: (_, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        return switch (snapshot.data!) {
          Ok<List<Post>>(:final value) => value.isEmpty
              ? const Center(child: Text('暂无内容'))
              : Padding(
                  // Cover the full pinned header height (collapsed toolbar + TabBar)
                  padding: EdgeInsets.only(top: kToolbarHeight + kTextTabBarHeight),
                  child: PostFeed(
                      posts: value, isMe: isMe, onRefresh: onRefresh),
                ),
          Error<List<Post>>(:final error) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('加载失败',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(error.toString(),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 16),
                  FilledButton.tonal(
                    onPressed: onRefresh,
                    child: const Text('重试'),
                  ),
                ],
              ),
            ),
        };
      },
    );
  }
}


/// Sticky TabBar delegate for the pinned tab bar.
class UserTabBarDelegate extends SliverPersistentHeaderDelegate {
  final ColorScheme cs;

  UserTabBarDelegate({required this.cs});

  @override
  double get minExtent => kTextTabBarHeight;
  @override
  double get maxExtent => kTextTabBarHeight;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: cs.surface,
      child: TabBar(
        labelColor: cs.primary,
        unselectedLabelColor: cs.onSurfaceVariant,
        indicatorColor: cs.primary,
        indicatorWeight: 3,
        indicatorPadding: EdgeInsets.zero,
        tabs: const [
          Tab(text: '贴文'),
          Tab(text: '赞过'),
          Tab(text: '收藏'),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(UserTabBarDelegate oldDelegate) => false;
}
