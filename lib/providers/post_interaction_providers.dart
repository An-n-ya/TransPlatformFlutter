import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/cache/post_cache.dart';
import '../utils/result.dart';
import 'repository_providers.dart';
import 'snackbar_provider.dart';

part 'post_interaction_providers.g.dart';

/// Optimistic post mutations (like / collect / delete).
///
/// Every mutation updates the cache (SSOT) first so the UI reacts instantly,
/// then calls the repository and rolls back on failure.
@riverpod
class PostInteraction extends _$PostInteraction {
  @override
  void build() {}

  Future<void> toggleLike(int postId) async {
    final cache = ref.read(postCacheProvider.notifier);
    final previous = ref.read(postCacheProvider).getById(postId);
    if (previous == null) return;

    final wasLiked = previous.liked ?? false;
    cache.upsert(
      previous.copyWith(
        liked: !wasLiked,
        likesCount: previous.likesCount + (wasLiked ? -1 : 1),
      ),
    );

    final result = wasLiked
        ? await ref.read(postRepositoryProvider).unlikePost(postId)
        : await ref.read(postRepositoryProvider).likePost(postId);

    switch (result) {
      case Ok<void>():
        break;
      case Error<void>():
        cache.upsert(previous);
        ref.read(snackbarProvider.notifier).show('操作失败');
    }
  }

  Future<void> toggleCollect(int postId) async {
    final cache = ref.read(postCacheProvider.notifier);
    final previous = ref.read(postCacheProvider).getById(postId);
    if (previous == null) return;

    final wasCollected = previous.collected ?? false;
    cache.upsert(
      previous.copyWith(
        collected: !wasCollected,
        collectionsCount:
            previous.collectionsCount + (wasCollected ? -1 : 1),
      ),
    );

    final result = wasCollected
        ? await ref.read(postRepositoryProvider).uncollectPost(postId)
        : await ref.read(postRepositoryProvider).collectPost(postId);

    switch (result) {
      case Ok<void>():
        break;
      case Error<void>():
        cache.upsert(previous);
        ref.read(snackbarProvider.notifier).show('操作失败');
    }
  }

  /// Returns true if the delete succeeded, false otherwise.
  Future<bool> delete(int postId) async {
    final result = await ref
        .read(postRepositoryProvider)
        .deletePost(postId);
    switch (result) {
      case Ok<void>():
        // Removing the entity makes list queries skip it automatically.
        ref.read(postCacheProvider.notifier).remove(postId);
        ref.read(snackbarProvider.notifier).show('已删除');
        return true;
      case Error<void>():
        ref.read(snackbarProvider.notifier).show('删除失败');
        return false;
    }
  }
}
