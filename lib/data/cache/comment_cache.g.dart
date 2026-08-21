// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'comment_cache.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$commentCacheHash() => r'6acbc759c870caaaeb4c2e5fe831fa866bda40f1';

/// In-memory Single Source of Truth for Comment entities.
///
/// Top-level comments and replies share this cache; list queries are keyed
/// by `'post-$postId'` for a post's comments and `'replies-$commentId'` for
/// a comment's replies.
///
/// keepAlive: the cache must survive for the whole app session. If it were
/// autoDispose, loaders writing into it during their await would lose the
/// data the moment their temporary dependency is released.
///
/// Copied from [CommentCache].
@ProviderFor(CommentCache)
final commentCacheProvider =
    NotifierProvider<CommentCache, CommentCacheState>.internal(
      CommentCache.new,
      name: r'commentCacheProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$commentCacheHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$CommentCache = Notifier<CommentCacheState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
