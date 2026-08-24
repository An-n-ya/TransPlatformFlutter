import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/models/post.dart';

part 'post_cache.g.dart';

/// Immutable snapshot of the post cache (Single Source of Truth for Post entities).
class PostCacheState {
  /// Normalized posts: postId → Post.
  final Map<int, Post> posts;

  /// Ordered post IDs per list-query key (e.g. 'feed', 'user-1', 'topic-2').
  final Map<String, List<int>> listQueries;

  const PostCacheState({
    this.posts = const {},
    this.listQueries = const {},
  });

  /// Read-only lookup for a single post.
  Post? getById(int id) => posts[id];

  /// Read-only ordered list for a query key (missing entities are skipped).
  List<Post> getList(String queryKey) => (listQueries[queryKey] ?? const [])
      .map((id) => posts[id])
      .whereType<Post>()
      .toList();

  PostCacheState copyWith({
    Map<int, Post>? posts,
    Map<String, List<int>>? listQueries,
  }) {
    return PostCacheState(
      posts: posts ?? this.posts,
      listQueries: listQueries ?? this.listQueries,
    );
  }
}

/// In-memory Single Source of Truth for Post entities.
///
/// All read/write of Post data must go through this cache:
/// - Loaders upsert results after fetching from the repository.
/// - Mutation notifiers update the cache optimistically and roll back on failure.
///
/// keepAlive: the cache must survive for the whole app session. If it were
/// autoDispose, loaders writing into it during their await would lose the
/// data the moment their temporary dependency is released.
@Riverpod(keepAlive: true)
class PostCache extends _$PostCache {
  @override
  PostCacheState build() => const PostCacheState();

  /// Upsert a single post (used by loaders and optimistic mutations).
  void upsert(Post post) {
    state = state.copyWith(posts: {...state.posts, post.id: post});
  }

  /// Insert [post] only if it is not already cached, without overwriting
  /// newer data (used when a widget first displays a post).
  void ensure(Post post) {
    if (!state.posts.containsKey(post.id)) {
      state = state.copyWith(posts: {...state.posts, post.id: post});
    }
  }

  /// Bulk upsert posts and record the ordered list under [queryKey].
  void upsertAll(String queryKey, List<Post> posts) {
    final newPosts = {...state.posts};
    for (final p in posts) {
      newPosts[p.id] = p;
    }
    state = state.copyWith(
      posts: newPosts,
      listQueries: {
        ...state.listQueries,
        queryKey: posts.map((p) => p.id).toList(),
      },
    );
  }

  /// Append a page of posts to an existing list query (cursor pagination),
  /// deduplicating by id. Entities are upserted so cards stay fresh.
  void appendAll(String queryKey, List<Post> posts) {
    if (posts.isEmpty) return;
    final newPosts = {...state.posts};
    for (final p in posts) {
      newPosts[p.id] = p;
    }
    final existing = state.listQueries[queryKey] ?? const <int>[];
    final appended =
        posts.map((p) => p.id).where((id) => !existing.contains(id));
    state = state.copyWith(
      posts: newPosts,
      listQueries: {
        ...state.listQueries,
        queryKey: [...existing, ...appended],
      },
    );
  }

  void remove(int id) {
    final newPosts = {...state.posts}..remove(id);
    state = state.copyWith(posts: newPosts);
  }

  /// Drop a cached list query so the next read re-fetches from the repository.
  void dropListQuery(String queryKey) {
    state = state.copyWith(
      listQueries: {...state.listQueries}..remove(queryKey),
    );
  }
}
