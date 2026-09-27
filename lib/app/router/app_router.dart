import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/responsive/responsive_scaffold.dart';
import '../../core/widgets/placeholder_page.dart';
import '../../features/feed/presentation/pages/feed_page.dart';
import '../../features/live/presentation/pages/live_pages.dart';
import '../../features/notifications/presentation/pages/activity_page.dart';
import '../../features/posts/presentation/pages/create_post_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/auth/presentation/pages/auth_pages.dart';
import '../../features/moderation/presentation/pages/moderation_page.dart';
import '../../features/subscriptions/presentation/pages/subscription_page.dart';

final appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(path: '/splash', builder: (context, state) => const SplashPage()),
    GoRoute(path: '/sign-in', builder: (context, state) => const SignInPage()),
    GoRoute(path: '/sign-up', builder: (context, state) => const SignUpPage()),
    ShellRoute(
      builder: (context, state, child) =>
          ResponsiveScaffold(location: state.uri.path, child: child),
      routes: [
        GoRoute(path: '/', builder: (context, state) => const FeedPage()),
        GoRoute(
          path: '/create',
          builder: (context, state) => const CreatePostPage(),
        ),
        GoRoute(
          path: '/live',
          builder: (context, state) => const LiveListPage(),
        ),
        GoRoute(
          path: '/activity',
          builder: (context, state) => const ActivityPage(),
        ),
        GoRoute(
          path: '/profile/:username',
          builder: (context, state) =>
              ProfilePage(username: state.pathParameters['username'] ?? 'nexo'),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const PlaceholderPage(
            title: 'Ajustes',
            description: 'Personaliza tu experiencia en Nexo.',
            icon: Icons.settings_outlined,
          ),
        ),
        GoRoute(
          path: '/live/:liveId',
          builder: (context, state) =>
              LiveRoomPage(liveId: state.pathParameters['liveId'] ?? 'preview'),
        ),
        GoRoute(
          path: '/creator-studio',
          builder: (context, state) => const CreatorStudioPage(),
        ),
        GoRoute(
          path: '/moderation',
          builder: (context, state) => const ModerationPage(),
        ),
        GoRoute(
          path: '/premium',
          builder: (context, state) => const SubscriptionPage(),
        ),
      ],
    ),
  ],
);
