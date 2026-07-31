import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trans_platform/ui/posts/comment.dart';
import 'package:trans_platform/ui/posts/comment_input.dart';
import 'package:trans_platform/ui/posts/interaction.dart';

import '../../data/repositories/post/post_repository.dart';
import '../../data/services/current_user_provider.dart';
import '../../domain/models/comment.dart';
import '../../domain/models/post.dart';
import '../../utils/result.dart';
import 'post_card.dart';


/// Post detail page with comments and comment input.
class PostDetailPage extends StatefulWidget {
  final int? postId;
  final Post? post;

  const PostDetailPage({super.key, this.postId, this.post});

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

  // Post state (loaded from network when only postId is given)
  Post? _post;
  bool _isLoadingPost = false;
  String? _loadError;

  // Interaction state
  late bool _liked;
  late bool _collected;
  late int _likesCount;
  late int _collectionsCount;

  @override
  void initState() {
    super.initState();
    _post = widget.post;
    _initInteractionState();
    _initComments();
    _loadCurrentUser();
    _focusNode.addListener(
      () => setState(() => _isFocused = _focusNode.hasFocus),
    );
    if (_post == null && widget.postId != null) {
      _fetchPost();
    }
  }

  void _initInteractionState() {
    _liked = _post?.liked ?? false;
    _collected = _post?.collected ?? false;
    _likesCount = _post?.likesCount ?? 0;
    _collectionsCount = _post?.collectionsCount ?? 0;
  }

  void _initComments() {
    if (_post != null) {
      _commentsFuture = _loadComments();
    }
  }

  Future<void> _fetchPost() async {
    setState(() => _isLoadingPost = true);
    final result =
        await context.read<PostRepository>().getPost(widget.postId!);
    if (!mounted) return;
    switch (result) {
      case Ok<Post>(:final value):
        setState(() {
          _post = value;
          _isLoadingPost = false;
        });
        _initInteractionState();
        _initComments();
        if (mounted) setState(() {});
      case Error<Post>():{
        setState(() {
          _isLoadingPost = false;
          _loadError = result.error.toString();
        });
      }
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _loadCurrentUser() {
    _currentUserId = context.read<CurrentUserProvider>().userId;
  }

  Future<Result<List<Comment>>> _loadComments() =>
      context.read<PostRepository>().getPostComments(_post!.id);

  Future<void> _sendComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    setState(() => _isSending = true);

    final result = await context.read<PostRepository>().createComment(
      _post!.id,
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
        ? await repo.unlikePost(_post!.id)
        : await repo.likePost(_post!.id);
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
        ? await repo.uncollectPost(_post!.id)
        : await repo.collectPost(_post!.id);
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
    final post = _post;
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
      body: _buildBody(post),
    );
  }

  Widget _buildBody(Post? post) {
    // Post not yet available
    if (post == null) {
      if (_isLoadingPost) {
        return const Center(child: CircularProgressIndicator());
      }
      if (_loadError != null) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('加载失败',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(_loadError!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 16),
              FilledButton.tonal(
                onPressed: () {
                  setState(() {
                    _loadError = null;
                    _fetchPost();
                  });
                },
                child: const Text('重试'),
              ),
            ],
          ),
        );
      }
      // Both post and postId are null → blank page
      return const SizedBox.shrink();
    }

    return Column(
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
                    user: post.author,
                    createdAt: post.createdAt,
                    location: post.location,
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
                  PostContent(content: post.content, images: post.images),
                  InteractionBar(
                    liked: _liked,
                    collected: _collected,
                    likesCount: _likesCount,
                    collectionsCount: _collectionsCount,
                    commentsCount: post.commentsCount,
                    onLike: _toggleLike,
                    onCollect: _toggleCollect,
                    onComment: () => {},
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
