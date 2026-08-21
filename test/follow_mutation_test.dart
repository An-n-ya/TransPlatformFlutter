import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:trans_platform/data/cache/user_cache.dart';
import 'package:trans_platform/data/repositories/user/user_repository_local.dart';
import 'package:trans_platform/providers/follow_mutation_providers.dart';
import 'package:trans_platform/providers/repository_providers.dart';
import 'package:trans_platform/providers/user_providers.dart';
import 'package:trans_platform/utils/result.dart';

/// Local repository whose follow/unfollow mutations always fail, so tests can
/// verify the optimistic update is rolled back to the pre-mutation snapshot.
class _FailingFollowRepo extends UserRepositoryLocal {
  @override
  Future<Result<void>> follow(int userId) async =>
      Result.error(Exception('network down'));

  @override
  Future<Result<void>> unfollow(int userId) async =>
      Result.error(Exception('network down'));
}

void main() {
  // Needed so GlobalKey.currentState (used by Snackbar.show) does not assert
  // on an uninitialized WidgetsBinding in pure unit tests.
  TestWidgetsFlutterBinding.ensureInitialized();

  ProviderContainer makeContainer() => ProviderContainer(
        overrides: [
          userRepositoryProvider.overrideWithValue(_FailingFollowRepo()),
        ],
      );

  test('toggleFollow updates the relation optimistically, then rolls back',
      () async {
    final container = makeContainer();
    addTearDown(container.dispose);

    container.read(followRelationsProvider.notifier).add(1);

    // Fire the mutation without awaiting it yet.
    final future = container
        .read(followMutationProvider.notifier)
        .toggleFollow(1);

    // Before the API settles, the relation already reflects the optimistic
    // unfollow.
    final optimistic = container.read(followRelationsProvider);
    expect(optimistic.isFollowing(1), isFalse);

    await future;

    // After the failing API call, the snapshot is restored.
    final after = container.read(followRelationsProvider);
    expect(after.isFollowing(1), isTrue);
  });

  test('ensureLoaded populates followee ids from the followee list', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container.read(followRelationsProvider.notifier).ensureLoaded(1);

    final relations = container.read(followRelationsProvider);
    expect(relations.loaded, isTrue);
    // Local repository returns the demo user (id 1).
    expect(relations.followeeIds, {1});
  });

  test('FollowList loader populates the user cache', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final users = await container
        .read(followListProvider(userId: 1, isFollowers: false).future);
    expect(users, hasLength(1));

    final cached = container.read(userCacheProvider).getFollowees(1);
    expect(cached, hasLength(1),
        reason: 'cache should hold the fetched users');
    expect(cached.single.id, 1);
  });
}
