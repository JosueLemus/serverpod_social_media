import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_social/core/widgets/app_state_views.dart';

void main() {
  testWidgets('error view exposes retry action', (tester) async {
    var retried = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: AppErrorView(onRetry: () => retried = true)),
      ),
    );
    await tester.tap(find.text('Reintentar conexión'));
    expect(retried, isTrue);
  });

  testWidgets('feed skeleton renders loading cards', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: FeedSkeleton())),
    );
    expect(find.byType(AppSkeleton), findsWidgets);
  });
}
