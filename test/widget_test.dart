import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:trans_platform/config/dependencies.dart';
import 'package:trans_platform/main.dart';

void main() {
  testWidgets('App renders without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: providersLocal,
        child: const MainApp(),
      ),
    );

    // Verify the app loaded — look for the bottom nav
    expect(find.text('首页'), findsOneWidget);
    expect(find.text('活动'), findsOneWidget);
    expect(find.text('我的'), findsOneWidget);
  });
}
