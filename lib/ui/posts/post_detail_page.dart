import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/models/comment.dart';
import '../../domain/models/post.dart';
import '../../domain/models/user.dart';
import 'photo_grid.dart';

/// Post detail page.
///
/// Shows a single post expanded with full content, image grid,
/// interaction counts, and a scrollable list of comments.
/// Backend integration is intentionally left out for now.
class PostDetailPage extends StatelessWidget {
  final Post post;

  const PostDetailPage({super.key, required this.post});

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
                  _PostHeader(post: post),
                  if (post.content.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Text(post.content),
                    ),
                  if (post.images.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: PhotoGrid(images: post.images),
                    ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _InteractionBar(post: post),
                  ),
                  const Divider(height: 24),
                  _CommentList(comments: _mockComments),
                ],
              ),
            ),
          ),
          const _CommentInput(),
        ],
      ),
    );
  }
}

/// Post header with avatar, name, follow button, and timestamp.
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
              style: TextStyle(
                color: cs.onPrimaryContainer,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post.author.nickname,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatMeta(post),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          FilledButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none, size: 18),
            label: const Text('Follow'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(100),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatMeta(Post post) {
    final parts = <String>[
      DateFormat('yyyy-MM-dd HH:mm').format(post.createdAt),
    ];
    if (post.location != null && post.location!.isNotEmpty) {
      parts.add(post.location!);
    }
    return parts.join(' · ');
  }
}

/// Like / comment counts bar.
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

/// Scrollable list of comments.
class _CommentList extends StatelessWidget {
  final List<Comment> comments;

  const _CommentList({required this.comments});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: comments.length,
      separatorBuilder: (_, _) => const SizedBox(height: 16),
      itemBuilder: (_, i) => _CommentTile(comment: comments[i]),
    );
  }
}

/// Single comment row.
class _CommentTile extends StatelessWidget {
  final Comment comment;

  const _CommentTile({required this.comment});

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
            style: TextStyle(
              color: cs.onPrimaryContainer,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
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
                    child: Text(
                      comment.author.nickname,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert, size: 20),
                    onPressed: () {},
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              Text(
                DateFormat('yyyy-MM-dd HH:mm').format(comment.createdAt),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(comment.content),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.favorite_border,
                      size: 18, color: cs.onSurface),
                  const SizedBox(width: 4),
                  Text('${comment.likesCount}'),
                  const SizedBox(width: 16),
                  Icon(Icons.mode_comment_outlined,
                      size: 18, color: cs.onSurface),
                  const SizedBox(width: 4),
                  Text('${comment.replies.length}'),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Sticky comment input at the bottom.
class _CommentInput extends StatefulWidget {
  const _CommentInput();

  @override
  State<_CommentInput> createState() => _CommentInputState();
}

class _CommentInputState extends State<_CommentInput> {
  final _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    setState(() => _isFocused = _focusNode.hasFocus);
  }

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
          height: _isFocused ? 120 : 40,
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
                  focusNode: _focusNode,
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
              if (_isFocused)
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 4),
                  child: FilledButton.icon(
                    onPressed: () {},
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

final _mockComments = [
  Comment(
    id: 1,
    postId: 1,
    author: const User(id: 2, username: 'alice', nickname: 'Alice'),
    content:
        'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Donec egestas viverra tortor, vel pretium sapien mollis nec. Aliquam ac faucibus eros. Interdum et malesuada fames ac ante ipsum primis in faucibus.',
    likesCount: 100,
    createdAt: DateTime(2024, 6, 15, 10, 30),
  ),
  Comment(
    id: 2,
    postId: 1,
    author: const User(id: 3, username: 'alice', nickname: 'Alice'),
    content:
        'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Donec egestas viverra tortor, vel pretium sapien mollis nec. Aliquam ac faucibus eros. Interdum et malesuada fames ac ante ipsum primis in faucibus.',
    likesCount: 100,
    createdAt: DateTime(2024, 6, 15, 11, 0),
  ),
];
