import 'package:flutter/material.dart';

import '../../domain/models/user.dart';
import '../../utils/time.dart';
import '../posts/post_card.dart';
import '../user/user_detail_page.dart';

/// Types of notifications shown in the messages page.
enum NotificationType { reply, like, follow }

/// A notification item displayed in one of the tabs.
class NotificationItem {
  final int id;
  final NotificationType type;
  final User user;
  final String actionText;
  final String? content;
  final DateTime createdAt;
  final bool isFollowing;

  const NotificationItem({
    required this.id,
    required this.type,
    required this.user,
    required this.actionText,
    this.content,
    required this.createdAt,
    this.isFollowing = false,
  });
}

/// Notifications page with tabs for replies, likes, and new followers.
class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text('消息'),
          actions: [
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () {},
            ),
          ],
          bottom: const _NotificationTabBar(),
        ),
        body: const TabBarView(
          children: [_ReplyList(), _LikeList(), _FollowList()],
        ),
      ),
    );
  }
}

/// Custom tab bar with a badge dot on the replies tab.
class _NotificationTabBar extends StatelessWidget
    implements PreferredSizeWidget {
  const _NotificationTabBar();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return TabBar(
      labelColor: cs.primary,
      unselectedLabelColor: cs.onSurfaceVariant,
      indicatorColor: cs.primary,
      indicatorWeight: 3,
      tabs: [
        Tab(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('回复'),
              const SizedBox(width: 4),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: cs.error,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
        const Tab(text: '收到喜欢'),
        const Tab(text: '新增关注'),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(48);
}

class _ReplyList extends StatelessWidget {
  const _ReplyList();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: _mockReplies.length,
      itemBuilder: (_, i) => _NotificationTile(item: _mockReplies[i]),
    );
  }
}

class _LikeList extends StatelessWidget {
  const _LikeList();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: _mockLikes.length,
      itemBuilder: (_, i) => _NotificationTile(item: _mockLikes[i]),
    );
  }
}

class _FollowList extends StatelessWidget {
  const _FollowList();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: _mockFollows.length,
      itemBuilder: (_, i) => _NotificationTile(item: _mockFollows[i]),
    );
  }
}

/// Single notification row reusing [PostHeader].
class _NotificationTile extends StatelessWidget {
  final NotificationItem item;

  const _NotificationTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
      child: Column(
        children: [
          PostHeader(
            user: item.user,
            onAvatarTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => UserDetailPage(user: item.user),
              ),
            ),
            title: Row(
              children: [
                Text(
                  item.user.nickname,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item.actionText,
                    style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant),
                  ),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 2),
                Text(
                  formatRelativeTime(item.createdAt),
                  style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant),
                ),
              ],
            ),
            trailing: item.type == NotificationType.follow
                ? _FollowButton(isFollowing: item.isFollowing)
                : null,
          ),
          if (item.content != null) ...[
            Padding(
              padding: const EdgeInsets.only(left: 72),
              child: Text(
                item.content!,
                style: TextStyle(fontSize: 14, color: cs.onSurface),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Follow / unfollow button used in the new followers tab.
class _FollowButton extends StatelessWidget {
  final bool isFollowing;

  const _FollowButton({required this.isFollowing});

  @override
  Widget build(BuildContext context) {
    return isFollowing
        ? FilledButton.tonal(
            onPressed: () {},
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(100),
              ),
            ),
            child: const Text('取关'),
          )
        : FilledButton(
            onPressed: () {},
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(100),
              ),
            ),
            child: const Text('回关'),
          );
  }
}

final _mockUser = const User(id: 1, username: 'user', nickname: 'User Name');

final _mockReplies = [
  NotificationItem(
    id: 1,
    type: NotificationType.reply,
    user: _mockUser,
    actionText: '回复了我的贴文',
    content:
        'Maecenas egestas nulla vel vulputate consequat. Nam aliquet nisl pretium, venenatis sapien a, malesuada mauris. Suspendisse bibendum ut turpis vitae elementum.',
    createdAt: DateTime.now().subtract(const Duration(days: 3)),
  ),
  NotificationItem(
    id: 2,
    type: NotificationType.reply,
    user: _mockUser,
    actionText: '回复了我的贴文',
    content:
        'Maecenas egestas nulla vel vulputate consequat. Nam aliquet nisl pretium, venenatis sapien a, malesuada mauris. Suspendisse bibendum ut turpis vitae elementum.',
    createdAt: DateTime.now().subtract(const Duration(days: 3)),
  ),
];

final _mockLikes = [
  NotificationItem(
    id: 3,
    type: NotificationType.like,
    user: _mockUser,
    actionText: '喜欢了我的贴文',
    content:
        'Maecenas egestas nulla vel vulputate consequat. Nam aliquet nisl pretium, venenatis sapien a, malesuada mauris.',
    createdAt: DateTime.now().subtract(const Duration(days: 2)),
  ),
];

final _mockFollows = [
  NotificationItem(
    id: 4,
    type: NotificationType.follow,
    user: _mockUser,
    actionText: '关注了我',
    createdAt: DateTime.now().subtract(const Duration(days: 3)),
    isFollowing: true,
  ),
  NotificationItem(
    id: 5,
    type: NotificationType.follow,
    user: _mockUser,
    actionText: '关注了我',
    createdAt: DateTime.now().subtract(const Duration(days: 3)),
    isFollowing: false,
  ),
];
