// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$followListHash() => r'0cc85e1ba102b96f7f4e1fd6806dc7707c4fabe7';

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

abstract class _$FollowList
    extends BuildlessAutoDisposeAsyncNotifier<List<User>> {
  late final int userId;
  late final bool isFollowers;

  FutureOr<List<User>> build({required int userId, required bool isFollowers});
}

/// Loads the followers (`isFollowers: true`) or followees list of a user.
///
/// Always fetches on first build and upserts into the user cache; the UI
/// renders from [UserCache.getFollowers] / [UserCache.getFollowees].
///
/// Copied from [FollowList].
@ProviderFor(FollowList)
const followListProvider = FollowListFamily();

/// Loads the followers (`isFollowers: true`) or followees list of a user.
///
/// Always fetches on first build and upserts into the user cache; the UI
/// renders from [UserCache.getFollowers] / [UserCache.getFollowees].
///
/// Copied from [FollowList].
class FollowListFamily extends Family<AsyncValue<List<User>>> {
  /// Loads the followers (`isFollowers: true`) or followees list of a user.
  ///
  /// Always fetches on first build and upserts into the user cache; the UI
  /// renders from [UserCache.getFollowers] / [UserCache.getFollowees].
  ///
  /// Copied from [FollowList].
  const FollowListFamily();

  /// Loads the followers (`isFollowers: true`) or followees list of a user.
  ///
  /// Always fetches on first build and upserts into the user cache; the UI
  /// renders from [UserCache.getFollowers] / [UserCache.getFollowees].
  ///
  /// Copied from [FollowList].
  FollowListProvider call({required int userId, required bool isFollowers}) {
    return FollowListProvider(userId: userId, isFollowers: isFollowers);
  }

  @override
  FollowListProvider getProviderOverride(
    covariant FollowListProvider provider,
  ) {
    return call(userId: provider.userId, isFollowers: provider.isFollowers);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'followListProvider';
}

/// Loads the followers (`isFollowers: true`) or followees list of a user.
///
/// Always fetches on first build and upserts into the user cache; the UI
/// renders from [UserCache.getFollowers] / [UserCache.getFollowees].
///
/// Copied from [FollowList].
class FollowListProvider
    extends AutoDisposeAsyncNotifierProviderImpl<FollowList, List<User>> {
  /// Loads the followers (`isFollowers: true`) or followees list of a user.
  ///
  /// Always fetches on first build and upserts into the user cache; the UI
  /// renders from [UserCache.getFollowers] / [UserCache.getFollowees].
  ///
  /// Copied from [FollowList].
  FollowListProvider({required int userId, required bool isFollowers})
    : this._internal(
        () => FollowList()
          ..userId = userId
          ..isFollowers = isFollowers,
        from: followListProvider,
        name: r'followListProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$followListHash,
        dependencies: FollowListFamily._dependencies,
        allTransitiveDependencies: FollowListFamily._allTransitiveDependencies,
        userId: userId,
        isFollowers: isFollowers,
      );

  FollowListProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.userId,
    required this.isFollowers,
  }) : super.internal();

  final int userId;
  final bool isFollowers;

  @override
  FutureOr<List<User>> runNotifierBuild(covariant FollowList notifier) {
    return notifier.build(userId: userId, isFollowers: isFollowers);
  }

  @override
  Override overrideWith(FollowList Function() create) {
    return ProviderOverride(
      origin: this,
      override: FollowListProvider._internal(
        () => create()
          ..userId = userId
          ..isFollowers = isFollowers,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        userId: userId,
        isFollowers: isFollowers,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<FollowList, List<User>>
  createElement() {
    return _FollowListProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is FollowListProvider &&
        other.userId == userId &&
        other.isFollowers == isFollowers;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, userId.hashCode);
    hash = _SystemHash.combine(hash, isFollowers.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin FollowListRef on AutoDisposeAsyncNotifierProviderRef<List<User>> {
  /// The parameter `userId` of this provider.
  int get userId;

  /// The parameter `isFollowers` of this provider.
  bool get isFollowers;
}

class _FollowListProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<FollowList, List<User>>
    with FollowListRef {
  _FollowListProviderElement(super.provider);

  @override
  int get userId => (origin as FollowListProvider).userId;
  @override
  bool get isFollowers => (origin as FollowListProvider).isFollowers;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
