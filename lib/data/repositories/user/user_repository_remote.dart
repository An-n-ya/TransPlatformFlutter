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
  Future<Result<bool>> checkUsername(String username) async {
    return _api.get<bool>(
      '/api/v1/users/check-username',
      queryParams: {'username': username},
      fromData: _parseAvailability,
    );
  }

  /// Tolerates `true`/`false`, `{ "available": bool }` or `{ "exists": bool }`.
  bool _parseAvailability(dynamic data) {
    if (data is bool) return data;
    if (data is Map<String, dynamic>) {
      final available = data['available'];
      if (available is bool) return available;
      final exists = data['exists'];
      if (exists is bool) return !exists;
    }
    return true;
  }

  @override
  Future<Result<User>> updateUser({
    String? nickname,
    String? avatar,
    String? bio,
    String? bioHeaderImg,
  }) async {
    final fields = <String, String>{};
    if (nickname != null) fields['nickname'] = nickname;
    if (bio != null) fields['bio'] = bio;

    // avatar 和 bioHeaderImg 都是相册选中的图片文件，以 multipart 文件上传；
    // 后端已不再提供 JSON 格式的 PUT /api/v1/users/me 接口。
    return _api.putMultipart<User>(
      '/api/v1/users/me',
      fields: fields,
      avatarPath: avatar,
      bioHeaderImgPath: bioHeaderImg,
      fromData: (data) => User.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Result<void>> sendEmailVerificationCode({
    required String email,
  }) async {
    return _api.post<void>(
      '/api/v1/users/me/email/send-code',
      body: {'email': email},
    );
  }

  @override
  Future<Result<User>> verifyEmail({
    required String email,
    required String code,
  }) async {
    return _api.post<User>(
      '/api/v1/users/me/email/verify',
      body: {'email': email, 'code': code},
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
  Future<Result<User>> setPinnedPost(int postId) async {
    return _api.put<User>(
      '/api/v1/users/me/pinned-post',
      body: {'postId': postId},
      fromData: (data) => User.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Result<User>> clearPinnedPost() async {
    return _api.delete<User>(
      '/api/v1/users/me/pinned-post',
      fromData: (data) => User.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<Result<List<User>>> getFollowers(
    int userId, {
    int page = 0,
    int size = 20,
  }) async {
    final result = await _api.getPage<User>(
      '/api/v1/users/$userId/followers',
      queryParams: {'page': page.toString(), 'size': size.toString()},
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
  Future<Result<List<User>>> getFollowees(
    int userId, {
    int page = 0,
    int size = 20,
  }) async {
    final result = await _api.getPage<User>(
      '/api/v1/users/$userId/followees',
      queryParams: {'page': page.toString(), 'size': size.toString()},
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
