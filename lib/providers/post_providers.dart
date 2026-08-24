import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/cache/comment_cache.dart';
import '../data/cache/post_cache.dart';
import '../data/services/api/page_result.dart';
import '../domain/models/comment.dart';
import '../domain/models/post.dart';
import '../utils/result.dart';
import 'repository_providers.dart';

part 'post_providers.g.dart';

/// Loads the homepage feed into the post cache.
///
/// UI renders from [PostCache.getList] with key 'feed'; this provider only
/// drives the initial loading/error state and keeps the SSOT fresh.
@riverpod
class FeedLoader extends _$FeedLoader {
  @override
  Future<List<Post>> build() async {
    final result = await ref.read(postRepositoryProvider).getFeed();
    switch (result) {
      case Ok<CursorPage<Post>>(:final value):
        ref.read(postCacheProvider.notifier).upsertAll('feed', value.content);
        return value.content;
      case Error<CursorPage<Post>>(:final error):
        throw error;
    }
  }

  /// Pull-to-refresh: re-fetch the feed and refresh the cache.
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final result = await ref.read(postRepositoryProvider).getFeed();
      switch (result) {
        case Ok<CursorPage<Post>>(:final value):
          ref.read(postCacheProvider.notifier).upsertAll('feed', value.content);
          return value.content;
        case Error<CursorPage<Post>>(:final error):
          throw error;
      }
    });
  }
}

/// Loads a single post. Serves from the cache (SSOT) when available.
@riverpod
class PostDetail extends _$PostDetail {
  @override
  Future<Post> build(int postId) async {
    // Already in SSOT? serve from cache without network.
    final cached = ref.read(postCacheProvider).getById(postId);
    if (cached != null) return cached;

    final result = await ref.read(postRepositoryProvider).getPost(postId);
    switch (result) {
      case Ok<Post>(:final value):
        ref.read(postCacheProvider.notifier).upsert(value);
        return value;
      case Error<Post>(:final error):
        throw error;
    }
  }
}

/// Loads the comments of a post into the comment cache.
///
/// UI renders from [CommentCache.getByPost]; this provider drives the initial
/// loading/error state.
@riverpod
class PostComments extends _$PostComments {
  @override
  Future<List<Comment>> build(int postId) async {
    final result = await ref
        .read(postRepositoryProvider)
        .getPostComments(postId);
    switch (result) {
      case Ok<List<Comment>>(:final value):
        ref.read(commentCacheProvider.notifier).upsertForPost(postId, value);
        return value;
      case Error<List<Comment>>(:final error):
        throw error;
    }
  }
}
