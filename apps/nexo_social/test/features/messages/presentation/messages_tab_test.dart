import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nexo_social/app/di/injection.dart';
import 'package:nexo_social/app/router/app_router.dart';
import 'package:nexo_social/app/router/app_routes.dart';
import 'package:nexo_social/app/theme/app_theme.dart';
import 'package:nexo_social/core/mock/demo_accounts.dart';
import 'package:nexo_social/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:nexo_social/features/messages/presentation/bloc/unread_messages_cubit.dart';
import 'package:nexo_social/features/messages/presentation/pages/conversation_page.dart';
import 'package:nexo_social/features/messages/presentation/pages/messages_inbox_page.dart';

import '../../../support/app_harness.dart';

/// Mensajes es una pestaña del shell (con el router real de la app): la
/// bandeja vive en su branch y cada chat se abre encima, sin la barra.
void main() {
  late GoRouter router;

  setUp(() async {
    await AppHarness.bootstrap();
    // Tomás: el mock le deja una conversación con Elena sin leer.
    await sl<AuthCubit>().signIn(DemoAccounts.viewer.email, 'nexo-demo-2026');
  });

  Future<void> pumpApp(WidgetTester tester, String location) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final auth = sl<AuthCubit>();
    router = createRouter(
      auth,
      initialLocation: location,
      unreadMessages: sl<UnreadMessagesCubit>(),
    );
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider.value(value: auth),
          BlocProvider.value(value: sl<UnreadMessagesCubit>()),
        ],
        child: MaterialApp.router(theme: AppTheme.nexo, routerConfig: router),
      ),
    );
    await AppHarness.settle(tester);
  }

  final messagesTab = find.byKey(const Key('tab-${AppRoutes.messages}'));

  testWidgets('the tab bar has Mensajes with the unread count', (tester) async {
    await pumpApp(tester, AppRoutes.feed);

    expect(messagesTab, findsOneWidget);
    expect(find.text('Mensajes'), findsOneWidget);
    final badge = find.descendant(
      of: messagesTab,
      matching: find.byKey(const Key('tab-unread-count')),
    );
    expect(badge, findsOneWidget);
    expect(
      find.descendant(of: badge, matching: find.text('1')),
      findsOneWidget,
    );
    // Ya no hay un segundo acceso en la barra del feed.
    expect(find.byKey(const Key('feed-messages')), findsNothing);
  });

  testWidgets('the tab opens the inbox inside the shell', (tester) async {
    await pumpApp(tester, AppRoutes.feed);

    await tester.tap(messagesTab);
    await AppHarness.settle(tester);

    expect(find.byType(MessagesInboxPage), findsOneWidget);
    expect(find.text(DemoAccounts.elena.name), findsOneWidget);
    // Es una pestaña: la barra sigue a la vista.
    expect(messagesTab, findsOneWidget);
  });

  testWidgets('a chat opens over the shell and back returns to the inbox', (
    tester,
  ) async {
    await pumpApp(tester, AppRoutes.messages);

    await tester.tap(find.text(DemoAccounts.elena.name));
    await AppHarness.settle(tester);
    expect(find.byType(ConversationPage), findsOneWidget);
    // Sin la barra mientras se escribe.
    expect(messagesTab, findsNothing);

    router.pop();
    await AppHarness.settle(tester);
    expect(find.byType(ConversationPage), findsNothing);
    expect(find.byType(MessagesInboxPage), findsOneWidget);
    expect(messagesTab, findsOneWidget);
  });

  testWidgets('"Enviar mensaje" from a profile opens the chat in the tab', (
    tester,
  ) async {
    await pumpApp(tester, AppRoutes.profileOf(DemoAccounts.carlos.username));

    await tester.tap(find.byKey(const Key('profile-message')));
    await AppHarness.settle(tester);
    expect(find.byType(ConversationPage), findsOneWidget);
    expect(find.text(DemoAccounts.carlos.name), findsWidgets);

    // Debajo quedó la bandeja, no el perfil: el chat es de la pestaña.
    router.pop();
    await AppHarness.settle(tester);
    expect(find.byType(MessagesInboxPage), findsOneWidget);
    expect(messagesTab, findsOneWidget);
  });
}
