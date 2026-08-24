import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/cache/post_cache.dart';
import '../data/services/api/page_result.dart';
import '../domain/models/post.dart';
import '../utils/result.dart';
import 'repository_providers.dart';

/// Snapshot of the feed's cursor-pagination state.
///
/// - [cursor] — next page cursor (null for the first page)
/// - [hasMore] — whether a further page exists
/// - [loadingMore] — a next-page request is in flight
/// - [error] — last load-more failure (null when none)
class FeedPaginationState {
  final int? cursor;
  final bool hasMore;
  final bool loadingMore;
  final Object? error;

  const FeedPaginationState({
    this.cursor,
    this.hasMore = true,
    this.loadingMore = false,
    this.error,
  });
}

/// Drives infinite scroll on the homepage feed.
///
/// [FeedLoader] fetches the first page and calls [reset] with the returned
/// cursor; this notifier appends subsequent pages via [loadMore].
class FeedPagination extends Notifier<FeedPaginationState> {
  @override
  FeedPaginationState build() => const FeedPaginationState();

  /// Reset after the first page is (re)loaded, so subsequent [loadMore]s
  /// continue from the fresh cursor.
  void reset({int? cursor, bool hasMore = true}) {
    state = FeedPaginationState(cursor: cursor, hasMore: hasMore);
  }

  /// Fetch and append the next page. No-op while already loading, when no
  /// more pages exist, or when the first page hasn't been loaded yet.
  Future<void> loadMore() async {
    final current = state;
    if (current.loadingMore || !current.hasMore || current.cursor == null) {
      return;
    }

    state = FeedPaginationState(
      cursor: current.cursor,
      hasMore: current.hasMore,
      loadingMore: true,
    );

    final result = await ref
        .read(postRepositoryProvider)
        .getFeed(cursor: current.cursor);

    switch (result) {
      case Ok<CursorPage<Post>>(:final value):
        ref.read(postCacheProvider.notifier).appendAll('feed', value.content);
        state = FeedPaginationState(
          cursor: value.nextCursor,
          hasMore: value.hasMore,
        );
      case Error<CursorPage<Post>>(:final error):
        state = FeedPaginationState(
          cursor: current.cursor,
          hasMore: current.hasMore,
          error: error,
        );
    }
  }
}

/// Feed pagination state. Plain (non-generated) provider → keepAlive by
/// default so an in-flight [FeedPagination.loadMore] is never disposed.
final feedPaginationProvider =
    NotifierProvider<FeedPagination, FeedPaginationState>(FeedPagination.new);
