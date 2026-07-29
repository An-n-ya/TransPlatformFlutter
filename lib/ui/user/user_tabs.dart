import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/post/post_repository.dart';
import '../../domain/models/post.dart';
import '../../utils/result.dart';
import '../posts/post_card.dart';

/// Tab content: list of posts by this user.
class UserPostsTab extends StatefulWidget {
  final int userId;
  final bool isMe;

  const UserPostsTab({super.key, required this.userId, this.isMe = false});

  @override
  State<UserPostsTab> createState() => _UserPostsTabState();
}

class _UserPostsTabState extends State<UserPostsTab> {
  late Future<Result<List<Post>>> _postsFuture;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  void _loadPosts() {
    _postsFuture = context.read<PostRepository>().getUserPosts(widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Result<List<Post>>>(
      future: _postsFuture,
      builder: (_, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        return switch (snapshot.data!) {
          Ok<List<Post>>(:final value) => value.isEmpty
              ? const Center(child: Text('暂无贴文'))
              : Padding(
                  padding: const EdgeInsets.only(top: 80),
                  child: PostFeed(
                    posts: value,
                    isMe: widget.isMe,
                    onPostDeleted: () => setState(_loadPosts),
                  ),
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
                    onPressed: () => setState(_loadPosts),
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

  @override
  Widget build(BuildContext context) {
    return _PostListBody(
      future: _postsFuture,
      isMe: widget.isMe,
      onRefresh: () => setState(_loadPosts),
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

  @override
  Widget build(BuildContext context) {
    return _PostListBody(
      future: _postsFuture,
      isMe: widget.isMe,
      onRefresh: () => setState(_loadPosts),
    );
  }
}

/// Shared body for liked / collected post tabs.
class _PostListBody extends StatelessWidget {
  final Future<Result<List<Post>>> future;
  final bool isMe;
  final VoidCallback onRefresh;

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
                  padding: const EdgeInsets.only(top: 80),
                  child: PostFeed(posts: value, isMe: isMe),
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
  double get minExtent => 48;
  @override
  double get maxExtent => 48;

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
