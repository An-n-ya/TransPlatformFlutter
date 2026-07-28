import '../../../domain/models/comment.dart';
import '../../../domain/models/post.dart';
import '../../../utils/result.dart';
import '../../services/api/api_client.dart';
import '../../services/api/page_result.dart';
import 'post_repository.dart';

/// Remote implementation of [PostRepository].
///
/// Calls the backend API at [ApiClient.baseUrl].
class PostRepositoryRemote implements PostRepository {
  final ApiClient _api;

  PostRepositoryRemote({required ApiClient apiClient}) : _api = apiClient;

  @override
  Future<Result<List<Post>>> getFeed({int page = 0, int size = 20}) async {
    final result = await _api.getPage<Post>(
      '/api/v1/feed',
      queryParams: {
        'page': page.toString(),
        'size': size.toString(),
      },
      fromItem: (data) => Post.fromJson(data as Map<String, dynamic>),
    );
    switch (result) {
      case Ok<PageResult<Post>>():
        return Result.ok(result.value.content);
      case Error<PageResult<Post>>():
        return Result.error(result.error);
    }
  }

  @override
  Future<Result<Post>> getPost(int postId) async {
    return _api.get<Post>(
      '/api/v1/posts/$postId',
      fromData: (data) => Post.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Result<List<Post>>> getUserPosts(int userId,
      {int page = 0, int size = 20}) async {
    final result = await _api.getPage<Post>(
      '/api/v1/users/$userId/posts',
      queryParams: {
        'page': page.toString(),
        'size': size.toString(),
      },
      fromItem: (data) => Post.fromJson(data as Map<String, dynamic>),
    );
    switch (result) {
      case Ok<PageResult<Post>>():
        return Result.ok(result.value.content);
      case Error<PageResult<Post>>():
        return Result.error(result.error);
    }
  }

  @override
  Future<Result<Post>> createPost({
    required String content,
    List<String>? images,
    String? location,
  }) async {
    return _api.post<Post>(
      '/api/v1/posts',
      body: {
        'content': content,
        if (images != null) 'images': images,
        if (location != null) 'location': location,
      },
      fromData: (data) => Post.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Result<void>> deletePost(int postId) async {
    return _api.delete<void>('/api/v1/posts/$postId');
  }

  @override
  Future<Result<void>> likePost(int postId) async {
    return _api.post<void>('/api/v1/posts/$postId/like');
  }

  @override
  Future<Result<void>> unlikePost(int postId) async {
    return _api.delete<void>('/api/v1/posts/$postId/like');
  }

  @override
  Future<Result<List<Comment>>> getPostComments(int postId,
      {int page = 0, int size = 20}) async {
    final result = await _api.getPage<Comment>(
      '/api/v1/posts/$postId/comments',
      queryParams: {
        'page': page.toString(),
        'size': size.toString(),
      },
      fromItem: (data) => Comment.fromJson(data as Map<String, dynamic>),
    );
    switch (result) {
      case Ok<PageResult<Comment>>():
        return Result.ok(result.value.content);
      case Error<PageResult<Comment>>():
        return Result.error(result.error);
    }
  }

  @override
  Future<Result<Comment>> createComment(int postId,
      {required String content, int? parentId, int? replyToUserId}) async {
    return _api.post<Comment>(
      '/api/v1/posts/$postId/comments',
      body: {
        'content': content,
        if (parentId != null) 'parentId': parentId,
        if (replyToUserId != null) 'replyToUserId': replyToUserId,
      },
      fromData: (data) => Comment.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Result<void>> deleteComment(int commentId) async {
    return _api.delete<void>('/api/v1/comments/$commentId');
  }

  @override
  Future<Result<void>> collectPost(int postId) async {
    return _api.post<void>('/api/v1/posts/$postId/collect');
  }

  @override
  Future<Result<void>> uncollectPost(int postId) async {
    return _api.delete<void>('/api/v1/posts/$postId/collect');
  }
}
