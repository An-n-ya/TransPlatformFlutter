import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart';

import '../../data/cache/post_cache.dart';
import '../../data/repositories/user/user_repository.dart';
import '../../data/services/current_user_provider.dart';
import '../../data/services/global_config_provider.dart';
import '../../domain/models/post.dart';
import '../../domain/models/user.dart';
import '../../providers/post_interaction_providers.dart';
import '../../utils/result.dart';
import '../../utils/time.dart';
import '../user/user_detail_page.dart';
import '../widgets/post_image_grid.dart';
import '../widgets/stat_button.dart';
import '../widgets/topic_chip.dart';
import '../widgets/user_avatar.dart';
import 'post_detail_page.dart';

/// A feed-style list of [PostCard]s.
///
/// Interaction state is read from the SSOT post cache, so every card always
/// reflects the latest data across pages.
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
  @override
  Widget build(BuildContext context) {
    final listView = ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(8),
      itemCount: widget.posts.length,
      itemBuilder: (_, i) {
        final post = widget.posts[i];
        return PostCard(
          post: post,
          isMe: widget.isMe,
          onPostDeleted: widget.onPostDeleted,
        );
      },
    );

    final onRefresh = widget.onRefresh;
    if (onRefresh == null) return listView;

    return RefreshIndicator(onRefresh: onRefresh, child: listView);
  }
}

/// A single post card — avatar, content, images, action buttons.
class PostCard extends ConsumerStatefulWidget {
  final Post post;
  final bool isMe;
  final VoidCallback? onPostDeleted;
  final Widget? trailing;
  final VoidCallback? onCommentTap;

  /// Whether tapping a non-interactive area of the card opens the post
  /// detail page. Disabled inside [PostDetailPage] to avoid re-entry.
  final bool openDetailOnTap;

  const PostCard({
    super.key,
    required this.post,
    this.isMe = false,
    this.onPostDeleted,
    this.trailing,
    this.onCommentTap,
    this.openDetailOnTap = true,
  });

  @override
  ConsumerState<PostCard> createState() => _PostCardState();
}

class _PostCardState extends ConsumerState<PostCard> {
  @override
  void initState() {
    super.initState();
    // Make sure the post exists in the SSOT cache without overwriting newer
    // data (e.g. an interaction applied from the detail page). Deferred so the
    // cache is not mutated while the widget tree is building.
    final post = widget.post;
    Future(() {
      if (mounted) {
        ref.read(postCacheProvider.notifier).ensure(post);
      }
    });
  }

  void _openDetail() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PostDetailPage(post: widget.post)),
    );
  }

  Future<void> _toggleLike() async {
    await ref
        .read(postInteractionProvider.notifier)
        .toggleLike(widget.post.id);
  }

  Future<void> _toggleCollect() async {
    await ref
        .read(postInteractionProvider.notifier)
        .toggleCollect(widget.post.id);
  }

  @override
  Widget build(BuildContext context) {
    final isPinned =
        context.watch<CurrentUserProvider>().pinnedPostId == widget.post.id;
    // Read the latest entity from the SSOT cache so interactions applied on
    // other pages (e.g. detail) are reflected here automatically.
    final post =
        ref.watch(postCacheProvider).getById(widget.post.id) ?? widget.post;
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
                      icon: (post.liked ?? false)
                          ? Icons.favorite
                          : Icons.favorite_border,
                      label: '${post.likesCount}',
                      color: (post.liked ?? false)
                          ? Colors.red
                          : const Color(0xFF1D1B20),
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
                      icon: (post.collected ?? false)
                          ? Icons.bookmark
                          : Icons.bookmark_border,
                      label: '${post.collectionsCount}',
                      color: (post.collected ?? false)
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

    final deleted = await ref
        .read(postInteractionProvider.notifier)
        .delete(widget.post.id);
    if (deleted) {
      widget.onPostDeleted?.call();
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
