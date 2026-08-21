// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'repository_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$repositoryModeHash() => r'742b7733ba00abf46aada2c95ff6b72d380c2d2c';

/// Selects the repository implementation.
/// Defaults to [RepositoryMode.local]; overridden in main_remote.dart.
///
/// Copied from [repositoryMode].
@ProviderFor(repositoryMode)
final repositoryModeProvider = AutoDisposeProvider<RepositoryMode>.internal(
  repositoryMode,
  name: r'repositoryModeProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$repositoryModeHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef RepositoryModeRef = AutoDisposeProviderRef<RepositoryMode>;
String _$apiClientHash() => r'86b68babc5f3f0c556b45abf296bacb4ed2308dd';

/// Shared HTTP client used in remote mode.
///
/// Reuses [sharedApiClient] (the same instance registered in the provider
/// tree) so the auth tokens set on login are present on every request.
///
/// Copied from [apiClient].
@ProviderFor(apiClient)
final apiClientProvider = AutoDisposeProvider<ApiClient>.internal(
  apiClient,
  name: r'apiClientProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$apiClientHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ApiClientRef = AutoDisposeProviderRef<ApiClient>;
String _$postRepositoryHash() => r'939801d58a0ac207540adc944e0e249706481da7';

/// [PostRepository] resolved from [RepositoryMode].
///
/// Copied from [postRepository].
@ProviderFor(postRepository)
final postRepositoryProvider = AutoDisposeProvider<PostRepository>.internal(
  postRepository,
  name: r'postRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$postRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PostRepositoryRef = AutoDisposeProviderRef<PostRepository>;
String _$userRepositoryHash() => r'bfe70162224f52f2722c8fc0465750cae894d1f4';

/// [UserRepository] resolved from [RepositoryMode].
///
/// Copied from [userRepository].
@ProviderFor(userRepository)
final userRepositoryProvider = AutoDisposeProvider<UserRepository>.internal(
  userRepository,
  name: r'userRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$userRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef UserRepositoryRef = AutoDisposeProviderRef<UserRepository>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
