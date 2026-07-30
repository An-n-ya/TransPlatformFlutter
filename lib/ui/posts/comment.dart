import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/post/post_repository.dart';
import '../../domain/models/comment.dart' hide TopReply;
import '../../utils/result.dart';
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
        if (widget.comment.topReply != null)
          Padding(
            padding: const EdgeInsets.only(left: 72, top: 8, right: 16),
            child: TopReply(comment: widget.comment),
          ),
      ],
    );
  }
}
