import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide ChangeNotifierProvider;
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:trans_platform/config/dependencies.dart';
import 'package:trans_platform/data/repositories/post/post_repository.dart';
import 'package:trans_platform/domain/models/comment.dart';
import 'package:trans_platform/domain/models/post.dart';
import 'package:trans_platform/domain/models/user.dart';
import 'package:trans_platform/providers/repository_providers.dart';
import 'package:trans_platform/ui/posts/post_detail_page.dart';
import 'package:trans_platform/utils/result.dart';

/// Repository returning a real post and two comments.
class _DetailRepo extends PostRepository {
  @override
  Future<Result<Post>> getPost(int postId) async => Result.ok(
        Post(
          id: postId,
          author: const User(id: 1, username: 'a', nickname: 'Alice'),
          content: 'post body',
          createdAt: DateTime(2026, 1, 1),
        ),
      );

  @override
  Future<Result<List<Comment>>> getPostComments(int postId,
      {int page = 0, int size = 20}) async {
    return Result.ok([
      Comment(
        id: 101,
        postId: postId,
        author: const User(id: 2, username: 'b', nickname: 'Bob'),
        content: 'first comment',
        createdAt: DateTime(2026, 1, 1),
      ),
      Comment(
        id: 102,
        postId: postId,
        author: const User(id: 3, username: 'c', nickname: 'Carol'),
        content: 'second comment',
        createdAt: DateTime(2026, 1, 2),
      ),
    ]);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('PostDetailPage renders comments from the comment cache',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          postRepositoryProvider.overrideWithValue(_DetailRepo()),
        ],
        child: MultiProvider(
          providers: providersLocal,
          child: const MaterialApp(
            home: PostDetailPage(postId: 7),
          ),
        ),
      ),
    );

    // Let the post + comments load.
    await tester.pumpAndSettle();

    // Both comments should be visible.
    expect(find.text('first comment'), findsOneWidget);
    expect(find.text('second comment'), findsOneWidget);
    expect(find.text('暂无评论'), findsNothing);
  });
}
