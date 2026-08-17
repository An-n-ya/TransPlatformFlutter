import '../../../domain/models/user.dart';
import '../../../utils/result.dart';

/// Data source for user profiles and follow relationships.
abstract class UserRepository {
  /// Get the currently authenticated user's profile.
  Future<Result<User>> getCurrentUser();

  /// Get a user by their ID.
  Future<Result<User>> getUser(int userId);

  /// Check whether a username is still available for registration.
  Future<Result<bool>> checkUsername(String username);

  /// Update the current user's profile.
  Future<Result<User>> updateUser({
    String? nickname,
    String? avatar,
    String? bio,
  });

  /// Follow a user.
  Future<Result<void>> follow(int userId);

  /// Unfollow a user.
  Future<Result<void>> unfollow(int userId);

  /// Set a post as the user's pinned post.
  Future<Result<User>> setPinnedPost(int postId);

  /// Clear the user's pinned post.
  Future<Result<User>> clearPinnedPost();

  /// Get followers of a user (paginated).
  Future<Result<List<User>>> getFollowers(int userId,
      {int page = 0, int size = 20});

  /// Get followees of a user (paginated).
  Future<Result<List<User>>> getFollowees(int userId,
      {int page = 0, int size = 20});
}
