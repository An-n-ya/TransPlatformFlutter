import '../../../domain/models/user.dart';
import '../../../utils/result.dart';
import 'user_repository.dart';

/// Local implementation of [UserRepository].
class UserRepositoryLocal implements UserRepository {
  @override
  Future<Result<User>> getCurrentUser() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return Result.ok(_demoUser);
  }

  @override
  Future<Result<User>> getUser(int userId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return Result.ok(_demoUser);
  }

  @override
  Future<Result<bool>> checkUsername(String username) async {
    await Future.delayed(const Duration(milliseconds: 300));
    // A few reserved names are treated as taken in the local mock.
    const taken = {'admin', 'root', 'taken', 'local'};
    return Result.ok(!taken.contains(username.toLowerCase()));
  }

  @override
  Future<Result<User>> updateUser({
    String? nickname,
    String? avatar,
    String? bio,
    String? bioHeaderImg,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return Result.ok(_demoUser);
  }

  @override
  Future<Result<void>> sendEmailVerificationCode({required String email}) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return const Result.ok(null);
  }

  @override
  Future<Result<User>> verifyEmail({
    required String email,
    required String code,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return Result.ok(_demoUser);
  }

  @override
  Future<Result<void>> follow(int userId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return Result.ok(null);
  }

  @override
  Future<Result<void>> unfollow(int userId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return Result.ok(null);
  }

  @override
  Future<Result<User>> setPinnedPost(int postId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return Result.ok(_demoUser);
  }

  @override
  Future<Result<User>> clearPinnedPost() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return Result.ok(_demoUser);
  }

  @override
  Future<Result<List<User>>> getFollowers(int userId,
      {int page = 0, int size = 20}) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return Result.ok([_demoUser]);
  }

  @override
  Future<Result<List<User>>> getFollowees(int userId,
      {int page = 0, int size = 20}) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return Result.ok([_demoUser]);
  }

  User get _demoUser => const User(
        id: 1,
        username: 'alice',
        nickname: 'Alice',
        avatar: 'assets/images/avatar.jpg',
        bio: 'Exploring the world 🌍',
        followersCount: 128,
        followeesCount: 42,
      );
}
