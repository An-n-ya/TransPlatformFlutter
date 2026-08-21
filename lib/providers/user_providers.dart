import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/cache/user_cache.dart';
import '../domain/models/user.dart';
import '../utils/result.dart';
import 'repository_providers.dart';

part 'user_providers.g.dart';

/// Loads a single user profile into the user cache.
///
/// Serves from the cache (SSOT) when available, otherwise fetches from the
/// repository and backfills the cache.
@riverpod
class UserDetail extends _$UserDetail {
  @override
  Future<User> build(int userId) async {
    // Already in SSOT? serve from cache without network.
    final cached = ref.read(userCacheProvider).getById(userId);
    if (cached != null) return cached;

    final result = await ref.read(userRepositoryProvider).getUser(userId);
    switch (result) {
      case Ok<User>(:final value):
        ref.read(userCacheProvider.notifier).upsert(value);
        return value;
      case Error<User>(:final error):
        throw error;
    }
  }
}

/// Loads the followers (`isFollowers: true`) or followees list of a user.
///
/// Always fetches on first build and upserts into the user cache; the UI
/// renders from [UserCache.getFollowers] / [UserCache.getFollowees].
@riverpod
class FollowList extends _$FollowList {
  @override
  Future<List<User>> build({
    required int userId,
    required bool isFollowers,
  }) async {
    final queryKey = isFollowers ? 'followers-$userId' : 'followees-$userId';
    final repo = ref.read(userRepositoryProvider);
    final result = isFollowers
        ? await repo.getFollowers(userId)
        : await repo.getFollowees(userId);
    switch (result) {
      case Ok<List<User>>(:final value):
        ref.read(userCacheProvider.notifier).upsertAll(queryKey, value);
        return value;
      case Error<List<User>>(:final error):
        throw error;
    }
  }
}
