import '../../../domain/models/user.dart';
import '../../../utils/result.dart';
import '../../services/api/api_client.dart';
import '../../services/api/page_result.dart';
import 'user_repository.dart';

/// Remote implementation of [UserRepository].
class UserRepositoryRemote implements UserRepository {
  final ApiClient _api;

  UserRepositoryRemote({required ApiClient apiClient}) : _api = apiClient;

  @override
  Future<Result<User>> getCurrentUser() async {
    return _api.get<User>(
      '/api/v1/users/me',
      fromData: (data) => User.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Result<User>> getUser(int userId) async {
    return _api.get<User>(
      '/api/v1/users/$userId',
      fromData: (data) => User.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Result<User>> updateUser({
    String? nickname,
    String? avatar,
    String? bio,
  }) async {
    final fields = <String, String>{};
    if (nickname != null) fields['nickname'] = nickname;
    if (bio != null) fields['bio'] = bio;

    return _api.putMultipart<User>(
      '/api/v1/users/me',
      fields: fields,
      avatarPath: avatar,
      fromData: (data) => User.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Result<void>> follow(int userId) async {
    return _api.post<void>('/api/v1/users/$userId/follow');
  }

  @override
  Future<Result<void>> unfollow(int userId) async {
    return _api.delete<void>('/api/v1/users/$userId/follow');
  }

  @override
  Future<Result<List<User>>> getFollowers(int userId,
      {int page = 0, int size = 20}) async {
    final result = await _api.getPage<User>(
      '/api/v1/users/$userId/followers',
      queryParams: {
        'page': page.toString(),
        'size': size.toString(),
      },
      fromItem: (data) => User.fromJson(data as Map<String, dynamic>),
    );
    switch (result) {
      case Ok<PageResult<User>>():
        return Result.ok(result.value.content);
      case Error<PageResult<User>>():
        return Result.error(result.error);
    }
  }

  @override
  Future<Result<List<User>>> getFollowees(int userId,
      {int page = 0, int size = 20}) async {
    final result = await _api.getPage<User>(
      '/api/v1/users/$userId/followees',
      queryParams: {
        'page': page.toString(),
        'size': size.toString(),
      },
      fromItem: (data) => User.fromJson(data as Map<String, dynamic>),
    );
    switch (result) {
      case Ok<PageResult<User>>():
        return Result.ok(result.value.content);
      case Error<PageResult<User>>():
        return Result.error(result.error);
    }
  }
}
