import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/post/post_repository.dart';
import '../../domain/models/post.dart';
import '../../utils/result.dart';
import 'post_card.dart';

/// Feed page — loads posts from [PostRepository] and renders them as cards.
///
/// States:
/// - Loading → [CircularProgressIndicator]
/// - Empty  → "暂无内容"
/// - Error  → message + retry button
/// - Data   → [PostFeed]
class Posts extends StatefulWidget {
  const Posts({super.key});

  @override
  State<Posts> createState() => _PostsState();
}

class _PostsState extends State<Posts> {
  late Future<Result<List<Post>>> _feedFuture;

  @override
  void initState() {
    super.initState();
    _loadFeed();
  }

  void _loadFeed() {
    _feedFuture = context.read<PostRepository>().getFeed();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Result<List<Post>>>(
      future: _feedFuture,
      builder: (_, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        return switch (snapshot.data!) {
          Ok<List<Post>>(:final value) => value.isEmpty
              ? const Center(child: Text('暂无内容'))
              : PostFeed(posts: value),
          Error<List<Post>>(:final error) => _ErrorView(
              message: _formatError(error),
              onRetry: () => setState(_loadFeed),
            ),
        };
      },
    );
  }

  String _formatError(Exception e) {
    final s = e.toString();
    final idx = s.indexOf('): ');
    return idx != -1 ? s.substring(idx + 3) : s;
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('加载失败', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall),
            const SizedBox(height: 16),
            FilledButton.tonal(onPressed: onRetry, child: const Text('重试')),
          ],
        ),
      ),
    );
  }
}
