import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trans_platform/ui/activites/activities_page.dart';

import '../../data/repositories/user/user_repository.dart';
import '../../domain/models/user.dart';
import '../../utils/result.dart';
import '../posts/posts_page.dart';
import '../user/user_detail_page.dart';
import 'home_page.dart';
import 'messages_page.dart';

/// Root shell after login.
///
/// Hosts a bottom [NavigationBar] with three tabs:
/// 0. "首页" → [HomePage]  (sub-tabs: 广场/附近/医疗/生活)
/// 1. "活动" → [Posts]     (feed / timeline)
/// 2. "我的" → tap opens current user's [UserDetailPage]
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _tabIndex = 0;

  void _onTabSelected(int index) {
    if (index == 2) {
      // "我的" → push current user's profile page
      _openMyProfile();
      return;
    }
    setState(() => _tabIndex = index);
  }

  Future<void> _openMyProfile() async {
    // Show loading indicator briefly while fetching user
    final result = await context.read<UserRepository>().getCurrentUser();
    if (!mounted) return;

    switch (result) {
      case Ok<User>(:final value):
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => UserDetailPage(user: value, isMe: true),
          ),
        );
      case Error<User>():
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('加载用户信息失败')),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: _onTabSelected,
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
            icon: Icon(Icons.account_circle),
            label: '我的',
          ),
        ],
      ),
      body: [
        const HomePage(),
        const ActivitiesPage(),
        const MessagesPage(),
      ][_tabIndex],
    );
  }
}
