import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/cache/comment_cache.dart';
import '../../domain/models/comment.dart' hide TopReply;
import '../../providers/comment_mutation_providers.dart';
import 'interaction.dart';
import 'post_card.dart';
import 'reply.dart';

// ── Comment list ──

class CommentList extends StatelessWidget {
  final List<Comment> comments;
  final int? currentUserId;
  final ValueChanged<int>? onDeleteRequested;

  const CommentList({
    super.key,
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

class _CommentTile extends ConsumerStatefulWidget {
  final Comment comment;
  final bool isMe;
  final VoidCallback? onDelete;

  const _CommentTile({required this.comment, this.isMe = false, this.onDelete});

  @override
  ConsumerState<_CommentTile> createState() => _CommentTileState();
}

class _CommentTileState extends ConsumerState<_CommentTile> {
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
    final comment =
        ref.watch(commentCacheProvider).getById(widget.comment.id) ??
        widget.comment;
    final liked = comment.liked ?? false;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PostHeader(
          user: comment.author,
          createdAt: comment.createdAt,
          trailing: widget.isMe
              ? PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onSelected: (value) {
                    if (value == 'delete') widget.onDelete?.call();
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_outline,
                            size: 20,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '删除',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
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
          child: Text(comment.content),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(left: 72),
          child: Row(
            children: [
              PostActionBtn(
                icon: liked ? Icons.favorite : Icons.favorite_border,
                label: '${comment.likesCount}',
                color: liked
                    ? Theme.of(context).colorScheme.error
                    : null,
                onPressed: _toggleLike,
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => showModalBottomSheet(
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
                child: Text(
                  '回复',
                  style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
        if (comment.topReply != null)
          Padding(
            padding: const EdgeInsets.only(left: 72, top: 8, right: 16),
            child: TopReply(comment: comment),
          ),
      ],
    );
  }
}
