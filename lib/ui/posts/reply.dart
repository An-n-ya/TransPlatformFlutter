// ── Top reply preview ──

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:trans_platform/data/repositories/post/post_repository.dart';
import 'package:trans_platform/domain/models/comment.dart';
import 'package:trans_platform/domain/models/user.dart';
import 'package:trans_platform/ui/posts/interaction.dart';
import 'package:trans_platform/ui/posts/post_card.dart';
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
                    style: DefaultTextStyle.of(context)
                        .style
                        .copyWith(fontSize: 14, height: 20 / 14),
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
                  Icon(Icons.favorite_border,
                      size: 14, color: cs.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(
                    '${topReply.likesCount}',
                    style:
                        TextStyle(fontSize: 14, color: cs.onSurfaceVariant),
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
                color: Theme.of(context).colorScheme.primary,
                icon: const Icon(Icons.mode_comment_outlined, size: 16),
                constraints:
                    const BoxConstraints(minWidth: 24, minHeight: 24),
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
                    height: MediaQuery.of(context).size.height * 0.85,
                    child: _ReplyDetailSheet(comment: comment),
                  ),
                ),
              ),
              Text(
                '${comment.commentsCount}',
                style: TextStyle(
                  fontSize: 12,
                  color:
                      Theme.of(context).colorScheme.onSurfaceVariant,
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

class _ReplyDetailSheet extends StatefulWidget {
  final Comment comment;

  const _ReplyDetailSheet({required this.comment});

  @override
  State<_ReplyDetailSheet> createState() => _ReplyDetailSheetState();
}

class _ReplyDetailSheetState extends State<_ReplyDetailSheet> {
  late Future<Result<List<Comment>>> _repliesFuture;

  @override
  void initState() {
    super.initState();
    _repliesFuture = context
        .read<PostRepository>()
        .getCommentReplies(widget.comment.id);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            height: 56,
            decoration: BoxDecoration(
              color: cs.surfaceDim,
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
              child: _ReplyDetailItem(
                author: widget.comment.author,
                content: widget.comment.content,
                likesCount: widget.comment.likesCount,
              ),
            ),
          const Divider(height: 1),
          Expanded(
            child: _buildReplyList(),
          ),
        ],
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
          Ok<List<Comment>>(:final value) => value.isEmpty
              ? const Center(child: Text('暂无回复'))
              : ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: value
                      .map((r) => _ReplyDetailItem(
                            replayToUser: r.replyToUser,
                            author: r.author,
                            content: r.content,
                            likesCount: r.likesCount,
                          ))
                      .toList(),
                ),
          Error<List<Comment>>() => const Center(child: Text('加载失败')),
        };
      },
    );
  }
}

class _ReplyDetailItem extends StatelessWidget {
  final User author;
  final User? replayToUser;
  final String content;
  final int likesCount;

  const _ReplyDetailItem({
    required this.author,
    this.replayToUser,
    required this.content,
    required this.likesCount,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PostHeader(
            user: author,
            subtitle: Text(
              'Time and Location',
              style: TextStyle(
                color: cs.onSurfaceVariant,
                fontSize: 14,
              ),
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
                if (replayToUser != null)  
                  Text('回复：${replayToUser?.nickname}', style: 
                        TextStyle(
                          color: cs.secondary,
                          fontSize: 14,
                        ),
 ),
                Text(content),
              ]),
                Row(
                  children: [
                    PostActionBtn(
                      icon: Icons.favorite_border,
                      label: '$likesCount',
                      onPressed: () {},
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () {},
                      child: Text(
                        '回复',
                        style: TextStyle(
                          color: cs.primary,
                          fontSize: 14,
                        ),
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
