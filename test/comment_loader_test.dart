import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:trans_platform/data/cache/comment_cache.dart';
import 'package:trans_platform/data/repositories/post/post_repository.dart';
import 'package:trans_platform/domain/models/comment.dart';
import 'package:trans_platform/domain/models/user.dart';
import 'package:trans_platform/providers/post_providers.dart';
import 'package:trans_platform/providers/repository_providers.dart';
import 'package:trans_platform/utils/result.dart';

/// Repository whose getPostComments returns two comments.
class _CommentsRepo extends PostRepository {
  @override
  Future<Result<List<Comment>>> getPostComments(int postId,
      {int page = 0, int size = 20}) async {
    return Result.ok([
      Comment(
        id: 101,
        postId: postId,
        author: const User(id: 2, username: 'b', nickname: 'Bob'),
        content: 'first',
        createdAt: DateTime(2026, 1, 1),
      ),
      Comment(
        id: 102,
        postId: postId,
        author: const User(id: 3, username: 'c', nickname: 'Carol'),
        content: 'second',
        createdAt: DateTime(2026, 1, 2),
      ),
    ]);
  }

  // Remaining interface members are unused by this test.
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('PostComments loader populates the comment cache', () async {
    final container = ProviderContainer(
      overrides: [postRepositoryProvider.overrideWithValue(_CommentsRepo())],
    );
    addTearDown(container.dispose);

    final comments = await container.read(postCommentsProvider(7).future);
    expect(comments, hasLength(2));

    final cached = container.read(commentCacheProvider).getByPost(7);
    expect(cached, hasLength(2), reason: 'cache should hold the fetched comments');
    expect(cached.map((c) => c.content), ['first', 'second']);
  });
}
