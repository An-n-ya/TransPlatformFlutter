import 'package:flutter/material.dart';
import 'package:trans_platform/ui/feeds/MomentCard.dart';

void main() {
  runApp(const TApp());
}

class TApp extends StatelessWidget {
  const TApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: TScaffold());
  }
}

class TScaffold extends StatefulWidget {

  const TScaffold({super.key});
  
  @override
  State<TScaffold> createState() => _TScaffoldState();
}


class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return 
      DefaultTabController(
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
            leading: 
              IconButton(
                icon: const Icon(Icons.account_circle),
                tooltip: 'Show Snackbar',
                onPressed: () {
                },
              ),
            actions: <Widget>[
              IconButton(
                icon: const Icon(Icons.notifications),
                tooltip: 'Show Snackbar',
                onPressed: () {
                },
              ),
              IconButton(
                icon: const Icon(Icons.settings),
                tooltip: 'Show Settings',
                onPressed: () {
                },
              ),
            ],
            title: const Text('Test'),
          ),
          body: TabBarView(
            children: [
              Moments(),
              Icon(Icons.directions_transit),
              Icon(Icons.directions_bike),
              Icon(Icons.directions_bike),
            ],
          ),
        ),
    );
  }
}


class _TScaffoldState extends State<TScaffold> {
  int currentPageIndex = 0;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      bottomNavigationBar: NavigationBar(
        onDestinationSelected: (int index) {
          setState(() {
            currentPageIndex = index;
          });
        },
        indicatorColor: Colors.purple,
        selectedIndex: currentPageIndex,
        destinations: const <Widget>[
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
      body: <Widget>[
        /// Home page
        HomePage(),

        /// Notifications page
        Moments(),

        /// Messages page
        ListView.builder(
          reverse: true,
          itemCount: 2,
          itemBuilder: (BuildContext context, int index) {
            if (index == 0) {
              return Align(
                alignment: .centerRight,
                child: Container(
                  margin: const .all(8.0),
                  padding: const .all(8.0),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: .circular(8.0),
                  ),
                  child: Text(
                    'Hello',
                    style: theme.textTheme.bodyLarge!.copyWith(
                      color: theme.colorScheme.onPrimary,
                    ),
                  ),
                ),
              );
            }
            return Align(
              alignment: .centerLeft,
              child: Container(
                margin: const .all(8.0),
                padding: const .all(8.0),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: .circular(8.0),
                ),
                child: Text(
                  'Hi!',
                  style: theme.textTheme.bodyLarge!.copyWith(
                    color: theme.colorScheme.onPrimary,
                  ),
                ),
              ),
            );
          },
        ),
      ][currentPageIndex],
    );
  }
}