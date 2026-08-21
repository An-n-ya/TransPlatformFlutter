import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../config/dependencies.dart';
import '../data/repositories/post/post_repository.dart';
import '../data/repositories/post/post_repository_local.dart';
import '../data/repositories/post/post_repository_remote.dart';
import '../data/repositories/user/user_repository.dart';
import '../data/repositories/user/user_repository_local.dart';
import '../data/repositories/user/user_repository_remote.dart';
import '../data/services/api/api_client.dart';

part 'repository_providers.g.dart';

/// Whether the app should use local (mock) or remote (API) repositories.
enum RepositoryMode { local, remote }

/// Selects the repository implementation.
/// Defaults to [RepositoryMode.local]; overridden in main_remote.dart.
@riverpod
RepositoryMode repositoryMode(RepositoryModeRef ref) => RepositoryMode.local;

/// Shared HTTP client used in remote mode.
///
/// Reuses [sharedApiClient] (the same instance registered in the provider
/// tree) so the auth tokens set on login are present on every request.
@riverpod
ApiClient apiClient(ApiClientRef ref) => sharedApiClient;

/// [PostRepository] resolved from [RepositoryMode].
@riverpod
PostRepository postRepository(PostRepositoryRef ref) {
  switch (ref.watch(repositoryModeProvider)) {
    case RepositoryMode.local:
      return PostRepositoryLocal();
    case RepositoryMode.remote:
      return PostRepositoryRemote(apiClient: ref.watch(apiClientProvider));
  }
}

/// [UserRepository] resolved from [RepositoryMode].
@riverpod
UserRepository userRepository(UserRepositoryRef ref) {
  switch (ref.watch(repositoryModeProvider)) {
    case RepositoryMode.local:
      return UserRepositoryLocal();
    case RepositoryMode.remote:
      return UserRepositoryRemote(apiClient: ref.watch(apiClientProvider));
  }
}
