import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/cache/comment_cache.dart';
import '../domain/models/comment.dart';
import '../domain/models/user.dart';
import '../utils/result.dart';
import 'repository_providers.dart';
import 'snackbar_provider.dart';

part 'comment_mutation_providers.g.dart';

/// Optimistic comment mutations (create / delete / like).
///
/// Mutations update the comment cache (SSOT) first, then call the repository
/// and roll back on failure.
@riverpod
class CommentMutation extends _$CommentMutation {
  @override
  void build() {}

  /// Create a comment with an optimistic insert.
  ///
  /// [author] is used for the temporary placeholder and is replaced by the
  /// server-returned comment on success. Returns true on success.
  Future<bool> create({
    required int postId,
    required String content,
    required User author,
  }) async {
    final repo = ref.read(postRepositoryProvider);
    final cache = ref.read(commentCacheProvider.notifier);

    // Optimistic: insert a temporary comment with a unique negative id.
    final tempId = DateTime.now().millisecondsSinceEpoch * -1;
    final temp = Comment(
      id: tempId,
      postId: postId,
      author: author,
      content: content,
      createdAt: DateTime.now(),
    );
    cache.upsertForPost(
      postId,
      [...ref.read(commentCacheProvider).getByPost(postId), temp],
    );

    final result = await repo.createComment(postId, content: content);
    switch (result) {
      case Ok<Comment>(:final value):
        cache.remove(tempId);
        cache.upsertForPost(
          postId,
          [...ref.read(commentCacheProvider).getByPost(postId), value],
        );
        return true;
      case Error<Comment>():
        cache.remove(tempId);
        ref.read(snackbarProvider.notifier).show('评论发送失败');
        return false;
    }
  }

  Future<void> delete(int commentId) async {
    final repo = ref.read(postRepositoryProvider);
    final cache = ref.read(commentCacheProvider.notifier);
    final previous = ref.read(commentCacheProvider).getById(commentId);
    if (previous == null) return;

    cache.remove(commentId);

    final result = await repo.deleteComment(commentId);
    switch (result) {
      case Ok<void>():
        ref.read(snackbarProvider.notifier).show('评论已删除');
        break;
      case Error<void>():
        cache.upsert(previous);
        ref.read(snackbarProvider.notifier).show('删除失败');
    }
  }

  Future<void> toggleLike(int commentId) async {
    final repo = ref.read(postRepositoryProvider);
    final cache = ref.read(commentCacheProvider.notifier);
    final previous = ref.read(commentCacheProvider).getById(commentId);
    if (previous == null) return;

    final wasLiked = previous.liked ?? false;
    cache.upsert(
      previous.copyWith(
        liked: !wasLiked,
        likesCount: previous.likesCount + (wasLiked ? -1 : 1),
      ),
    );

    final result = wasLiked
        ? await repo.unlikeComment(commentId)
        : await repo.likeComment(commentId);

    switch (result) {
      case Ok<void>():
        break;
      case Error<void>():
        cache.upsert(previous);
        ref.read(snackbarProvider.notifier).show('操作失败');
    }
  }
}
