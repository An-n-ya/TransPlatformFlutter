import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../data/repositories/auth/auth_repository.dart';
import '../data/repositories/auth/auth_repository_local.dart';
import '../data/repositories/auth/auth_repository_remote.dart';
import '../data/repositories/notification/notification_repository.dart';
import '../data/repositories/notification/notification_repository_local.dart';
import '../data/repositories/notification/notification_repository_remote.dart';
import '../data/repositories/post/post_repository.dart';
import '../data/repositories/post/post_repository_local.dart';
import '../data/repositories/post/post_repository_remote.dart';
import '../data/repositories/search/search_repository.dart';
import '../data/repositories/search/search_repository_local.dart';
import '../data/repositories/search/search_repository_remote.dart';
import '../data/repositories/topic/topic_repository.dart';
import '../data/repositories/topic/topic_repository_local.dart';
import '../data/repositories/topic/topic_repository_remote.dart';
import '../data/repositories/user/user_repository.dart';
import '../data/repositories/user/user_repository_local.dart';
import '../data/repositories/user/user_repository_remote.dart';
import '../data/services/api/api_client.dart';
import '../data/services/token_storage_service.dart';
import '../data/services/current_user_provider.dart';
import '../data/services/global_config_provider.dart';
import 'env.dart';

/// Single shared [ApiClient] used by both the provider tree and the Riverpod
/// providers, so auth tokens set on login are visible to every HTTP call.
final ApiClient sharedApiClient = ApiClient(baseUrl: Env.apiBaseUrl);

final List<SingleChildWidget> _sharedProviders = [
  Provider<TokenStorageService>(create: (_) => TokenStorageService()),
  ChangeNotifierProvider<CurrentUserProvider>(
      create: (_) => CurrentUserProvider()),
  ChangeNotifierProvider<GlobalConfigProvider>(
      create: (_) => GlobalConfigProvider(initialBaseUrl: Env.apiBaseUrl)),
  Provider<ApiClient>(create: (_) => sharedApiClient),
];

List<SingleChildWidget> get providersLocal => [
      ..._sharedProviders,
      Provider<PostRepository>(create: (_) => PostRepositoryLocal()),
      Provider<UserRepository>(create: (_) => UserRepositoryLocal()),
      Provider<AuthRepository>(create: (_) => AuthRepositoryLocal()),
      Provider<NotificationRepository>(
          create: (_) => NotificationRepositoryLocal()),
      Provider<SearchRepository>(create: (_) => SearchRepositoryLocal()),
      Provider<TopicRepository>(create: (_) => TopicRepositoryLocal()),
    ];

List<SingleChildWidget> get providersRemote => [
      ..._sharedProviders,

      ProxyProvider<ApiClient, PostRepository>(
        update: (_, api, _) => PostRepositoryRemote(apiClient: api),
      ),
      ProxyProvider<ApiClient, UserRepository>(
        update: (_, api, _) => UserRepositoryRemote(apiClient: api),
      ),
      ProxyProvider<ApiClient, AuthRepository>(
        update: (_, api, _) => AuthRepositoryRemote(apiClient: api),
      ),
      ProxyProvider<ApiClient, NotificationRepository>(
        update: (_, api, _) => NotificationRepositoryRemote(apiClient: api),
      ),
      ProxyProvider<ApiClient, SearchRepository>(
        update: (_, api, _) => SearchRepositoryRemote(apiClient: api),
      ),
      ProxyProvider<ApiClient, TopicRepository>(
        update: (_, api, _) => TopicRepositoryRemote(apiClient: api),
      ),
    ];
