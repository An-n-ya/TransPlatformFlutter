// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'post_cache.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$postCacheHash() => r'36ca0ed9c6f94a028134e7f70dc362cd7b3a733b';

/// In-memory Single Source of Truth for Post entities.
///
/// All read/write of Post data must go through this cache:
/// - Loaders upsert results after fetching from the repository.
/// - Mutation notifiers update the cache optimistically and roll back on failure.
///
/// keepAlive: the cache must survive for the whole app session. If it were
/// autoDispose, loaders writing into it during their await would lose the
/// data the moment their temporary dependency is released.
///
/// Copied from [PostCache].
@ProviderFor(PostCache)
final postCacheProvider = NotifierProvider<PostCache, PostCacheState>.internal(
  PostCache.new,
  name: r'postCacheProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$postCacheHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$PostCache = Notifier<PostCacheState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
