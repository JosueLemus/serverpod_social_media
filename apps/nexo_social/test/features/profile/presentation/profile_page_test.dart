import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_social/app/di/injection.dart';
import 'package:nexo_social/app/theme/app_theme.dart';
import 'package:nexo_social/features/profile/presentation/pages/profile_page.dart';

void main() {
  testWidgets('profile renders a stable pinned tab header', (tester) async {
    await configureDependencies();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const ProfilePage(username: 'elena.crea'),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Elena Vega'), findsOneWidget);
    expect(find.text('Publicaciones'), findsOneWidget);
  });
}
