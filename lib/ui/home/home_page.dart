import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trans_platform/ui/home/search_page.dart';

import '../../data/repositories/notification/notification_repository.dart';
import '../../domain/models/feed_type.dart';
import '../../utils/result.dart';

import '../settings/settings_page.dart';
import '../notification/notification_page.dart';
import '../posts/add_post_page.dart';
import '../posts/posts_page.dart';

/// "首页" tab — three feed streams (广场 / 关注 / 附近), one per [FeedType].
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DefaultTabController(
      length: FeedType.values.length,
      child: Scaffold(
        appBar: AppBar(
          bottom: TabBar(
            tabs: [for (final t in FeedType.values) Tab(text: t.label)],
          ),
          leading: IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const SearchPage())),
          ),
          actions: <Widget>[
            FutureBuilder<Result<int>>(
              future: context.read<NotificationRepository>().getUnreadCount(),
              builder: (_, snapshot) {
                final unread = switch (snapshot.data) {
                  Ok<int>(:final value) => value,
                  _ => 0,
                };
                return IconButton(
                  icon: unread > 0
                      ? Badge(
                          label: Text(
                            unread > 99 ? '99+' : '$unread',
                            style: const TextStyle(fontSize: 10),
                          ),
                          child: const Icon(Icons.notifications),
                        )
                      : const Icon(Icons.notifications),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const NotificationPage()),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const SettingsPage())),
            ),
          ],
          title: const Text('TransPlatform'),
        ),
        body: TabBarView(
          children: [
            for (final t in FeedType.values) Posts(type: t),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const AddPostPage())),
          backgroundColor: colorScheme.primaryContainer,
          child: Icon(Icons.add, color: colorScheme.primary),
        ),
      ),
    );
  }
}
