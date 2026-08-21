import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/cache/post_cache.dart';
import '../../providers/post_providers.dart';
import 'post_card.dart';

/// Feed page — loads the feed via [feedLoaderProvider] and renders posts
/// from the SSOT post cache.
///
/// States:
/// - Loading → [CircularProgressIndicator]
/// - Empty  → "暂无内容"
/// - Error  → message + retry button
/// - Data   → [PostFeed]
class Posts extends ConsumerWidget {
  const Posts({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedAsync = ref.watch(feedLoaderProvider);
    return feedAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _ErrorView(
        message: _formatError(error),
        onRetry: () => ref.invalidate(feedLoaderProvider),
      ),
      data: (_) {
        final posts = ref.watch(postCacheProvider).getList('feed');
        return posts.isEmpty
            ? const Center(child: Text('暂无内容'))
            : PostFeed(
                posts: posts,
                onRefresh: () =>
                    ref.read(feedLoaderProvider.notifier).refresh(),
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
