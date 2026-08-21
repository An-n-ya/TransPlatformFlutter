import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/models/comment.dart';

part 'comment_cache.g.dart';

/// Immutable snapshot of the comment cache (SSOT for Comment entities).
class CommentCacheState {
  /// Normalized comments: commentId → Comment.
  final Map<int, Comment> comments;

  /// Ordered comment IDs per post key (e.g. 'post-1').
  final Map<String, List<int>> listQueries;

  const CommentCacheState({
    this.comments = const {},
    this.listQueries = const {},
  });

  /// Read-only lookup for a single comment.
  Comment? getById(int id) => comments[id];

  /// Read-only ordered list for a query key (missing entities are skipped).
  List<Comment> getList(String queryKey) => (listQueries[queryKey] ?? const [])
      .map((id) => comments[id])
      .whereType<Comment>()
      .toList();

  /// Read-only comments of a post.
  List<Comment> getByPost(int postId) => getList('post-$postId');

  CommentCacheState copyWith({
    Map<int, Comment>? comments,
    Map<String, List<int>>? listQueries,
  }) {
    return CommentCacheState(
      comments: comments ?? this.comments,
      listQueries: listQueries ?? this.listQueries,
    );
  }
}

/// In-memory Single Source of Truth for Comment entities.
///
/// Top-level comments and replies share this cache; list queries are keyed
/// by `'post-$postId'` for a post's comments and `'replies-$commentId'` for
/// a comment's replies.
///
/// keepAlive: the cache must survive for the whole app session. If it were
/// autoDispose, loaders writing into it during their await would lose the
/// data the moment their temporary dependency is released.
@Riverpod(keepAlive: true)
class CommentCache extends _$CommentCache {
  @override
  CommentCacheState build() => const CommentCacheState();

  /// Upsert a single comment (used by loaders and optimistic mutations).
  void upsert(Comment comment) {
    state = state.copyWith(comments: {...state.comments, comment.id: comment});
  }

  /// Insert [comment] only if it is not already cached, without overwriting
  /// newer data (used when a widget first displays a comment).
  void ensure(Comment comment) {
    if (!state.comments.containsKey(comment.id)) {
      state = state.copyWith(comments: {...state.comments, comment.id: comment});
    }
  }

  /// Bulk upsert comments and record the list under `'post-$postId'`.
  void upsertForPost(int postId, List<Comment> comments) {
    final newComments = {...state.comments};
    for (final c in comments) {
      newComments[c.id] = c;
    }
    state = state.copyWith(
      comments: newComments,
      listQueries: {
        ...state.listQueries,
        'post-$postId': comments.map((c) => c.id).toList(),
      },
    );
  }

  void remove(int id) {
    final newComments = {...state.comments}..remove(id);
    state = state.copyWith(comments: newComments);
  }

  /// Drop a cached list query so the next read re-fetches from the repository.
  void dropListQuery(String queryKey) {
    state = state.copyWith(
      listQueries: {...state.listQueries}..remove(queryKey),
    );
  }
}
