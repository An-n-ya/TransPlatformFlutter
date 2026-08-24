import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/cache/post_cache.dart';
import '../../domain/models/feed_type.dart';
import '../../providers/feed_pagination_provider.dart';
import '../../providers/post_providers.dart';
import 'post_card.dart';

/// Feed page for a [FeedType] — loads the feed via [feedLoaderProvider] and
/// renders posts from the SSOT post cache.
///
/// States:
/// - Loading → [CircularProgressIndicator]
/// - Empty  → "暂无内容"
/// - Error  → message + retry button
/// - Data   → [PostFeed]
class Posts extends ConsumerWidget {
  final FeedType type;

  const Posts({super.key, this.type = FeedType.plaza});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedAsync = ref.watch(feedLoaderProvider(type));
    return feedAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _ErrorView(
        message: _formatError(error),
        onRetry: () => ref.invalidate(feedLoaderProvider(type)),
      ),
      data: (_) {
        final posts = ref.watch(postCacheProvider).getList(type.cacheKey);
        return posts.isEmpty
            ? const Center(child: Text('暂无内容'))
            : _FeedListView(type: type);
      },
    );
  }

  String _formatError(Object e) {
    final s = e.toString();
    final idx = s.indexOf('): ');
    return idx != -1 ? s.substring(idx + 3) : s;
  }
}

/// Renders the loaded feed with cursor-based infinite scroll: when the user
/// scrolls near the bottom, [feedPaginationProvider] appends the next page.
class _FeedListView extends ConsumerStatefulWidget {
  final FeedType type;

  const _FeedListView({required this.type});

  @override
  ConsumerState<_FeedListView> createState() => _FeedListViewState();
}

class _FeedListViewState extends ConsumerState<_FeedListView> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // A short first page (< viewport height) never fires scroll events, so
    // kick pagination off once after the first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) => _onScroll());
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.extentAfter < 200) {
      ref.read(feedPaginationProvider(widget.type).notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pagination = ref.watch(feedPaginationProvider(widget.type));
    final posts = ref.watch(postCacheProvider).getList(widget.type.cacheKey);
    return PostFeed(
      posts: posts,
      onRefresh: () =>
          ref.read(feedLoaderProvider(widget.type).notifier).refresh(),
      scrollController: _scrollController,
      footer: _buildFooter(pagination),
    );
  }

  Widget _buildFooter(FeedPaginationState pagination) {
    if (pagination.loadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    if (pagination.error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: TextButton.icon(
            onPressed: () =>
                ref.read(feedPaginationProvider(widget.type).notifier)
                    .loadMore(),
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('加载失败，点击重试'),
          ),
        ),
      );
    }
    if (!pagination.hasMore) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: Text(
            '没有更多了',
            style: TextStyle(color: Theme.of(context).colorScheme.outline),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
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
            Icon(
            Icons.error_outline,
            size: 48,
            color: theme.colorScheme.error,
          ),
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
