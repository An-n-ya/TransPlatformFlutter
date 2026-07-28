import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../data/repositories/auth/auth_repository.dart';
import '../data/repositories/auth/auth_repository_local.dart';
import '../data/repositories/auth/auth_repository_remote.dart';
import '../data/repositories/post/post_repository.dart';
import '../data/repositories/post/post_repository_local.dart';
import '../data/repositories/post/post_repository_remote.dart';
import '../data/repositories/user/user_repository.dart';
import '../data/repositories/user/user_repository_local.dart';
import '../data/repositories/user/user_repository_remote.dart';
import '../data/services/api/api_client.dart';
import 'env.dart';

// ============================================================
// Local data mode — hardcoded sample data, no backend needed
// ============================================================

List<SingleChildWidget> get providersLocal => [
      Provider<PostRepository>(create: (_) => PostRepositoryLocal()),
      Provider<UserRepository>(create: (_) => UserRepositoryLocal()),
      Provider<AuthRepository>(create: (_) => AuthRepositoryLocal()),
    ];

// ============================================================
// Remote data mode — real API calls to the backend
// ============================================================

List<SingleChildWidget> get providersRemote => [
      // Shared HTTP client with JWT token from env
      Provider<ApiClient>(
        create: (_) => ApiClient(
          baseUrl: Env.apiBaseUrl,
          accessToken: Env.accessToken,
          refreshToken: Env.refreshToken,
        ),
      ),

      // Repositories backed by real API
      ProxyProvider<ApiClient, PostRepository>(
        update: (_, api, _) => PostRepositoryRemote(apiClient: api),
      ),
      ProxyProvider<ApiClient, UserRepository>(
        update: (_, api, _) => UserRepositoryRemote(apiClient: api),
      ),
      ProxyProvider<ApiClient, AuthRepository>(
        update: (_, api, _) => AuthRepositoryRemote(apiClient: api),
      ),
    ];
