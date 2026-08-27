import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/user/user_repository.dart';
import '../../domain/models/user.dart';
import '../../utils/result.dart';
import '../user/user_detail_page.dart';
import 'home_page.dart';

/// Root shell after login.
///
/// Hosts a bottom [NavigationBar] with two tabs:
/// 0. "首页" → [HomePage]
/// 1. "我的" → tap opens current user's [UserDetailPage]
///
/// 语音通话（活动）tab 已从主分支移除，仅保留在 `chatroom` 分支。
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _tabIndex = 0;

  void _onTabSelected(int index) {
    if (index == 1) {
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Scaffold(
      bottomNavigationBar: NavigationBar(
        indicatorColor: colorScheme.primaryContainer,
        selectedIndex: _tabIndex,
        onDestinationSelected: _onTabSelected,
        destinations: const [
          NavigationDestination(
            selectedIcon: Icon(Icons.star),
            icon: Icon(Icons.home_outlined),
            label: '首页',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_circle),
            label: '我的',
          ),
        ],
      ),
      body: const HomePage(),
    );
  }
}
