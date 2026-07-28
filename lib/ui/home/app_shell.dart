import 'package:flutter/material.dart';

import '../posts/posts_page.dart';
import 'home_page.dart';
import 'messages_page.dart';

/// Root shell after login.
///
/// Hosts a bottom [NavigationBar] with three tabs:
/// 0. "首页" → [HomePage]  (sub-tabs: 广场/附近/医疗/生活)
/// 1. "活动" → [Posts]    (feed / timeline)
/// 2. "我的" → [MessagesPage] (chat-style messages)
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (i) => setState(() => _tabIndex = i),
        indicatorColor: Colors.purple,
        destinations: const [
          NavigationDestination(
            selectedIcon: Icon(Icons.star),
            icon: Icon(Icons.home_outlined),
            label: '首页',
          ),
          NavigationDestination(
            icon: Badge(child: Icon(Icons.group)),
            label: '活动',
          ),
          NavigationDestination(
            icon: Badge(label: Text('2'), child: Icon(Icons.account_circle)),
            label: '我的',
          ),
        ],
      ),
      body: [
        const HomePage(),
        const Posts(),
        const MessagesPage(),
      ][_tabIndex],
    );
  }
}
