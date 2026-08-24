import '../../../domain/models/comment.dart';
import '../../../domain/models/post.dart';
import '../../../utils/result.dart';
import '../../services/api/page_result.dart';

/// Data source for posts and feed.
///
/// Implementations:
/// - [PostRepositoryLocal] — hardcoded sample data for UI development
/// - [PostRepositoryRemote] — calls the backend API
abstract class PostRepository {
  /// Get the homepage feed (cursor-paginated).
  ///
  /// Omit [cursor] for the first page; pass back [CursorPage.nextCursor]
  /// for subsequent pages.
  Future<Result<CursorPage<Post>>> getFeed({int? cursor, int size = 20});

  /// Get a single post by ID.
  Future<Result<Post>> getPost(int postId);

  /// Get all posts by a specific user (paginated).
  Future<Result<List<Post>>> getUserPosts(int userId,
      {int page = 0, int size = 20});

  /// Get posts under a specific topic (paginated).
  Future<Result<List<Post>>> getPostsByTopic(int topicId,
      {int page = 0, int size = 20});

  /// Get posts liked by current user (paginated).
  Future<Result<List<Post>>> getLikedPosts({int page = 0, int size = 20});

  /// Get posts collected by current user (paginated).
  Future<Result<List<Post>>> getCollectedPosts({int page = 0, int size = 20});

  /// Create a new post.
  Future<Result<Post>> createPost({
    required String content,
    List<String>? images,
    String? location,
    List<int>? topicIds,
  });

  /// Delete a post.
  Future<Result<void>> deletePost(int postId);

  // ---- Interactions ----

  /// Like a post.
  Future<Result<void>> likePost(int postId);

  /// Unlike a post.
  Future<Result<void>> unlikePost(int postId);

  /// Get comments for a post (paginated).
  Future<Result<List<Comment>>> getPostComments(int postId,
      {int page = 0, int size = 20});

  /// Create a comment on a post.
  Future<Result<Comment>> createComment(
    int postId, {
    required String content,
  });

  /// Create a reply to a comment.
  Future<Result<Comment>> createReply(
    int commentId, {
    required String content,
    int? replyToUserId,
  });

  /// Delete a comment.
  Future<Result<void>> deleteComment(int commentId);

  /// Like a comment.
  Future<Result<void>> likeComment(int commentId);

  /// Unlike a comment.
  Future<Result<void>> unlikeComment(int commentId);

  /// Get replies for a comment (paginated).
  Future<Result<List<Comment>>> getCommentReplies(int commentId,
      {int page = 0, int size = 20});

  /// Collect a post.
  Future<Result<void>> collectPost(int postId);

  /// Uncollect a post.
  Future<Result<void>> uncollectPost(int postId);
}
