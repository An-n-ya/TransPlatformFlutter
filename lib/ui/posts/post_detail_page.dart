import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/post/post_repository.dart';
import '../../data/repositories/user/user_repository.dart';
import '../../domain/models/comment.dart';
import '../../domain/models/post.dart';
import '../../domain/models/user.dart';
import '../../utils/result.dart';
import 'photo_grid.dart';
import 'post_card.dart';

/// Post detail page with comments and comment input.
class PostDetailPage extends StatefulWidget {
  final Post post;

  const PostDetailPage({super.key, required this.post});

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  final _commentController = TextEditingController();
  final _focusNode = FocusNode();
  late Future<Result<List<Comment>>> _commentsFuture;
  int? _currentUserId;
  bool _isFocused = false;
  bool _isSending = false;

  // Interaction state
  late bool _liked;
  late bool _collected;
  late int _likesCount;
  late int _collectionsCount;

  @override
  void initState() {
    super.initState();
    _liked = widget.post.liked ?? false;
    _collected = widget.post.collected ?? false;
    _likesCount = widget.post.likesCount;
    _collectionsCount = widget.post.collectionsCount;
    _commentsFuture = _loadComments();
    _loadCurrentUser();
    _focusNode.addListener(
      () => setState(() => _isFocused = _focusNode.hasFocus),
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUser() async {
    final result = await context.read<UserRepository>().getCurrentUser();
    if (!mounted) return;
    if (result is Ok<User>) {
      setState(() => _currentUserId = result.value.id);
    }
  }

  Future<Result<List<Comment>>> _loadComments() =>
      context.read<PostRepository>().getPostComments(widget.post.id);

  Future<void> _sendComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    setState(() => _isSending = true);

    final result = await context.read<PostRepository>().createComment(
      widget.post.id,
      content: content,
    );

    if (!mounted) return;

    switch (result) {
      case Ok<Comment>():
        _commentController.clear();
        setState(() {
          _isSending = false;
          _commentsFuture = _loadComments();
        });
      case Error<Comment>():
        setState(() => _isSending = false);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('评论发送失败')));
        }
    }
  }

  void _reloadComments() {
    _commentsFuture = _loadComments();
    setState(() {});
  }

  Future<void> _deleteComment(int commentId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除评论'),
        content: const Text('确定要删除这条评论吗？'),
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

    final result = await context.read<PostRepository>().deleteComment(
      commentId,
    );
    if (!mounted) return;

    switch (result) {
      case Ok<void>():
        {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('评论已删除')));
          _reloadComments();
        }
      case Error<void>():
        {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('删除失败')));
        }
    }
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
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Post'),
        actions: [
          IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(top: 10, bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PostHeader(
                      user: widget.post.author,
                      createdAt: widget.post.createdAt,
                      location: widget.post.location,
                      trailing: FilledButton.icon(
                        onPressed: () {},
                        icon:
                            const Icon(Icons.notifications_none, size: 18),
                        label: const Text('Follow'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(100),
                          ),
                        ),
                      ),
                    ),
                  if (widget.post.content.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Text(widget.post.content),
                    ),
                  if (widget.post.images.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: PhotoGrid(images: widget.post.images),
                    ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: _InteractionBar(
                      liked: _liked,
                      collected: _collected,
                      likesCount: _likesCount,
                      collectionsCount: _collectionsCount,
                      commentsCount: widget.post.commentsCount,
                      onLike: _toggleLike,
                      onCollect: _toggleCollect,
                    ),
                  ),
                  const Divider(height: 24),
                  _buildCommentsSection(),
                ],
                ),
              ),
            ),
          ),
          _CommentInput(
            controller: _commentController,
            focusNode: _focusNode,
            isFocused: _isFocused,
            isSending: _isSending,
            onSend: _sendComment,
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsSection() {
    return FutureBuilder<Result<List<Comment>>>(
      future: _commentsFuture,
      builder: (_, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        return switch (snapshot.data!) {
          Ok<List<Comment>>(:final value) =>
            value.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text('暂无评论'),
                  )
                : _CommentList(
                    comments: value,
                    currentUserId: _currentUserId,
                    onDeleteRequested: (id) => _deleteComment(id),
                  ),
          Error<List<Comment>>() => const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Text('加载评论失败'),
          ),
        };
      },
    );
  }
}

// ── Interaction counts ──

class _InteractionBar extends StatelessWidget {
  final bool liked;
  final bool collected;
  final int likesCount;
  final int collectionsCount;
  final int commentsCount;
  final VoidCallback onLike;
  final VoidCallback onCollect;

  const _InteractionBar({
    required this.liked,
    required this.collected,
    required this.likesCount,
    required this.collectionsCount,
    required this.commentsCount,
    required this.onLike,
    required this.onCollect,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        PostActionBtn(
          icon: liked ? Icons.favorite : Icons.favorite_border,
          label: '$likesCount',
          color: liked ? Colors.red : null,
          onPressed: onLike,
        ),
        const SizedBox(width: 8),
        PostActionBtn(
          icon: Icons.mode_comment_outlined,
          label: '$commentsCount',
          onPressed: () {},
        ),
        const SizedBox(width: 8),
        PostActionBtn(
          icon: collected ? Icons.bookmark : Icons.bookmark_border,
          label: '$collectionsCount',
          color: collected ? Colors.amber : null,
          onPressed: onCollect,
        ),
      ],
    );
  }
}

// ── Comment list ──

class _CommentList extends StatelessWidget {
  final List<Comment> comments;
  final int? currentUserId;
  final ValueChanged<int>? onDeleteRequested;

  const _CommentList({
    required this.comments,
    this.currentUserId,
    this.onDeleteRequested,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(horizontal: 0),
      itemCount: comments.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (_, i) => _CommentTile(
        comment: comments[i],
        isMe: currentUserId != null && comments[i].author.id == currentUserId,
        onDelete: () => onDeleteRequested?.call(comments[i].id),
      ),
    );
  }
}

class _CommentTile extends StatefulWidget {
  final Comment comment;
  final bool isMe;
  final VoidCallback? onDelete;

  const _CommentTile({
    required this.comment,
    this.isMe = false,
    this.onDelete,
  });

  @override
  State<_CommentTile> createState() => _CommentTileState();
}

class _CommentTileState extends State<_CommentTile> {
  late bool _liked;
  late int _likesCount;

  @override
  void initState() {
    super.initState();
    _liked = false;
    _likesCount = widget.comment.likesCount;
  }

  Future<void> _toggleLike() async {
    final repo = context.read<PostRepository>();
    final result = _liked
        ? await repo.unlikeComment(widget.comment.id)
        : await repo.likeComment(widget.comment.id);
    if (!mounted) return;
    switch (result) {
      case Ok<void>():{
        setState(() {
          _liked = !_liked;
          _likesCount += _liked ? 1 : -1;
        });
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PostHeader(
          user: widget.comment.author,
          createdAt: widget.comment.createdAt,
          trailing: widget.isMe
              ? PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onSelected: (value) {
                    if (value == 'delete') widget.onDelete?.call();
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
              : const SizedBox(width: 48),
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: 72),
          child: Text(widget.comment.content),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(left: 60),
          child: PostActionBtn(
            icon: _liked ? Icons.favorite : Icons.favorite_border,
            label: '$_likesCount',
            color: _liked ? Colors.red : null,
            onPressed: _toggleLike,
          ),
        ),
      ],
    );
  }
}

// ── Comment input ──

class _CommentInput extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isFocused;
  final bool isSending;
  final VoidCallback onSend;

  const _CommentInput({
    required this.controller,
    required this.focusNode,
    required this.isFocused,
    required this.isSending,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: cs.outline)),
          color: cs.surface,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          height: isFocused ? 120 : 40,
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(24),
          ),
          padding: const EdgeInsets.only(left: 16, right: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  decoration: const InputDecoration(
                    hintText: '我有话要说！',
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              if (isFocused)
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 4),
                  child: isSending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : FilledButton.icon(
                          onPressed: onSend,
                          icon: const Icon(Icons.upload_outlined, size: 18),
                          label: const Text('发送'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(100),
                            ),
                          ),
                        ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
