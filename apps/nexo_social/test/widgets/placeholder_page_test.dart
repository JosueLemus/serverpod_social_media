import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_social/core/widgets/placeholder_page.dart';

void main() {
  testWidgets('renders title and description', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PlaceholderPage(title: 'Prueba', description: 'Descripción'),
        ),
      ),
    );
    expect(find.text('Prueba'), findsOneWidget);
    expect(find.text('Descripción'), findsOneWidget);
  });
}
