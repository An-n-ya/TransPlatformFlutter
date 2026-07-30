import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trans_platform/ui/posts/comment.dart';
import 'package:trans_platform/ui/posts/comment_input.dart';
import 'package:trans_platform/ui/posts/interaction.dart';

import '../../data/repositories/post/post_repository.dart';
import '../../data/repositories/user/user_repository.dart';
import '../../domain/models/comment.dart';
import '../../domain/models/post.dart';
import '../../domain/models/user.dart';
import '../../utils/result.dart';
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
    // TODO: 使用 Provider 直接获取当前用户信息，而不是从数据库中查询
    // 在用户登录后将当前用户的 ID 存储在Provider全局状态管理工具
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
                        icon: const Icon(Icons.notifications_none, size: 18),
                        label: const Text('关注'),
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
                    PostContent(content: widget.post.content, images: widget.post.images),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: InteractionBar(
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
          CommentInput(
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
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text('加载评论失败: ${snapshot.error}'),
          );
        }
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
                : CommentList(
                    comments: value,
                    currentUserId: _currentUserId,
                    onDeleteRequested: (id) => _deleteComment(id),
                  ),
          Error<List<Comment>>(:final error) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text('加载评论失败: $error'),
          ),
        };
      },
    );
  }
}




