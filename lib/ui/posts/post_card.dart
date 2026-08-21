import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/post/post_repository.dart';
import '../../data/repositories/user/user_repository.dart';
import '../../data/services/current_user_provider.dart';
import '../../data/services/global_config_provider.dart';
import '../../domain/models/post.dart';
import '../../domain/models/user.dart';
import '../../utils/result.dart';
import '../../utils/time.dart';
import '../user/user_detail_page.dart';
import '../widgets/post_image_grid.dart';
import '../widgets/stat_button.dart';
import '../widgets/topic_chip.dart';
import '../widgets/user_avatar.dart';
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
  final Future<void> Function()? onRefresh;

  const PostFeed({
    super.key,
    required this.posts,
    this.isMe = false,
    this.onPostDeleted,
    this.onRefresh,
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
    final listView = ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
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

    final onRefresh = widget.onRefresh;
    if (onRefresh == null) return listView;

    return RefreshIndicator(onRefresh: onRefresh, child: listView);
  }
}

/// A single post card — avatar, content, images, action buttons.
class PostCard extends StatefulWidget {
  final Post post;
  final bool isMe;
  final VoidCallback? onPostDeleted;
  final Widget? trailing;
  final VoidCallback? onCommentTap;

  /// Whether tapping a non-interactive area of the card opens the post
  /// detail page. Disabled inside [PostDetailPage] to avoid re-entry.
  final bool openDetailOnTap;
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
    this.trailing,
    this.onCommentTap,
    this.openDetailOnTap = true,
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

  void _openDetail() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PostDetailPage(post: widget.post)),
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
    final isPinned =
        context.watch<CurrentUserProvider>().pinnedPostId == widget.post.id;
    final post = widget.post;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x22CAC4D0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            offset: Offset(0, 1),
            blurRadius: 3,
          ),
          BoxShadow(
            color: Color(0x1A000000),
            offset: Offset(0, 1),
            blurRadius: 2,
            spreadRadius: -1,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.openDetailOnTap ? _openDetail : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, post, isPinned),
              if (post.content.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: Text(
                    post.content,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 22 / 14,
                      color: Color(0xFF1D1B20),
                    ),
                  ),
                ),
              if (post.topics.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final topic in post.topics) TopicChip(topic: topic),
                    ],
                  ),
                ),
              if (post.images.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: PostImageGrid(images: post.images),
                ),
              // ── Card divider ──
              const Divider(
                thickness: 1,
                indent: 0,
                endIndent: 0,
                color: Color(0x55CAC4D0),
              ),
              // ── Stats row ──
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: Row(
                  children: [
                    StatButton(
                      icon: _liked ? Icons.favorite : Icons.favorite_border,
                      label: '$_likesCount',
                      color: _liked ? Colors.red : const Color(0xFF1D1B20),
                      onTap: _toggleLike,
                    ),
                    const SizedBox(width: 20),
                    StatButton(
                      icon: Icons.mode_comment_outlined,
                      label: '${post.commentsCount}',
                      onTap: widget.onCommentTap ?? _openDetail,
                    ),
                    const SizedBox(width: 20),
                    StatButton(
                      icon: _collected ? Icons.bookmark : Icons.bookmark_border,
                      label: '$_collectionsCount',
                      color: _collected
                          ? Colors.amber
                          : const Color(0xFF1D1B20),
                      onTap: _toggleCollect,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Post post, bool isPinned) {
    final debugMode = context.watch<GlobalConfigProvider>().debugMode;
    final meta = [
      formatRelativeTime(post.createdAt),
      if (post.location != null && post.location!.isNotEmpty) post.location!,
      if (debugMode) '#${post.id}',
    ].join(' · ');

    void openAuthor() => Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => UserDetailPage(user: post.author)),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
      child: Row(
        children: [
          UserAvatar(user: post.author, onTap: openAuthor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: openAuthor,
                  child: Text(
                    post.author.nickname,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1D1B20),
                    ),
                  ),
                ),
                Text(
                  meta,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF49454F),
                  ),
                ),
              ],
            ),
          ),
          widget.trailing ??
              PostCardTrailing(
                isMe: widget.isMe,
                isPinned: isPinned,
                onDelete: _deletePost,
                onTogglePin: _togglePin,
              ),
        ],
      ),
    );
  }

  Future<void> _togglePin() async {
    final repo = context.read<UserRepository>();
    final provider = context.read<CurrentUserProvider>();
    final isPinned = provider.pinnedPostId == widget.post.id;
    final result = isPinned
        ? await repo.clearPinnedPost()
        : await repo.setPinnedPost(widget.post.id);
    if (!mounted) return;
    switch (result) {
      case Ok<User>():
        {
          if (isPinned) {
            provider.clearPinnedPostId();
          } else {
            provider.setPinnedPostId(widget.post.id);
          }
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(isPinned ? '已取消置顶' : '已置顶')));
        }
      case Error<User>():
        {
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('操作失败')));
          }
        }
    }
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
  final String? postId;
  final VoidCallback? onAvatarTap;

  const PostHeader({
    super.key,
    required this.user,
    this.title,
    this.subtitle,
    this.trailing,
    this.createdAt,
    this.location,
    this.postId,
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
      title:
          title ??
          GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => UserDetailPage(user: user)),
            ),
            child: Text(user.nickname),
          ),
      subtitle:
          subtitle ??
          (createdAt != null
              ? Row(
                  children: [
                    Text(formatRelativeTime(createdAt!)),
                    if (location != null) ...[
                      const SizedBox(width: 8),
                      Icon(
                        Icons.location_on,
                        size: 14,
                        color: cs.onSurfaceVariant,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        location!,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                    if (context.watch<GlobalConfigProvider>().debugMode &&
                        postId != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        '#$postId',
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: cs.primary),
                      ),
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

/// Trailing widget for a post header: pinned flag + more menu.
class PostCardTrailing extends StatelessWidget {
  final bool isMe;
  final bool isPinned;
  final VoidCallback onDelete;
  final VoidCallback onTogglePin;

  const PostCardTrailing({
    super.key,
    required this.isMe,
    required this.isPinned,
    required this.onDelete,
    required this.onTogglePin,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isPinned)
          const Padding(
            padding: EdgeInsets.only(right: 8),
            child: Icon(Icons.push_pin, size: 18, color: Colors.amber),
          ),
        if (isMe)
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
                case 'delete':
                  onDelete();
                case 'pin':
                  onTogglePin();
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'pin',
                child: Row(
                  children: [
                    Icon(
                      isPinned ? Icons.push_pin_outlined : Icons.push_pin,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(isPinned ? '取消置顶' : '置顶'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, size: 20, color: Colors.red),
                    SizedBox(width: 8),
                    Text('删除', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          )
        else if (!isPinned)
          const SizedBox.shrink()
        else
          const SizedBox(width: 24),
      ],
    );
  }
}
