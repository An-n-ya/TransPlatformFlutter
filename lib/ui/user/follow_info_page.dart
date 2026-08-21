import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/cache/user_cache.dart';
import '../../domain/models/user.dart';
import '../../providers/user_providers.dart';
import '../posts/post_card.dart';
import 'user_buttons.dart';

/// Followers / followees list page.
///
/// - [isFollowerPage] = true  → 粉丝列表 (`/api/v1/users/{id}/followers`)
/// - [isFollowerPage] = false → 关注列表 (`/api/v1/users/{id}/followees`)
///
/// The list is loaded via [FollowList] into the SSOT user cache; the rows
/// are rendered from the cache so follow buttons reflect live state.
class FollowInfoPage extends ConsumerWidget {
  final int userId;
  final bool isFollowerPage;

  const FollowInfoPage({
    super.key,
    required this.userId,
    this.isFollowerPage = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncList = ref.watch(
      followListProvider(userId: userId, isFollowers: isFollowerPage),
    );
    return Scaffold(
      appBar: AppBar(title: Text(isFollowerPage ? '粉丝' : '关注')),
      body: asyncList.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(child: Text('加载失败')),
        data: (users) {
          // Render from the SSOT cache (filled by the loader above).
          final list = isFollowerPage
              ? ref.watch(userCacheProvider).getFollowers(userId)
              : ref.watch(userCacheProvider).getFollowees(userId);
          return list.isEmpty
              ? const Center(child: Text('暂无数据'))
              : ListView.builder(
                  itemCount: list.length,
                  itemBuilder: (_, i) => _UserRow(user: list[i]),
                );
        },
      ),
    );
  }
}

/// Single user row: avatar + nickname, with a quick follow button.
class _UserRow extends StatelessWidget {
  final User user;

  const _UserRow({required this.user});

  @override
  Widget build(BuildContext context) {
    return PostHeader(
      user: user,
      subtitle: Text(user.bio ?? ''),
      trailing: UserFollowButton(targetUser: user),
    );
  }
}
