import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:integration_test/integration_test.dart';
import 'package:nexo_social/app/app.dart';
import 'package:nexo_social/app/di/injection.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('mock flow navigates, likes, creates and opens a live', (
    tester,
  ) async {
    await configureDependencies();
    await tester.pumpWidget(const NexoApp());
    await tester.pumpAndSettle();
    expect(find.text('Elena Vega'), findsOneWidget);
    await tester.tap(find.byKey(const Key('like-post-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Crear'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('create-post-field')),
      'Hola comunidad',
    );
    await tester.tap(find.byKey(const Key('publish-button')));
    await tester.pumpAndSettle();
    expect(find.text('Hola comunidad'), findsOneWidget);
    await tester.tap(find.text('En vivo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Masterclass de Diseño Mobile'));
    await tester.pumpAndSettle();
    expect(find.text('Sala en vivo'), findsOneWidget);
  });
}
