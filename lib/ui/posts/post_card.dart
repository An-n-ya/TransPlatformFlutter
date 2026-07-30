import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trans_platform/ui/posts/interaction.dart';

import '../../data/repositories/post/post_repository.dart';
import '../../domain/models/post.dart';
import '../../domain/models/user.dart';
import '../../utils/result.dart';
import '../../utils/time.dart';
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
          onInteractionChanged:
              (liked, collected, likesCount, collectionsCount) {
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
  final void Function(
    bool liked,
    bool collected,
    int likesCount,
    int collectionsCount,
  )?
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
    widget.onInteractionChanged?.call(
      _liked,
      _collected,
      _likesCount,
      _collectionsCount,
    );
  }

  Future<void> _toggleLike() async {
    final repo = context.read<PostRepository>();
    final result = _liked
        ? await repo.unlikePost(widget.post.id)
        : await repo.likePost(widget.post.id);
    if (!mounted) return;
    switch (result) {
      case Ok<void>():
        {
          setState(() {
            _liked = !_liked;
            _likesCount += _liked ? 1 : -1;
          });
          _syncToParent();
        }
      case Error<void>():
        {
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('操作失败')));
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
      case Ok<void>():
        {
          setState(() {
            _collected = !_collected;
            _collectionsCount += _collected ? 1 : -1;
          });
          _syncToParent();
        }
      case Error<void>():
        {
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('操作失败')));
          }
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          PostHeader(
            user: widget.post.author,
            createdAt: widget.post.createdAt,
            location: widget.post.location,
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
                            Icon(
                              Icons.delete_outline,
                              size: 20,
                              color: Colors.red,
                            ),
                            SizedBox(width: 8),
                            Text('删除', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  )
                : const Icon(Icons.more_vert),
          ),

          PostContent(content: widget.post.content, images: widget.post.images),

          // ── Action buttons ──
          Row(
            children: [
              PostActionBtn(
                icon: _liked ? Icons.favorite : Icons.favorite_border,
                label: '$_likesCount',
                color: _liked ? Colors.red : null,
                onPressed: _toggleLike,
              ),
              PostActionBtn(
                icon: Icons.mode_comment_outlined,
                label: '${widget.post.commentsCount}',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => PostDetailPage(post: widget.post),
                  ),
                ),
              ),
              PostActionBtn(
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
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final result = await context.read<PostRepository>().deletePost(
      widget.post.id,
    );
    if (!context.mounted) return;

    switch (result) {
      case Ok<void>():
        {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('已删除')));
          widget.onPostDeleted?.call();
        }
      case Error<void>():
        {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('删除失败')));
        }
    }
  }
}

/// Reusable post/comment header: avatar, title, subtitle, trailing.
class PostHeader extends StatelessWidget {
  final User user;
  final Widget? title;
  final Widget? subtitle;
  final Widget? trailing;
  final DateTime? createdAt;
  final String? location;
  final VoidCallback? onAvatarTap;

  const PostHeader({
    super.key,
    required this.user,
    this.title,
    this.subtitle,
    this.trailing,
    this.createdAt,
    this.location,
    this.onAvatarTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      minTileHeight: 56,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      leading: GestureDetector(
        onTap: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => UserDetailPage(user: user))),
        child: ClipOval(child: _buildAvatar(context)),
      ),
      title: title ??
          GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) => UserDetailPage(user: user)),
            ),
            child: Text(user.nickname),
          ),
      subtitle: subtitle ??
          (createdAt != null
              ? Row(
                  children: [
                    Text(formatRelativeTime(createdAt!)),
                    if (location != null) ...[
                      const SizedBox(width: 8),
                      Icon(Icons.location_on,
                          size: 14, color: cs.onSurfaceVariant),
                      const SizedBox(width: 2),
                      Text(location!,
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ],
                )
              : null),

      trailing: trailing,
    );
  }

  Widget _buildAvatar(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    ImageProvider? image;
    if (user.avatar != null && user.avatar!.isNotEmpty) {
      image = user.avatar!.startsWith('http')
          ? NetworkImage(user.avatar!)
          : AssetImage(user.avatar!) as ImageProvider;
    }
    return CircleAvatar(
      radius: 20,
      backgroundColor: cs.primaryContainer,
      backgroundImage: image,
      child: image == null
          ? Text(
              user.nickname.isNotEmpty ? user.nickname[0].toUpperCase() : '?',
              style: TextStyle(
                color: cs.onPrimaryContainer,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            )
          : null,
    );
  }
}


class PostContent extends StatelessWidget {
  final String? content;
  final List<String>? images;
  const PostContent({
    super.key,
    this.content,
    this.images,
  });
  
  @override
  Widget build(BuildContext context) {
          return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
            children: [

          if (content != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(content!),
            ),
          if (images != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: PhotoGrid(images: images!),
            ),
          ]);

          // ── Images ──
  }
}