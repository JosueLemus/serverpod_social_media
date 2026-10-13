import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nexo_social/app/di/injection.dart';
import 'package:nexo_social/app/router/app_routes.dart';
import 'package:nexo_social/app/theme/app_theme.dart';
import 'package:nexo_social/core/mock/demo_accounts.dart';
import 'package:nexo_social/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:nexo_social/features/messages/domain/repositories/messages_repository.dart';
import 'package:nexo_social/features/messages/presentation/bloc/unread_messages_cubit.dart';
import 'package:nexo_social/features/messages/presentation/pages/conversation_page.dart';
import 'package:nexo_social/features/messages/presentation/pages/messages_inbox_page.dart';
import 'package:nexo_social/features/messages/presentation/widgets/messages_button.dart';

import '../../../support/app_harness.dart';

void main() {
  setUp(() async {
    await AppHarness.bootstrap();
    await sl<AuthCubit>().signIn(DemoAccounts.viewer.email, 'nexo-demo-2026');
  });

  /// La bandeja, el chat y una página de partida, con rutas reales.
  GoRouter router(String initialLocation) => GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => const Scaffold(body: MessagesButton()),
      ),
      GoRoute(
        path: AppRoutes.messages,
        builder: (_, _) => const MessagesInboxPage(),
        routes: [
          GoRoute(
            path: AppRoutes.conversationWithSegment,
            builder: (_, state) =>
                ConversationPage(userId: state.pathParameters['userId']),
          ),
          GoRoute(
            path: AppRoutes.conversationSegment,
            builder: (_, state) => ConversationPage(
              conversationId: state.pathParameters['conversationId'],
            ),
          ),
        ],
      ),
    ],
  );

  Future<void> pump(WidgetTester tester, String location) async {
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider.value(value: sl<AuthCubit>()),
          BlocProvider.value(value: sl<UnreadMessagesCubit>()),
        ],
        child: MaterialApp.router(
          theme: AppTheme.nexo,
          routerConfig: router(location),
        ),
      ),
    );
    await AppHarness.settle(tester);
  }

  testWidgets(
    'the feed button shows unread conversations and opens the inbox',
    (tester) async {
      await pump(tester, '/');
      // El mock arranca con una conversación con Elena y un mensaje sin leer.
      expect(find.text('1'), findsOneWidget);

      await tester.tap(find.byKey(const Key('feed-messages')));
      await AppHarness.settle(tester);
      expect(find.byType(MessagesInboxPage), findsOneWidget);
      expect(find.text(DemoAccounts.elena.name), findsOneWidget);
      expect(find.textContaining('¿Viste el vivo'), findsOneWidget);
    },
  );

  testWidgets('a conversation opens from the inbox and a message is sent', (
    tester,
  ) async {
    await pump(tester, AppRoutes.messages);
    await tester.tap(find.byType(InkWell).first);
    await AppHarness.settle(tester);

    expect(find.byType(ConversationPage), findsOneWidget);
    expect(find.textContaining('¿Viste el vivo'), findsOneWidget);
    // Abrirla la marca leída: el badge vuelve a cero.
    expect(sl<UnreadMessagesCubit>().state, 0);

    await tester.enterText(
      find.byKey(const Key('dm-composer-field')),
      'Sí, ¡estuvo genial!',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('dm-send')));
    await AppHarness.settle(tester);

    expect(find.text('Sí, ¡estuvo genial!'), findsOneWidget);
    expect(find.text('Enviando…'), findsNothing);
  });

  testWidgets('opening with an account from a profile creates the chat', (
    tester,
  ) async {
    await pump(tester, AppRoutes.conversationWith(DemoAccounts.carlos.id));

    expect(find.text(DemoAccounts.carlos.name), findsOneWidget);
    expect(find.textContaining('Manda el primer mensaje'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('dm-composer-field')),
      'Hola Carlos',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('dm-send')));
    await AppHarness.settle(tester);
    expect(find.text('Hola Carlos'), findsOneWidget);

    final inbox = await sl<MessagesRepository>().conversations();
    expect(
      inbox.items.map((c) => c.peer.name),
      contains(DemoAccounts.carlos.name),
    );
  });
}
