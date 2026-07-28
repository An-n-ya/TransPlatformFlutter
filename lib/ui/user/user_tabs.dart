import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/post/post_repository.dart';
import '../../domain/models/post.dart';
import '../../utils/result.dart';
import '../posts/post_card.dart';

/// Tab content: list of posts by this user.
class UserPostsTab extends StatefulWidget {
  final int userId;

  const UserPostsTab({super.key, required this.userId});

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
                  child: PostFeed(posts: value),
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
