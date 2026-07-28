import 'package:flutter/material.dart';

import '../settings/settings_page.dart';
import '../posts/posts_page.dart';

/// "首页" tab — a page with its own sub-tab bar (广场/附近/医疗/生活).
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          bottom: const TabBar(
            tabs: [
              Tab(text: '广场'),
              Tab(text: '附近'),
              Tab(text: '医疗'),
              Tab(text: '生活'),
            ],
          ),
          leading: IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () {},
          ),
          actions: <Widget>[
            IconButton(
              icon: const Icon(Icons.notifications),
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsPage()),
              ),
            ),
          ],
          title: const Text('TransPlatform'),
        ),
        body: const TabBarView(
          children: [
            Posts(),
            Icon(Icons.directions_transit),
            Icon(Icons.directions_bike),
            Icon(Icons.directions_bike),
          ],
        ),
      ),
    );
  }
}
