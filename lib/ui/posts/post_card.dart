import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/post/post_repository.dart';
import '../../domain/models/post.dart';
import '../../utils/result.dart';
import '../user/user_detail_page.dart';
import 'photo_grid.dart';

/// A feed-style list of [PostCard]s.
class PostFeed extends StatelessWidget {
  final List<Post> posts;
  final bool isMe;
  final VoidCallback? onPostDeleted;

  const PostFeed({
    super.key,
    required this.posts,
    this.isMe = false,
    this.onPostDeleted,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: posts.length,
      itemBuilder: (_, i) => PostCard(
        post: posts[i],
        isMe: isMe,
        onPostDeleted: onPostDeleted,
      ),
    );
  }
}

/// A single post card — avatar, content, images, action buttons.
class PostCard extends StatelessWidget {
  final Post post;
  final bool isMe;
  final VoidCallback? onPostDeleted;

  const PostCard({
    super.key,
    required this.post,
    this.isMe = false,
    this.onPostDeleted,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          ListTile(
            leading: GestureDetector(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => UserDetailPage(user: post.author),
                ),
              ),
              child: ClipOval(child: _buildAvatar(context)),
            ),
            title: GestureDetector(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => UserDetailPage(user: post.author),
                ),
              ),
              child: Text(post.author.nickname),
            ),
            subtitle: Row(
              children: [
                Text(_formatDate(post.createdAt)),
                if (post.location != null) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.location_on,
                      size: 14, color: cs.onSurfaceVariant),
                  const SizedBox(width: 2),
                  Text(post.location!, style: theme.textTheme.bodySmall),
                ],
              ],
            ),
            trailing: isMe
                ? PopupMenuButton<String>(
                    icon: const Icon(Icons.more_horiz),
                    onSelected: (value) {
                      if (value == 'delete') _deletePost(context);
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline,
                                size: 20, color: Colors.red),
                            SizedBox(width: 8),
                            Text('删除', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  )
                : const Icon(Icons.more_horiz),
          ),

          // ── Content ──
          if (post.content.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(post.content),
            ),

          // ── Images ──
          if (post.images.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: PhotoGrid(images: post.images),
            ),

          // ── Action buttons ──
          Row(
            children: [
              _ActionBtn(
                icon: post.liked == true ? Icons.favorite : Icons.favorite_border,
                label: '${post.likesCount}',
                color: post.liked == true ? Colors.red : null,
                onPressed: () {},
              ),
              _ActionBtn(
                icon: Icons.comment,
                label: '${post.commentsCount}',
                onPressed: () {},
              ),
              _ActionBtn(
                icon: post.collected == true
                    ? Icons.bookmark
                    : Icons.bookmark_border,
                label: '${post.collectionsCount}',
                color: post.collected == true ? Colors.amber : null,
                onPressed: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes} 分钟前';
    if (diff.inHours < 24) return '${diff.inHours} 小时前';
    if (diff.inDays < 7) return '${diff.inDays} 天前';
    return DateFormat('yyyy-MM-dd').format(dt);
  }

  Widget _buildAvatar(BuildContext context) {
    final url = post.author.avatar;
    const fallback = CircleAvatar(radius: 20, child: Icon(Icons.person));
    if (url == null) return fallback;
    if (url.startsWith('http')) {
      return Image.network(url, width: 40, height: 40, fit: BoxFit.cover,
          errorBuilder: (_, _, _) => fallback);
    }
    return Image.asset(url, width: 40, height: 40, fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback);
  }

  Future<void> _deletePost(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除贴文'),
        content: const Text('确定要删除这条贴文吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('删除',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final result = await context.read<PostRepository>().deletePost(post.id);
    if (!context.mounted) return;

    switch (result) {
      case Ok<void>():{
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已删除')),
        );
        onPostDeleted?.call();
      }
      case Error<void>():{
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('删除失败')),
        );
      }
    }
  }
}

/// Small helper for like / comment / collect buttons.
class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onPressed;

  const _ActionBtn({
    required this.icon,
    required this.label,
    this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return TextButton.icon(
      style: TextButton.styleFrom(foregroundColor: color ?? cs.onSurface),
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
    );
  }
}
