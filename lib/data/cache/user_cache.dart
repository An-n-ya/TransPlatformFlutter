import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/models/user.dart';

part 'user_cache.g.dart';

/// Immutable snapshot of the user cache (Single Source of Truth for User entities).
class UserCacheState {
  /// Normalized users: userId → User.
  final Map<int, User> users;

  /// Ordered user IDs per list-query key (e.g. 'followers-1', 'followees-2').
  final Map<String, List<int>> listQueries;

  const UserCacheState({
    this.users = const {},
    this.listQueries = const {},
  });

  /// Read-only lookup for a single user.
  User? getById(int id) => users[id];

  /// Read-only ordered list for a query key (missing entities are skipped).
  List<User> getList(String queryKey) => (listQueries[queryKey] ?? const [])
      .map((id) => users[id])
      .whereType<User>()
      .toList();

  /// Read-only followers of a user.
  List<User> getFollowers(int userId) => getList('followers-$userId');

  /// Read-only followees of a user.
  List<User> getFollowees(int userId) => getList('followees-$userId');

  UserCacheState copyWith({
    Map<int, User>? users,
    Map<String, List<int>>? listQueries,
  }) {
    return UserCacheState(
      users: users ?? this.users,
      listQueries: listQueries ?? this.listQueries,
    );
  }
}

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
@Riverpod(keepAlive: true)
class UserCache extends _$UserCache {
  @override
  UserCacheState build() => const UserCacheState();

  /// Upsert a single user (used by loaders).
  void upsert(User user) {
    state = state.copyWith(users: {...state.users, user.id: user});
  }

  /// Insert [user] only if it is not already cached, without overwriting
  /// newer data (used when a widget first displays a user).
  void ensure(User user) {
    if (!state.users.containsKey(user.id)) {
      state = state.copyWith(users: {...state.users, user.id: user});
    }
  }

  /// Bulk upsert users and record the ordered list under [queryKey].
  void upsertAll(String queryKey, List<User> users) {
    final newUsers = {...state.users};
    for (final u in users) {
      newUsers[u.id] = u;
    }
    state = state.copyWith(
      users: newUsers,
      listQueries: {
        ...state.listQueries,
        queryKey: users.map((u) => u.id).toList(),
      },
    );
  }

  void remove(int id) {
    final newUsers = {...state.users}..remove(id);
    state = state.copyWith(users: newUsers);
  }

  /// Drop a cached list query so the next read re-fetches from the repository.
  void dropListQuery(String queryKey) {
    state = state.copyWith(
      listQueries: {...state.listQueries}..remove(queryKey),
    );
  }
}
