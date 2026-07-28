import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/post/post_repository.dart';
import '../../domain/models/post.dart';
import '../../utils/result.dart';
import 'photo_grid.dart';

/// Page that shows a scrollable feed of [Post] cards.
///
/// Loads data from [PostRepository] (injected via Provider).
/// To switch data source, change the entry point:
/// - lib/main_local.dart  → hardcoded sample data
/// - lib/main_remote.dart → real backend API at localhost:8081
class Moments extends StatefulWidget {
  const Moments({super.key});

  @override
  State<Moments> createState() => _MomentsState();
}

class _MomentsState extends State<Moments> {
  late Future<Result<List<Post>>> _feedFuture;

  @override
  void initState() {
    super.initState();
    _feedFuture = context.read<PostRepository>().getFeed();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Result<List<Post>>>(
      future: _feedFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final result = snapshot.data!;
        switch (result) {
          case Ok<List<Post>>():
            final posts = result.value;
            if (posts.isEmpty) {
              return const Center(child: Text('暂无内容'));
            }
            return _PostFeed(posts: posts);
          case Error<List<Post>>():
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('加载失败', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      result.error.toString(),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.tonal(
                    onPressed: () {
                      setState(() {
                        _feedFuture =
                            context.read<PostRepository>().getFeed();
                      });
                    },
                    child: const Text('重试'),
                  ),
                ],
              ),
            );
        }
      },
    );
  }
}

class _PostFeed extends StatelessWidget {
  final List<Post> posts;

  const _PostFeed({required this.posts});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: posts.length,
      itemBuilder: (context, index) => _PostCard(post: posts[index]),
    );
  }
}

class _PostCard extends StatelessWidget {
  final Post post;

  const _PostCard({required this.post});

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes} 分钟前';
    if (diff.inHours < 24) return '${diff.inHours} 小时前';
    if (diff.inDays < 7) return '${diff.inDays} 天前';
    return DateFormat('yyyy-MM-dd').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: avatar + nickname + date
          ListTile(
            leading: ClipOval(
              child: _buildAvatar(context),
            ),
            title: Text(post.author.nickname),
            subtitle: Row(
              children: [
                Text(_formatDate(post.createdAt)),
                if (post.location != null) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.location_on,
                      size: 14, color: colorScheme.onSurfaceVariant),
                  const SizedBox(width: 2),
                  Text(post.location!,
                      style: theme.textTheme.bodySmall),
                ],
              ],
            ),
            trailing: const Icon(Icons.more_horiz),
          ),

          // Content text
          if (post.content.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(post.content),
            ),

          // Images
          if (post.images.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: PhotoGrid(images: post.images),
            ),

          // Stats + actions
          Row(
            children: [
              // Like
              TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor:
                      post.liked == true ? Colors.red : colorScheme.onSurface,
                ),
                onPressed: () {},
                icon: Icon(
                  post.liked == true ? Icons.favorite : Icons.favorite_border,
                ),
                label: Text('${post.likesCount}'),
              ),

              // Comment
              TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: colorScheme.onSurface,
                ),
                onPressed: () {},
                icon: const Icon(Icons.comment),
                label: Text('${post.commentsCount}'),
              ),

              // Collect
              TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: post.collected == true
                      ? Colors.amber
                      : colorScheme.onSurface,
                ),
                onPressed: () {},
                icon: Icon(
                  post.collected == true
                      ? Icons.bookmark
                      : Icons.bookmark_border,
                ),
                label: Text('${post.collectionsCount}'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(BuildContext context) {
    final avatarUrl = post.author.avatar;
    if (avatarUrl != null && avatarUrl.startsWith('http')) {
      // Network image for remote data
      return Image.network(
        avatarUrl,
        width: 40,
        height: 40,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => const CircleAvatar(
          radius: 20,
          child: Icon(Icons.person),
        ),
      );
    }
    // Local asset or fallback
    return (avatarUrl != null)
        ? Image.asset(
            avatarUrl,
            width: 40,
            height: 40,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => const CircleAvatar(
              radius: 20,
              child: Icon(Icons.person),
            ),
          )
        : const CircleAvatar(
            radius: 20,
            child: Icon(Icons.person),
          );
  }
}
