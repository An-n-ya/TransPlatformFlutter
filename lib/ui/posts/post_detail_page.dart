import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/post/post_repository.dart';
import '../../data/repositories/user/user_repository.dart';
import '../../domain/models/comment.dart';
import '../../domain/models/post.dart';
import '../../domain/models/user.dart';
import '../../utils/result.dart';
import 'photo_grid.dart';

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
  // TODO: use a state management solution like Provider to manage the current user's ID.
  int? _currentUserId;
  bool _isFocused = false;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _commentsFuture = _loadComments();
    _loadCurrentUser();
    _focusNode.addListener(() => setState(() => _isFocused = _focusNode.hasFocus));
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

    final result = await context
        .read<PostRepository>()
        .createComment(widget.post.id, content: content);

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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('评论发送失败')),
          );
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
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final result = await context.read<PostRepository>().deleteComment(commentId);
    if (!mounted) return;

    switch (result) {
      case Ok<void>():{
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('评论已删除')));
        _reloadComments();
      }
      case Error<void>():{
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('删除失败')));
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
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(top: 10, bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _PostHeader(post: widget.post),
                  if (widget.post.content.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Text(widget.post.content),
                    ),
                  if (widget.post.images.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: PhotoGrid(images: widget.post.images),
                    ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _InteractionBar(post: widget.post),
                  ),
                  const Divider(height: 24),
                  _buildCommentsSection(),
                ],
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
          Ok<List<Comment>>(:final value) => value.isEmpty
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

// ── Post header ──

class _PostHeader extends StatelessWidget {
  final Post post;
  const _PostHeader({required this.post});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: cs.primaryContainer,
            child: Text(
              post.author.nickname.isNotEmpty
                  ? post.author.nickname[0].toUpperCase()
                  : '?',
              style: TextStyle(color: cs.onPrimaryContainer, fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(post.author.nickname, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(_formatMeta(post), style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
              ],
            ),
          ),
          FilledButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none, size: 18),
            label: const Text('Follow'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
            ),
          ),
        ],
      ),
    );
  }

  String _formatMeta(Post post) {
    final parts = <String>[DateFormat('yyyy-MM-dd HH:mm').format(post.createdAt)];
    if (post.location != null && post.location!.isNotEmpty) parts.add(post.location!);
    return parts.join(' · ');
  }
}

// ── Interaction counts ──

class _InteractionBar extends StatelessWidget {
  final Post post;
  const _InteractionBar({required this.post});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(Icons.favorite_border, size: 18, color: cs.onSurface),
        const SizedBox(width: 4),
        Text('${post.likesCount}'),
        const SizedBox(width: 16),
        Icon(Icons.mode_comment_outlined, size: 18, color: cs.onSurface),
        const SizedBox(width: 4),
        Text('${post.commentsCount}'),
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
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: comments.length,
      separatorBuilder: (_, _) => const SizedBox(height: 16),
      itemBuilder: (_, i) => _CommentTile(
        comment: comments[i],
        isMe: currentUserId != null && comments[i].author.id == currentUserId,
        onDelete: () => onDeleteRequested?.call(comments[i].id),
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  final Comment comment;
  final bool isMe;
  final VoidCallback? onDelete;

  const _CommentTile({
    required this.comment,
    this.isMe = false,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: cs.primaryContainer,
          child: Text(
            comment.author.nickname.isNotEmpty
                ? comment.author.nickname[0].toUpperCase()
                : '?',
            style: TextStyle(color: cs.onPrimaryContainer, fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(comment.author.nickname,
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500)),
                  ),

                  if (isMe)
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onSelected: (value) {
                        if (value == 'delete') onDelete?.call();
                      },
                      itemBuilder: (_) => [
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
                  else
                    const SizedBox(width: 48),
                ],
              ),
              Text(DateFormat('yyyy-MM-dd HH:mm').format(comment.createdAt),
                  style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
              const SizedBox(height: 4),
              Text(comment.content),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.favorite_border, size: 18, color: cs.onSurface),
                  const SizedBox(width: 4),
                  Text('${comment.likesCount}'),
                ],
              ),
            ],
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
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
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
