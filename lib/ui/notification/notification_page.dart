import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/notification/notification_repository.dart';
import '../../domain/models/notification.dart';
import '../../utils/result.dart';
import '../../utils/time.dart';
import '../posts/post_card.dart';
import '../posts/post_detail_page.dart';

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
              onPressed: () =>
                  context.read<NotificationRepository>().markAllAsRead(),
            ),
          ],
          bottom: const _NotificationTabBar(),
        ),
        body: const _NotificationTabs(),
      ),
    );
  }
}

class _NotificationTabBar extends StatelessWidget
    implements PreferredSizeWidget {
  const _NotificationTabBar();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return FutureBuilder<Result<List<AppNotification>>>(
      future: context.read<NotificationRepository>().getNotifications(),
      builder: (_, snapshot) {
        final notifications = switch (snapshot.data) {
          Ok<List<AppNotification>>(:final value) => value,
          _ => <AppNotification>[],
        };

        final replyUnread = notifications
            .where(
              (n) => (n.type == 'comment' || n.type == 'reply') && !n.isRead,
            )
            .length;
        final likeUnread = notifications
            .where(
              (n) =>
                  (n.type == 'post_like' || n.type == 'collection') &&
                  !n.isRead,
            )
            .length;
        final followUnread = notifications
            .where((n) => n.type == 'follow' && !n.isRead)
            .length;

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
                  if (replyUnread > 0) ...[
                    const SizedBox(width: 4),
                    const _UnreadDot(),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('收到喜欢'),
                  if (likeUnread > 0) ...[
                    const SizedBox(width: 4),
                    const _UnreadDot(),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('新增关注'),
                  if (followUnread > 0) ...[
                    const SizedBox(width: 4),
                    const _UnreadDot(),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(48);
}

/// Shared tab body that loads notifications and filters by type.
class _NotificationTabs extends StatefulWidget {
  const _NotificationTabs();

  @override
  State<_NotificationTabs> createState() => _NotificationTabsState();
}

class _NotificationTabsState extends State<_NotificationTabs> {
  late Future<Result<List<AppNotification>>> _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<NotificationRepository>().getNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Result<List<AppNotification>>>(
      future: _future,
      builder: (_, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        return switch (snapshot.data!) {
          Ok<List<AppNotification>>(:final value) => TabBarView(
            children: [
              _NotificationList(
                notifications: value
                    .where((n) => n.type == 'comment' || n.type == 'reply')
                    .toList(),
              ),
              _NotificationList(
                notifications: value
                    .where(
                      (n) => n.type == 'post_like' || n.type == 'collection',
                    )
                    .toList(),
              ),
              _NotificationList(
                notifications: value.where((n) => n.type == 'follow').toList(),
              ),
            ],
          ),
          Error<List<AppNotification>>() => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text('加载失败', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 16),
                FilledButton.tonal(
                  onPressed: () => setState(() {
                    _future = context
                        .read<NotificationRepository>()
                        .getNotifications();
                  }),
                  child: const Text('重试'),
                ),
              ],
            ),
          ),
        };
      },
    );
  }
}

class _NotificationList extends StatelessWidget {
  final List<AppNotification> notifications;

  const _NotificationList({required this.notifications});

  @override
  Widget build(BuildContext context) {
    if (notifications.isEmpty) {
      return const Center(child: Text('暂无消息'));
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: notifications.length,
      itemBuilder: (_, i) => _NotificationTile(item: notifications[i]),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification item;

  const _NotificationTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      onTap: () {
        if (item.targetId != null) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => PostDetailPage(postId: item.targetId),
            ),
          );
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PostHeader(
              user: item.fromUser,
              title: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    item.fromUser.nickname,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _actionText(item.type),
                    style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant),
                  ),
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      if (!item.isRead) ...[
                        const Padding(
                          padding: EdgeInsets.only(right: 6),
                          child: _UnreadDot(),
                        ),
                      ],
                      Text(
                        formatRelativeTime(item.createdAt),
                        style: TextStyle(
                          fontSize: 14,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              trailing: item.type == 'follow' ? _FollowButton() : null,
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
      ),
    );
  }

  String _actionText(String type) {
    return switch (type) {
      'reply' => '回复了我的评论',
      'comment' => '评论了我的贴文',
      'post_like' => '喜欢了我的贴文',
      'collection' => '收藏了我的贴文',
      'follow' => '关注了我',
      _ => type,
    };
  }
}

/// A small red dot indicating unread status.
class _UnreadDot extends StatelessWidget {
  const _UnreadDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.error,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _FollowButton extends StatelessWidget {
  const _FollowButton();

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: () {},
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
      ),
      child: const Text('回关'),
    );
  }
}
