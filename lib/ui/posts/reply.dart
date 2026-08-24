// ── Top reply preview ──

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart';
import 'package:trans_platform/data/cache/comment_cache.dart';
import 'package:trans_platform/data/repositories/post/post_repository.dart';
import 'package:trans_platform/domain/models/comment.dart';
import 'package:trans_platform/domain/models/user.dart';
import 'package:trans_platform/providers/comment_mutation_providers.dart';
import 'package:trans_platform/ui/posts/interaction.dart';
import 'package:trans_platform/ui/posts/post_card.dart';
import 'package:trans_platform/ui/posts/comment_input.dart';
import 'package:trans_platform/utils/result.dart';

class TopReply extends StatelessWidget {
  final Comment comment;

  const TopReply({required this.comment});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final topReply = comment.topReply;
    if (topReply == null) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: DefaultTextStyle.of(
                      context,
                    ).style.copyWith(fontSize: 14, height: 20 / 14),
                    children: [
                      TextSpan(
                        text: '${topReply.nickname}:',
                        style: TextStyle(color: cs.onSurfaceVariant),
                      ),
                      const TextSpan(text: ' '),
                      TextSpan(text: topReply.content),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.favorite_border,
                    size: 14,
                    color: cs.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${topReply.likesCount}',
                    style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              IconButton(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
                color: Theme.of(context).colorScheme.primary,
                icon: const Icon(Icons.mode_comment_outlined, size: 16),
                constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                padding: EdgeInsets.zero,
                onPressed: () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  builder: (_) => SizedBox(
                    height: MediaQuery.of(context).size.height * 0.9,
                    child: ReplyDetailSheet(comment: comment),
                  ),
                ),
              ),
              Text(
                '${comment.commentsCount}',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Reply detail sheet ──

class ReplyDetailSheet extends StatefulWidget {
  final Comment comment;

  const ReplyDetailSheet({required this.comment});

  @override
  State<ReplyDetailSheet> createState() => _ReplyDetailSheetState();
}

class _ReplyDetailSheetState extends State<ReplyDetailSheet> {
  late Future<Result<List<Comment>>> _repliesFuture;

  final _inputController = TextEditingController();
  final _inputFocusNode = FocusNode();
  bool _inputFocused = false;
  bool _isSending = false;
  int? _replyToUserId;

  void _startReplyTo(User author) {
    setState(() => _replyToUserId = author.id);
    _inputFocusNode.requestFocus();
  }

  @override
  void initState() {
    super.initState();
    _repliesFuture = _loadReplies();
    _inputFocusNode.addListener(
      () => setState(() => _inputFocused = _inputFocusNode.hasFocus),
    );
  }

  @override
  void dispose() {
    _inputController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  Future<Result<List<Comment>>> _loadReplies() =>
      context.read<PostRepository>().getCommentReplies(widget.comment.id);

  Future<void> _sendReply() async {
    final content = _inputController.text.trim();
    if (content.isEmpty) return;
    setState(() => _isSending = true);

    final result = await context.read<PostRepository>().createReply(
      widget.comment.id,
      content: content,
      replyToUserId: _replyToUserId,
    );

    if (!mounted) return;
    switch (result) {
      case Ok<Comment>():
        {
          _inputController.clear();
          _repliesFuture = _loadReplies();
          setState(() {
            _replyToUserId = null;
          });
        }
      case Error<Comment>():
        {
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('发送失败')));
          }
        }
    }
    if (mounted) setState(() => _isSending = false);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Column(
            children: [
              Container(
                height: 56,
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
                child: Row(
                  children: [
                    const SizedBox(width: 48),
                    const Expanded(
                      child: Text(
                        '回复详情',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              Container(
                width: double.infinity,
                child: _ReplyDetailItem(comment: widget.comment),
              ),
              const Divider(height: 1),
              Expanded(child: _buildReplyList()),
              CommentInput(
                controller: _inputController,
                focusNode: _inputFocusNode,
                isFocused: _inputFocused,
                isSending: _isSending,
                onSend: _sendReply,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReplyList() {
    return FutureBuilder<Result<List<Comment>>>(
      future: _repliesFuture,
      builder: (_, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        return switch (snapshot.data!) {
          Ok<List<Comment>>(:final value) =>
            value.isEmpty
                ? const Center(child: Text('暂无回复'))
                : ListView(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children: value
                        .map<Widget>((r) => _ReplyDetailItem(
                              comment: r,
                              onReply: () => _startReplyTo(r.author),
                            ))
                        .toList(),
                  ),
          Error<List<Comment>>() => const Center(child: Text('加载失败')),
        };
      },
    );
  }
}

class _ReplyDetailItem extends ConsumerStatefulWidget {
  final Comment comment;
  final VoidCallback? onReply;

  const _ReplyDetailItem({required this.comment, this.onReply});

  @override
  ConsumerState<_ReplyDetailItem> createState() => _ReplyDetailItemState();
}

class _ReplyDetailItemState extends ConsumerState<_ReplyDetailItem> {
  @override
  void initState() {
    super.initState();
    // Ensure the comment exists in the SSOT cache without overwriting newer
    // data. Deferred so the cache is not mutated while the tree builds.
    final comment = widget.comment;
    Future(() {
      if (mounted) {
        ref.read(commentCacheProvider.notifier).ensure(comment);
      }
    });
  }

  Future<void> _toggleLike() async {
    await ref
        .read(commentMutationProvider.notifier)
        .toggleLike(widget.comment.id);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final comment =
        ref.watch(commentCacheProvider).getById(widget.comment.id) ??
        widget.comment;
    final liked = comment.liked ?? false;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PostHeader(
            user: comment.author,
            subtitle: Text(
              'Time and Location',
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 14),
            ),
            trailing: const Icon(Icons.more_vert, size: 20),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 72),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (comment.replyToUser != null)
                      Text(
                        '回复：${comment.replyToUser?.nickname}',
                        style: TextStyle(color: cs.secondary, fontSize: 14),
                      ),
                    Text(comment.content),
                  ],
                ),
                Row(
                  children: [
                    PostActionBtn(
                      icon: liked ? Icons.favorite : Icons.favorite_border,
                      label: '${comment.likesCount}',
                      color: liked ? cs.error : null,
                      onPressed: _toggleLike,
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: widget.onReply,
                      child: Text(
                        '回复',
                        style: TextStyle(color: cs.primary, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
