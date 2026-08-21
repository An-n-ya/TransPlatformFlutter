import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../utils/result.dart';
import 'repository_providers.dart';
import 'snackbar_provider.dart';
import 'user_providers.dart';

part 'follow_mutation_providers.g.dart';

/// Immutable snapshot of the current user's follow relationships.
class FollowRelationsState {
  /// IDs of the users the current user follows.
  final Set<int> followeeIds;

  /// Whether the followee list has been loaded at least once.
  final bool loaded;

  const FollowRelationsState({
    this.followeeIds = const {},
    this.loaded = false,
  });

  bool isFollowing(int userId) => followeeIds.contains(userId);

  FollowRelationsState copyWith({Set<int>? followeeIds, bool? loaded}) {
    return FollowRelationsState(
      followeeIds: followeeIds ?? this.followeeIds,
      loaded: loaded ?? this.loaded,
    );
  }
}

/// Single Source of Truth for "who the current user follows".
///
/// The followee list is loaded once per session (through [followListProvider]
/// so the user cache is populated too) and held here for instant follow-state
/// lookups anywhere in the app.
@Riverpod(keepAlive: true)
class FollowRelations extends _$FollowRelations {
  Future<void>? _inflight;

  @override
  FollowRelationsState build() => const FollowRelationsState();

  /// Load the followee list once. Safe to call from multiple widgets.
  Future<void> ensureLoaded(int currentUserId) {
    if (state.loaded) return Future.value();
    return _inflight ??= _load(currentUserId);
  }

  Future<void> _load(int currentUserId) async {
    try {
      final users = await ref.read(
        followListProvider(userId: currentUserId, isFollowers: false).future,
      );
      state = FollowRelationsState(
        followeeIds: users.map((u) => u.id).toSet(),
        loaded: true,
      );
    } catch (_) {
      // Fall back to "not following" and mark loaded so the UI never spins
      // forever; a later visit to a fresh provider state can retry.
      state = const FollowRelationsState(loaded: true);
    } finally {
      _inflight = null;
    }
  }

  bool isFollowing(int userId) => state.isFollowing(userId);

  void add(int userId) {
    if (!state.followeeIds.contains(userId)) {
      state = state.copyWith(followeeIds: {...state.followeeIds, userId});
    }
  }

  void remove(int userId) {
    if (state.followeeIds.contains(userId)) {
      state =
          state.copyWith(followeeIds: {...state.followeeIds}..remove(userId));
    }
  }
}

/// Optimistic follow / unfollow mutations.
///
/// The follow relationship is updated in [FollowRelations] first so every
/// follow button in the app rebuilds instantly; on failure it rolls back to
/// the pre-mutation snapshot and shows an error.
@riverpod
class FollowMutation extends _$FollowMutation {
  @override
  void build() {}

  Future<void> toggleFollow(int targetUserId) async {
    final relations = ref.read(followRelationsProvider.notifier);
    final wasFollowing = relations.isFollowing(targetUserId);

    // Optimistic update → UI rebuilds automatically.
    if (wasFollowing) {
      relations.remove(targetUserId);
    } else {
      relations.add(targetUserId);
    }

    final result = wasFollowing
        ? await ref.read(userRepositoryProvider).unfollow(targetUserId)
        : await ref.read(userRepositoryProvider).follow(targetUserId);

    switch (result) {
      case Ok<void>():
        ref
            .read(snackbarProvider.notifier)
            .show(wasFollowing ? '已取消关注' : '已关注');
      case Error<void>():
        // Roll back to the snapshot.
        if (wasFollowing) {
          relations.add(targetUserId);
        } else {
          relations.remove(targetUserId);
        }
        ref.read(snackbarProvider.notifier).show('操作失败');
    }
  }
}
