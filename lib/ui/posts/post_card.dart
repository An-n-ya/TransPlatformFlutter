import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/models/post.dart';
import '../user/user_detail_page.dart';
import 'photo_grid.dart';

/// A feed-style list of [PostCard]s.
class PostFeed extends StatelessWidget {
  final List<Post> posts;

  const PostFeed({super.key, required this.posts});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: posts.length,
      itemBuilder: (_, i) => PostCard(post: posts[i]),
    );
  }
}

/// A single post card — avatar, content, images, action buttons.
class PostCard extends StatelessWidget {
  final Post post;

  const PostCard({super.key, required this.post});

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
            leading: ClipOval(child: _buildAvatar(context)),
            title: Text(post.author.nickname),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => UserDetailPage(user: post.author),
              ),
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
            trailing: const Icon(Icons.more_horiz),
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
