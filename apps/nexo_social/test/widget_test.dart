import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_social/features/feed/presentation/pages/feed_page.dart';

import 'support/app_harness.dart';

void main() {
  setUp(AppHarness.bootstrap);

  testWidgets('shows the mock feed', (tester) async {
    await tester.pumpWidget(AppHarness.wrap(const FeedPage()));
    await AppHarness.settle(tester);

    // En la fila de historias y en la tarjeta del post.
    expect(find.text('Elena Vega'), findsWidgets);
  });
}
