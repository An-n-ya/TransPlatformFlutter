import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:trans_platform/data/cache/comment_cache.dart';
import 'package:trans_platform/data/cache/post_cache.dart';
import 'package:trans_platform/data/repositories/post/post_repository_local.dart';
import 'package:trans_platform/domain/models/comment.dart';
import 'package:trans_platform/domain/models/post.dart';
import 'package:trans_platform/domain/models/user.dart';
import 'package:trans_platform/providers/comment_mutation_providers.dart';
import 'package:trans_platform/providers/post_interaction_providers.dart';
import 'package:trans_platform/providers/repository_providers.dart';
import 'package:trans_platform/utils/result.dart';

/// Local repository whose interaction mutations always fail, so tests can
/// verify the optimistic update is rolled back to the pre-mutation snapshot.
class _FailingRepo extends PostRepositoryLocal {
  @override
  Future<Result<void>> likePost(int postId) async =>
      Result.error(Exception('network down'));

  @override
  Future<Result<void>> unlikePost(int postId) async =>
      Result.error(Exception('network down'));

  @override
  Future<Result<Comment>> createComment(int postId,
          {required String content}) async =>
      Result.error(Exception('network down'));
}

void main() {
  // Needed so GlobalKey.currentState (used by Snackbar.show) does not assert
  // on an uninitialized WidgetsBinding in pure unit tests.
  TestWidgetsFlutterBinding.ensureInitialized();

  ProviderContainer makeContainer() => ProviderContainer(
        overrides: [
          postRepositoryProvider.overrideWithValue(_FailingRepo()),
        ],
      );

  test('toggleLike updates the cache optimistically, then rolls back', () async {
    final container = makeContainer();
    addTearDown(container.dispose);

    container.read(postCacheProvider.notifier).upsert(
          Post(
            id: 1,
            author: const User(id: 1, username: 'u', nickname: 'N'),
            content: 'hello',
            liked: false,
            createdAt: DateTime(2026),
          ),
        );

    // Fire the mutation without awaiting it yet.
    final future = container
        .read(postInteractionProvider.notifier)
        .toggleLike(1);

    // Before the API settles, the cache already reflects the optimistic like.
    final optimistic = container.read(postCacheProvider).getById(1)!;
    expect(optimistic.liked, isTrue);
    expect(optimistic.likesCount, 1);

    await future;

    // After the failing API call, the snapshot is restored.
    final after = container.read(postCacheProvider).getById(1)!;
    expect(after.liked, isFalse);
    expect(after.likesCount, 0);
  });

  test('create comment inserts optimistically, then removes on failure', () async {
    final container = makeContainer();
    addTearDown(container.dispose);

    const postId = 1;
    final future = container
        .read(commentMutationProvider.notifier)
        .create(
          postId: postId,
          content: 'hello',
          author: const User(id: 0, username: '', nickname: 'me'),
        );

    // Before the API settles, the temporary comment is visible.
    final optimistic = container.read(commentCacheProvider).getByPost(postId);
    expect(optimistic, hasLength(1));
    expect(optimistic.single.content, 'hello');

    final succeeded = await future;
    expect(succeeded, isFalse);

    // After the failure, the temporary comment is removed.
    expect(container.read(commentCacheProvider).getByPost(postId), isEmpty);
  });
}
