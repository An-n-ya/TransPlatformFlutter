import '../../../domain/models/comment.dart';
import '../../../domain/models/post.dart';
import '../../../domain/models/user.dart';
import '../../../utils/result.dart';
import '../../services/api/page_result.dart';
import 'post_repository.dart';

/// Local implementation of [PostRepository].
///
/// Returns hardcoded sample data for UI development/test.
class PostRepositoryLocal implements PostRepository {
  @override
  Future<Result<CursorPage<Post>>> getFeed({int? cursor, int size = 20}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return Result.ok(CursorPage(content: _samplePosts, hasMore: false));
  }

  @override
  Future<Result<Post>> getPost(int postId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    try {
      return Result.ok(_samplePosts.firstWhere((p) => p.id == postId));
    } catch (_) {
      return Result.error(Exception('Post not found: $postId'));
    }
  }

  @override
  Future<Result<List<Post>>> getUserPosts(int userId,
      {int page = 0, int size = 20}) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final posts = _samplePosts.where((p) => p.author.id == userId).toList();
    return Result.ok(posts);
  }

  @override
  Future<Result<List<Post>>> getPostsByTopic(int topicId,
      {int page = 0, int size = 20}) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return Result.ok(_samplePosts.take(2).toList());
  }

  @override
  Future<Result<List<Post>>> getLikedPosts({int page = 0, int size = 20}) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return Result.ok(_samplePosts.take(2).toList());
  }

  @override
  Future<Result<List<Post>>> getCollectedPosts({int page = 0, int size = 20}) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return Result.ok(_samplePosts.take(1).toList());
  }

  @override
  Future<Result<Post>> createPost({
    required String content,
    List<String>? images,
    String? location,
    List<int>? topicIds,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return Result.ok(
      Post(
        id: DateTime.now().millisecondsSinceEpoch,
        author: _currentUser,
        content: content,
        images: images ?? [],
        location: location,
        createdAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<Result<void>> deletePost(int postId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return Result.ok(null);
  }

  @override
  Future<Result<void>> likePost(int postId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return Result.ok(null);
  }

  @override
  Future<Result<void>> unlikePost(int postId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return Result.ok(null);
  }

  @override
  Future<Result<List<Comment>>> getPostComments(int postId,
      {int page = 0, int size = 20}) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return Result.ok(_sampleComments);
  }

  @override
  Future<Result<Comment>> createComment(int postId,
      {required String content}) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return Result.ok(
      Comment(
        id: DateTime.now().millisecondsSinceEpoch,
        postId: postId,
        author: _currentUser,
        content: content,
        createdAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<Result<Comment>> createReply(int commentId,
      {required String content, int? replyToUserId}) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return Result.ok(
      Comment(
        id: DateTime.now().millisecondsSinceEpoch,
        postId: commentId,
        author: _currentUser,
        content: content,
        parentId: commentId,
        replyToUser: _currentUser,
        createdAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<Result<void>> deleteComment(int commentId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return Result.ok(null);
  }

  @override
  Future<Result<void>> likeComment(int commentId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return Result.ok(null);
  }

  @override
  Future<Result<void>> unlikeComment(int commentId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return Result.ok(null);
  }

  @override
  Future<Result<List<Comment>>> getCommentReplies(int commentId,
      {int page = 0, int size = 20}) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return Result.ok([]);
  }

  @override
  Future<Result<void>> collectPost(int postId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return Result.ok(null);
  }

  @override
  Future<Result<void>> uncollectPost(int postId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return Result.ok(null);
  }

  // ---- Sample data ----

  User get _currentUser => _sampleUsers[0];

  List<User> get _sampleUsers => const [
        User(
          id: 1,
          username: 'alice',
          nickname: 'Alice',
          avatar: 'assets/images/avatar.jpg',
          bio: 'Exploring the world 🌍',
          followersCount: 128,
          followeesCount: 42,
        ),
        User(
          id: 2,
          username: 'bob',
          nickname: 'Bob',
          avatar: 'assets/images/avatar.jpg',
          bio: 'Photography enthusiast 📷',
          followersCount: 56,
          followeesCount: 89,
        ),
        User(
          id: 3,
          username: 'charlie',
          nickname: 'Charlie',
          avatar: 'assets/images/avatar.jpg',
          bio: 'Code & Coffee ☕',
          followersCount: 12,
          followeesCount: 34,
        ),
      ];

  List<Post> get _samplePosts => [
        Post(
          id: 1,
          author: _sampleUsers[0],
          content: 'Exploring the mountains today! The weather is perfect '
              'and the scenery is breathtaking. Lorem ipsum dolor sit amet, '
              'consectetur adipiscing elit.',
          images: [
            'assets/images/image.png',
            'assets/images/image.png',
            'assets/images/image.png',
          ],
          location: 'Mountain Peak',
          likesCount: 42,
          commentsCount: 7,
          collectionsCount: 3,
          liked: true,
          collected: false,
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        ),
        Post(
          id: 2,
          author: _sampleUsers[1],
          content: 'Homemade pasta for dinner tonight! 🍝',
          images: [
            'assets/images/image.png',
            'assets/images/image.png',
          ],
          likesCount: 18,
          commentsCount: 3,
          collectionsCount: 1,
          createdAt: DateTime.now().subtract(const Duration(hours: 12)),
        ),
        Post(
          id: 3,
          author: _sampleUsers[2],
          content: 'Just finished reading a great book. Highly recommend! 📚',
          likesCount: 7,
          commentsCount: 1,
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
        Post(
          id: 4,
          author: _sampleUsers[0],
          content: 'Sunset at the beach 🌅',
          images: [
            'assets/images/image.png',
          ],
          location: 'Ocean Beach',
          likesCount: 35,
          commentsCount: 5,
          collectionsCount: 2,
          liked: true,
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
        ),
      ];

  List<Comment> get _sampleComments => [
        Comment(
          id: 1,
          postId: 1,
          author: _sampleUsers[1],
          content: 'Great view! 🎉',
          likesCount: 3,
          createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        ),
        Comment(
          id: 2,
          postId: 1,
          author: _sampleUsers[2],
          content: 'Where is this? Looks amazing!',
          likesCount: 1,
          createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
        ),
      ];
}
