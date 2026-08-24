// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'post_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$feedLoaderHash() => r'e7803b417e503f919758ebc8773789fe88c4acac';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

abstract class _$FeedLoader
    extends BuildlessAutoDisposeAsyncNotifier<List<Post>> {
  late final FeedType type;

  FutureOr<List<Post>> build(FeedType type);
}

/// Loads the first page of a feed stream into the post cache.
///
/// One instance per [FeedType] (plaza / following / nearby). UI renders from
/// [PostCache.getList] with key `type.cacheKey`; this provider only drives the
/// initial loading/error state and keeps the SSOT fresh.
///
/// Copied from [FeedLoader].
@ProviderFor(FeedLoader)
const feedLoaderProvider = FeedLoaderFamily();

/// Loads the first page of a feed stream into the post cache.
///
/// One instance per [FeedType] (plaza / following / nearby). UI renders from
/// [PostCache.getList] with key `type.cacheKey`; this provider only drives the
/// initial loading/error state and keeps the SSOT fresh.
///
/// Copied from [FeedLoader].
class FeedLoaderFamily extends Family<AsyncValue<List<Post>>> {
  /// Loads the first page of a feed stream into the post cache.
  ///
  /// One instance per [FeedType] (plaza / following / nearby). UI renders from
  /// [PostCache.getList] with key `type.cacheKey`; this provider only drives the
  /// initial loading/error state and keeps the SSOT fresh.
  ///
  /// Copied from [FeedLoader].
  const FeedLoaderFamily();

  /// Loads the first page of a feed stream into the post cache.
  ///
  /// One instance per [FeedType] (plaza / following / nearby). UI renders from
  /// [PostCache.getList] with key `type.cacheKey`; this provider only drives the
  /// initial loading/error state and keeps the SSOT fresh.
  ///
  /// Copied from [FeedLoader].
  FeedLoaderProvider call(FeedType type) {
    return FeedLoaderProvider(type);
  }

  @override
  FeedLoaderProvider getProviderOverride(
    covariant FeedLoaderProvider provider,
  ) {
    return call(provider.type);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'feedLoaderProvider';
}

/// Loads the first page of a feed stream into the post cache.
///
/// One instance per [FeedType] (plaza / following / nearby). UI renders from
/// [PostCache.getList] with key `type.cacheKey`; this provider only drives the
/// initial loading/error state and keeps the SSOT fresh.
///
/// Copied from [FeedLoader].
class FeedLoaderProvider
    extends AutoDisposeAsyncNotifierProviderImpl<FeedLoader, List<Post>> {
  /// Loads the first page of a feed stream into the post cache.
  ///
  /// One instance per [FeedType] (plaza / following / nearby). UI renders from
  /// [PostCache.getList] with key `type.cacheKey`; this provider only drives the
  /// initial loading/error state and keeps the SSOT fresh.
  ///
  /// Copied from [FeedLoader].
  FeedLoaderProvider(FeedType type)
    : this._internal(
        () => FeedLoader()..type = type,
        from: feedLoaderProvider,
        name: r'feedLoaderProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$feedLoaderHash,
        dependencies: FeedLoaderFamily._dependencies,
        allTransitiveDependencies: FeedLoaderFamily._allTransitiveDependencies,
        type: type,
      );

  FeedLoaderProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.type,
  }) : super.internal();

  final FeedType type;

  @override
  FutureOr<List<Post>> runNotifierBuild(covariant FeedLoader notifier) {
    return notifier.build(type);
  }

  @override
  Override overrideWith(FeedLoader Function() create) {
    return ProviderOverride(
      origin: this,
      override: FeedLoaderProvider._internal(
        () => create()..type = type,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        type: type,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<FeedLoader, List<Post>>
  createElement() {
    return _FeedLoaderProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is FeedLoaderProvider && other.type == type;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, type.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin FeedLoaderRef on AutoDisposeAsyncNotifierProviderRef<List<Post>> {
  /// The parameter `type` of this provider.
  FeedType get type;
}

class _FeedLoaderProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<FeedLoader, List<Post>>
    with FeedLoaderRef {
  _FeedLoaderProviderElement(super.provider);

  @override
  FeedType get type => (origin as FeedLoaderProvider).type;
}

String _$postDetailHash() => r'fb832e9a598d50bf120f43a15ae215e8a1d123ea';

abstract class _$PostDetail extends BuildlessAutoDisposeAsyncNotifier<Post> {
  late final int postId;

  FutureOr<Post> build(int postId);
}

/// Loads a single post. Serves from the cache (SSOT) when available.
///
/// Copied from [PostDetail].
@ProviderFor(PostDetail)
const postDetailProvider = PostDetailFamily();

/// Loads a single post. Serves from the cache (SSOT) when available.
///
/// Copied from [PostDetail].
class PostDetailFamily extends Family<AsyncValue<Post>> {
  /// Loads a single post. Serves from the cache (SSOT) when available.
  ///
  /// Copied from [PostDetail].
  const PostDetailFamily();

  /// Loads a single post. Serves from the cache (SSOT) when available.
  ///
  /// Copied from [PostDetail].
  PostDetailProvider call(int postId) {
    return PostDetailProvider(postId);
  }

  @override
  PostDetailProvider getProviderOverride(
    covariant PostDetailProvider provider,
  ) {
    return call(provider.postId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'postDetailProvider';
}

/// Loads a single post. Serves from the cache (SSOT) when available.
///
/// Copied from [PostDetail].
class PostDetailProvider
    extends AutoDisposeAsyncNotifierProviderImpl<PostDetail, Post> {
  /// Loads a single post. Serves from the cache (SSOT) when available.
  ///
  /// Copied from [PostDetail].
  PostDetailProvider(int postId)
    : this._internal(
        () => PostDetail()..postId = postId,
        from: postDetailProvider,
        name: r'postDetailProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$postDetailHash,
        dependencies: PostDetailFamily._dependencies,
        allTransitiveDependencies: PostDetailFamily._allTransitiveDependencies,
        postId: postId,
      );

  PostDetailProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.postId,
  }) : super.internal();

  final int postId;

  @override
  FutureOr<Post> runNotifierBuild(covariant PostDetail notifier) {
    return notifier.build(postId);
  }

  @override
  Override overrideWith(PostDetail Function() create) {
    return ProviderOverride(
      origin: this,
      override: PostDetailProvider._internal(
        () => create()..postId = postId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        postId: postId,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<PostDetail, Post> createElement() {
    return _PostDetailProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PostDetailProvider && other.postId == postId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, postId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin PostDetailRef on AutoDisposeAsyncNotifierProviderRef<Post> {
  /// The parameter `postId` of this provider.
  int get postId;
}

class _PostDetailProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<PostDetail, Post>
    with PostDetailRef {
  _PostDetailProviderElement(super.provider);

  @override
  int get postId => (origin as PostDetailProvider).postId;
}

String _$postCommentsHash() => r'6c5f56bb8c8d7afb4578a2ba98e327a68e79bdbd';

abstract class _$PostComments
    extends BuildlessAutoDisposeAsyncNotifier<List<Comment>> {
  late final int postId;

  FutureOr<List<Comment>> build(int postId);
}

/// Loads the comments of a post into the comment cache.
///
/// UI renders from [CommentCache.getByPost]; this provider drives the initial
/// loading/error state.
///
/// Copied from [PostComments].
@ProviderFor(PostComments)
const postCommentsProvider = PostCommentsFamily();

/// Loads the comments of a post into the comment cache.
///
/// UI renders from [CommentCache.getByPost]; this provider drives the initial
/// loading/error state.
///
/// Copied from [PostComments].
class PostCommentsFamily extends Family<AsyncValue<List<Comment>>> {
  /// Loads the comments of a post into the comment cache.
  ///
  /// UI renders from [CommentCache.getByPost]; this provider drives the initial
  /// loading/error state.
  ///
  /// Copied from [PostComments].
  const PostCommentsFamily();

  /// Loads the comments of a post into the comment cache.
  ///
  /// UI renders from [CommentCache.getByPost]; this provider drives the initial
  /// loading/error state.
  ///
  /// Copied from [PostComments].
  PostCommentsProvider call(int postId) {
    return PostCommentsProvider(postId);
  }

  @override
  PostCommentsProvider getProviderOverride(
    covariant PostCommentsProvider provider,
  ) {
    return call(provider.postId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'postCommentsProvider';
}

/// Loads the comments of a post into the comment cache.
///
/// UI renders from [CommentCache.getByPost]; this provider drives the initial
/// loading/error state.
///
/// Copied from [PostComments].
class PostCommentsProvider
    extends AutoDisposeAsyncNotifierProviderImpl<PostComments, List<Comment>> {
  /// Loads the comments of a post into the comment cache.
  ///
  /// UI renders from [CommentCache.getByPost]; this provider drives the initial
  /// loading/error state.
  ///
  /// Copied from [PostComments].
  PostCommentsProvider(int postId)
    : this._internal(
        () => PostComments()..postId = postId,
        from: postCommentsProvider,
        name: r'postCommentsProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$postCommentsHash,
        dependencies: PostCommentsFamily._dependencies,
        allTransitiveDependencies:
            PostCommentsFamily._allTransitiveDependencies,
        postId: postId,
      );

  PostCommentsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.postId,
  }) : super.internal();

  final int postId;

  @override
  FutureOr<List<Comment>> runNotifierBuild(covariant PostComments notifier) {
    return notifier.build(postId);
  }

  @override
  Override overrideWith(PostComments Function() create) {
    return ProviderOverride(
      origin: this,
      override: PostCommentsProvider._internal(
        () => create()..postId = postId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        postId: postId,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<PostComments, List<Comment>>
  createElement() {
    return _PostCommentsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PostCommentsProvider && other.postId == postId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, postId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin PostCommentsRef on AutoDisposeAsyncNotifierProviderRef<List<Comment>> {
  /// The parameter `postId` of this provider.
  int get postId;
}

class _PostCommentsProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<PostComments, List<Comment>>
    with PostCommentsRef {
  _PostCommentsProviderElement(super.provider);

  @override
  int get postId => (origin as PostCommentsProvider).postId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
