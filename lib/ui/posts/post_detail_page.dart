import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trans_platform/ui/posts/comment.dart';
import 'package:trans_platform/ui/posts/comment_input.dart';

import '../../data/repositories/post/post_repository.dart';
import '../../data/services/current_user_provider.dart';
import '../../domain/models/comment.dart';
import '../../domain/models/post.dart';
import '../../utils/result.dart';
import '../../utils/time.dart';
import '../user/user_buttons.dart';
import '../user/user_detail_page.dart';
import '../widgets/post_image_grid.dart';
import '../widgets/stat_button.dart';
import '../widgets/topic_chip.dart';
import '../widgets/user_avatar.dart';

/// Post detail page (PostDetail-Mobile design).
///
/// Shows the post inside a white rounded card (author header, content,
/// topic chips, image grid, stats row), then the comment list below a
/// section divider, with a sticky comment input at the bottom.
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
      case Error<Post>():
        setState(() {
          _isLoadingPost = false;
          _loadError = result.error.toString();
        });
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

    if (confirmed != true || !mounted) return;

    final result = await context.read<PostRepository>().deleteComment(
      commentId,
    );
    if (!mounted) return;

    switch (result) {
      case Ok<void>():
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('评论已删除')));
        _reloadComments();
      case Error<void>():
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('删除失败')));
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
        setState(() {
          _liked = !_liked;
          _likesCount += _liked ? 1 : -1;
        });
      case Error<void>():
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('操作失败')));
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
        setState(() {
          _collected = !_collected;
          _collectionsCount += _collected ? 1 : -1;
        });
      case Error<void>():
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('操作失败')));
    }
  }

  // ── Build ──

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final post = _post;
    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 22),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          '贴文',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: cs.onSurface,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, size: 22),
            onPressed: () {},
          ),
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
      // Both post and postId are null -> blank page
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
                  _buildPostCard(post),
                  // ── Section divider ──
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: Divider(height: 1, color: Color(0xFFCAC4D0)),
                  ),
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

  // ── Post card ──

  Widget _buildPostCard(Post post) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 4, 20, 0),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(post),
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
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: ColoredBox(color: Color(0x55CAC4D0), child: SizedBox(height: 1)),
          ),
          _buildStatsRow(post),
        ],
      ),
    );
  }

  Widget _buildCardHeader(Post post) {
    final meta = [
      formatRelativeTime(post.createdAt),
      if (post.location != null && post.location!.isNotEmpty) post.location!,
    ].join(' · ');

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => UserDetailPage(user: post.author),
              ),
            ),
            child: UserAvatar(user: post.author),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => UserDetailPage(user: post.author),
                    ),
                  ),
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
          const SizedBox(width: 8),
          UserFollowButton(targetUser: post.author),
        ],
      ),
    );
  }

  Widget _buildStatsRow(Post post) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
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
            onTap: () => _focusNode.requestFocus(),
          ),
          const SizedBox(width: 20),
          StatButton(
            icon: _collected ? Icons.bookmark : Icons.bookmark_border,
            label: '$_collectionsCount',
            color: _collected ? Colors.amber : const Color(0xFF1D1B20),
            onTap: _toggleCollect,
          ),
        ],
      ),
    );
  }

  // ── Comments ──

  Widget _buildCommentsSection() {
    return FutureBuilder<Result<List<Comment>>>(
      future: _commentsFuture,
      builder: (_, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.only(top: 24),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text('加载评论失败: ${snapshot.error}'),
          );
        }
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.only(top: 24),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        return switch (snapshot.data!) {
          Ok<List<Comment>>(:final value) => value.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 24),
                  child: Text('暂无评论'),
                )
              : Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: CommentList(
                    comments: value,
                    currentUserId: _currentUserId,
                    onDeleteRequested: (id) => _deleteComment(id),
                  ),
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

