// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_cache.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$userCacheHash() => r'168740f836bb54906d5ff27c4bfb1ae6d586e150';

/// In-memory Single Source of Truth for User entities.
///
/// All read/write of User data must go through this cache:
/// - Loaders upsert results after fetching from the repository.
/// - The follow relationship (who the current user follows) is held by
///   `FollowRelations` in follow_mutation_providers.dart, keyed by user ID.
///
/// keepAlive: the cache must survive for the whole app session. If it were
/// autoDispose, loaders writing into it during their await would lose the
/// data the moment their temporary dependency is released.
///
/// Copied from [UserCache].
@ProviderFor(UserCache)
final userCacheProvider = NotifierProvider<UserCache, UserCacheState>.internal(
  UserCache.new,
  name: r'userCacheProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$userCacheHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$UserCache = Notifier<UserCacheState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
