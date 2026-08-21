import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart';

import '../../data/cache/comment_cache.dart';
import '../../data/cache/post_cache.dart';
import '../../data/services/current_user_provider.dart';
import '../../domain/models/post.dart';
import '../../domain/models/user.dart';
import '../../providers/comment_mutation_providers.dart';
import '../../providers/post_providers.dart';
import '../user/user_buttons.dart';
import 'comment.dart';
import 'comment_input.dart';
import 'post_card.dart';

/// Post detail page (PostDetail-Mobile design).
///
/// Shows the post inside a white rounded card (author header, content,
/// topic chips, image grid, stats row), then the comment list below a
/// section divider, with a sticky comment input at the bottom.
///
/// Data is served from the SSOT caches: the post from [PostCache] and the
/// comments from [CommentCache]; the loader providers drive the initial
/// loading/error state and keep the caches fresh.
class PostDetailPage extends ConsumerStatefulWidget {
  final int? postId;
  final Post? post;

  const PostDetailPage({super.key, this.postId, this.post});

  @override
  ConsumerState<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends ConsumerState<PostDetailPage> {
  final _commentController = TextEditingController();
  final _focusNode = FocusNode();
  int? _currentUserId;
  bool _isFocused = false;
  bool _isSending = false;

  int? get _postId => widget.postId ?? widget.post?.id;

  @override
  void initState() {
    super.initState();
    // Make a passed-in post available in the SSOT cache without overwriting
    // newer data. Deferred so the cache is not mutated while the tree builds.
    final post = widget.post;
    if (post != null) {
      Future(() {
        if (mounted) {
          ref.read(postCacheProvider.notifier).ensure(post);
        }
      });
    }
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

  void _loadCurrentUser() {
    _currentUserId = context.read<CurrentUserProvider>().userId;
  }

  Future<void> _sendComment() async {
    final postId = _postId;
    if (postId == null) return;
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    setState(() => _isSending = true);

    // Minimal placeholder for the optimistic insert; replaced by the
    // server-returned comment on success.
    final author = User(id: _currentUserId ?? 0, username: '', nickname: '我');
    final ok = await ref.read(commentMutationProvider.notifier).create(
      postId: postId,
      content: content,
      author: author,
    );

    if (!mounted) return;
    setState(() => _isSending = false);
    if (ok) {
      _commentController.clear();
    }
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

    await ref.read(commentMutationProvider.notifier).delete(commentId);
  }

  // ── Build ──

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
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
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    final postId = _postId;
    final cached = postId != null
        ? ref.watch(postCacheProvider).getById(postId)
        : null;

    // Post available (from cache or passed in) → render content.
    if (cached != null) {
      return _buildPostContent(cached, postId!);
    }

    // Post not yet available.
    if (postId != null) {
      final asyncDetail = ref.watch(postDetailProvider(postId));
      if (asyncDetail.isLoading) {
        return const Center(child: CircularProgressIndicator());
      }
      if (asyncDetail.hasError) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('加载失败',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(_formatError(asyncDetail.error!),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 16),
              FilledButton.tonal(
                onPressed: () => ref.invalidate(postDetailProvider(postId)),
                child: const Text('重试'),
              ),
            ],
          ),
        );
      }
      return const Center(child: CircularProgressIndicator());
    }

    // Both post and postId are null -> blank page.
    return const SizedBox.shrink();
  }

  Widget _buildPostContent(Post post, int postId) {
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
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                    child: PostCard(
                      post: post,
                      openDetailOnTap: false,
                      trailing: _currentUserId == post.author.id
                          ? null
                          : UserFollowButton(targetUser: post.author),
                      onCommentTap: () => _focusNode.requestFocus(),
                      onPostDeleted: () {
                        if (mounted) Navigator.of(context).pop();
                      },
                    ),
                  ),
                  // ── Section divider ──
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: Divider(height: 1, color: Color(0xFFCAC4D0)),
                  ),
                  _buildCommentsSection(postId),
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

  // ── Comments ──

  Widget _buildCommentsSection(int postId) {
    final asyncComments = ref.watch(postCommentsProvider(postId));
    return asyncComments.when(
      loading: () => const Padding(
        padding: EdgeInsets.only(top: 24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Text('加载评论失败: $error'),
      ),
      data: (_) {
        final comments =
            ref.watch(commentCacheProvider).getByPost(postId);
        return comments.isEmpty
            ? const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 24),
                child: Text('暂无评论'),
              )
            : Padding(
                padding: const EdgeInsets.only(top: 8),
                child: CommentList(
                  comments: comments,
                  currentUserId: _currentUserId,
                  onDeleteRequested: (id) => _deleteComment(id),
                ),
              );
      },
    );
  }

  String _formatError(Object e) {
    final s = e.toString();
    final idx = s.indexOf('): ');
    return idx != -1 ? s.substring(idx + 3) : s;
  }
}
