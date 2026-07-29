import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/post/post_repository.dart';
import '../../domain/models/post.dart';
import '../../utils/result.dart';
import '../user/user_detail_page.dart';
import 'photo_grid.dart';
import 'post_detail_page.dart';

/// Tracks user-initiated interaction overrides per post.
class _PostInteractions {
  bool liked;
  bool collected;
  int likesCount;
  int collectionsCount;

  _PostInteractions.fromPost(Post post)
      : liked = post.liked ?? false,
        collected = post.collected ?? false,
        likesCount = post.likesCount,
        collectionsCount = post.collectionsCount;
}

/// A feed-style list of [PostCard]s with persistent interaction state.
class PostFeed extends StatefulWidget {
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
  State<PostFeed> createState() => _PostFeedState();
}

class _PostFeedState extends State<PostFeed> {
  final Map<int, _PostInteractions> _interactions = {};

  _PostInteractions _forPost(Post post) {
    return _interactions.putIfAbsent(
      post.id,
      () => _PostInteractions.fromPost(post),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: widget.posts.length,
      itemBuilder: (_, i) {
        final post = widget.posts[i];
        final ix = _forPost(post);
        return PostCard(
          post: post,
          isMe: widget.isMe,
          onPostDeleted: widget.onPostDeleted,
          initialLiked: ix.liked,
          initialCollected: ix.collected,
          initialLikesCount: ix.likesCount,
          initialCollectionsCount: ix.collectionsCount,
          onInteractionChanged: (liked, collected, likesCount, collectionsCount) {
            ix.liked = liked;
            ix.collected = collected;
            ix.likesCount = likesCount;
            ix.collectionsCount = collectionsCount;
          },
        );
      },
    );
  }
}

/// A single post card — avatar, content, images, action buttons.
class PostCard extends StatefulWidget {
  final Post post;
  final bool isMe;
  final VoidCallback? onPostDeleted;
  final bool initialLiked;
  final bool initialCollected;
  final int initialLikesCount;
  final int initialCollectionsCount;
  final void Function(bool liked, bool collected, int likesCount, int collectionsCount)?
      onInteractionChanged;

  const PostCard({
    super.key,
    required this.post,
    this.isMe = false,
    this.onPostDeleted,
    this.initialLiked = false,
    this.initialCollected = false,
    this.initialLikesCount = 0,
    this.initialCollectionsCount = 0,
    this.onInteractionChanged,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  late bool _liked;
  late bool _collected;
  late int _likesCount;
  late int _collectionsCount;

  @override
  void initState() {
    super.initState();
    _liked = widget.initialLiked;
    _collected = widget.initialCollected;
    _likesCount = widget.initialLikesCount;
    _collectionsCount = widget.initialCollectionsCount;
  }

  void _syncToParent() {
    widget.onInteractionChanged
        ?.call(_liked, _collected, _likesCount, _collectionsCount);
  }

  Future<void> _toggleLike() async {
    final repo = context.read<PostRepository>();
    final result = _liked
        ? await repo.unlikePost(widget.post.id)
        : await repo.likePost(widget.post.id);
    if (!mounted) return;
    switch (result) {
      case Ok<void>():{
        setState(() {
          _liked = !_liked;
          _likesCount += _liked ? 1 : -1;
        });
        _syncToParent();
      }
      case Error<void>():{
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('操作失败')),
          );
        }
      }
    }
  }

  Future<void> _toggleCollect() async {
    final repo = context.read<PostRepository>();
    final result = _collected
        ? await repo.uncollectPost(widget.post.id)
        : await repo.collectPost(widget.post.id);
    if (!mounted) return;
    switch (result) {
      case Ok<void>():{
        setState(() {
          _collected = !_collected;
          _collectionsCount += _collected ? 1 : -1;
        });
        _syncToParent();
      }
      case Error<void>():{
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('操作失败')),
          );
        }
      }
    }
  }

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
                  builder: (_) => UserDetailPage(user: widget.post.author),
                ),
              ),
              child: ClipOval(child: _buildAvatar(context)),
            ),
            title: GestureDetector(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => UserDetailPage(user: widget.post.author),
                ),
              ),
              child: Text(widget.post.author.nickname),
            ),
            subtitle: Row(
              children: [
                Text(_formatDate(widget.post.createdAt)),
                if (widget.post.location != null) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.location_on,
                      size: 14, color: cs.onSurfaceVariant),
                  const SizedBox(width: 2),
                  Text(widget.post.location!, style: theme.textTheme.bodySmall),
                ],
              ],
            ),
            trailing: widget.isMe
                ? PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (value) {
                      if (value == 'delete') _deletePost();
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
                : const Icon(Icons.more_vert),
          ),

          // ── Content ──
          if (widget.post.content.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(widget.post.content),
            ),

          // ── Images ──
          if (widget.post.images.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: PhotoGrid(images: widget.post.images),
            ),

          // ── Action buttons ──
          Row(
            children: [
              _ActionBtn(
                icon: _liked ? Icons.favorite : Icons.favorite_border,
                label: '$_likesCount',
                color: _liked ? Colors.red : null,
                onPressed: _toggleLike,
              ),
              _ActionBtn(
                icon: Icons.mode_comment_outlined,
                label: '${widget.post.commentsCount}',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => PostDetailPage(post: widget.post),
                  ),
                ),
              ),
              _ActionBtn(
                icon: _collected ? Icons.bookmark : Icons.bookmark_border,
                label: '$_collectionsCount',
                color: _collected ? Colors.amber : null,
                onPressed: _toggleCollect,
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
    final url = widget.post.author.avatar;
    const fallback = CircleAvatar(radius: 20, child: Icon(Icons.person));
    if (url == null) return fallback;
    if (url.startsWith('http')) {
      return Image.network(url, width: 40, height: 40, fit: BoxFit.cover,
          errorBuilder: (_, _, _) => fallback);
    }
    return Image.asset(url, width: 40, height: 40, fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback);
  }

  Future<void> _deletePost() async {
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

    final result = await context.read<PostRepository>().deletePost(widget.post.id);
    if (!context.mounted) return;

    switch (result) {
      case Ok<void>():{
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已删除')),
        );
        widget.onPostDeleted?.call();
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
