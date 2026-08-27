import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:trans_platform/config/dependencies.dart';
import 'package:trans_platform/ui/home/app_shell.dart';

void main() {
  testWidgets('App shell renders without crashing', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MultiProvider(
          providers: providersLocal,
          child: const MaterialApp(home: AppShell()),
        ),
      ),
    );

    // Let the feed load (local repository uses short Future.delayed calls).
    await tester.pumpAndSettle();

    // Verify the app loaded — look for the bottom nav
    expect(find.text('首页'), findsOneWidget);
    expect(find.text('我的'), findsOneWidget);
  });
}
