
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:trans_platform/data/repositories/post/post_repository.dart';
import 'package:trans_platform/domain/models/comment.dart' hide TopReply;
import 'package:trans_platform/ui/posts/interaction.dart';
import 'package:trans_platform/ui/posts/post_card.dart';
import 'package:trans_platform/ui/posts/reply.dart';
import 'package:trans_platform/utils/result.dart';

class CommentInput extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isFocused;
  final bool isSending;
  final VoidCallback onSend;

  const CommentInput({
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

// ── Comment list ──
class CommentList extends StatelessWidget {
  final List<Comment> comments;
  final int? currentUserId;
  final ValueChanged<int>? onDeleteRequested;

  const CommentList({
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

  const _CommentTile({required this.comment, this.isMe = false, this.onDelete});

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
                          Icon(
                            Icons.delete_outline,
                            size: 20,
                            color: Colors.red,
                          ),
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
        if (widget.comment.topReply != null)
          Padding(
            padding: const EdgeInsets.only(left: 72, top: 8, right: 16),
            child: TopReply(comment: widget.comment),
          ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(left: 60),
          child: Row(
            children: [
              PostActionBtn(
                icon: _liked ? Icons.favorite : Icons.favorite_border,
                label: '$_likesCount',
                color: _liked ? Colors.red : null,
                onPressed: _toggleLike,
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () {},
                child: Text(
                  '回复',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}