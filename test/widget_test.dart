import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_social/app/di/injection.dart';
import 'package:nexo_social/app/theme/app_theme.dart';
import 'package:nexo_social/features/feed/presentation/pages/feed_page.dart';

void main() {
  testWidgets('shows the mock feed', (tester) async {
    await configureDependencies();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(body: FeedPage()),
      ),
    );
    // Google Fonts can keep a font-loading frame scheduled in test mode.
    // One bounded frame is enough for the mock FeedCubit to emit its content.
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Elena Vega'), findsOneWidget);
  });
}
