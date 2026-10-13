import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nexo_social/app/di/injection.dart';
import 'package:nexo_social/app/router/app_routes.dart';
import 'package:nexo_social/app/theme/app_theme.dart';
import 'package:nexo_social/core/errors/failures.dart';
import 'package:nexo_social/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:nexo_social/features/feed/domain/entities/post.dart';
import 'package:nexo_social/features/feed/domain/repositories/post_repository.dart';
import 'package:nexo_social/features/feed/presentation/bloc/post_detail_cubit.dart';
import 'package:nexo_social/features/feed/presentation/pages/post_detail_page.dart';
import 'package:nexo_social/features/feed/presentation/utils/post_share_text.dart';
import 'package:nexo_social/features/feed/presentation/widgets/photo_viewer.dart';
import 'package:nexo_social/features/feed/presentation/widgets/post_card.dart';
import 'package:nexo_social/features/notifications/domain/entities/app_notification.dart';
import 'package:nexo_social/features/notifications/presentation/utils/notification_type_ui.dart';
import 'package:nexo_social/features/profile/presentation/pages/profile_page.dart';

import '../../../support/app_harness.dart';
import '../../../support/fake_post_repository.dart';

void main() {
  group('PostDetailCubit', () {
    late FakePostRepository posts;

    setUp(() => posts = FakePostRepository([fakePost('7', likes: 2)]));

    blocTest<PostDetailCubit, PostDetailState>(
      'carga la publicación',
      build: () => PostDetailCubit(posts, '7'),
      act: (cubit) => cubit.load(),
      expect: () => [
        const PostDetailState(),
        isA<PostDetailState>()
            .having((s) => s.status, 'status', PostDetailStatus.ready)
            .having((s) => s.post?.id, 'post', '7'),
      ],
    );

    blocTest<PostDetailCubit, PostDetailState>(
      'una publicación que no existe es "no encontrada", no un error',
      build: () => PostDetailCubit(posts, '404'),
      act: (cubit) => cubit.load(),
      expect: () => [
        const PostDetailState(),
        const PostDetailState(status: PostDetailStatus.notFound),
      ],
    );

    blocTest<PostDetailCubit, PostDetailState>(
      'sin red es un error con reintento',
      build: () =>
          PostDetailCubit(posts..failNext = const NetworkFailure('x'), '7'),
      act: (cubit) => cubit.load(),
      expect: () => [
        const PostDetailState(),
        const PostDetailState(status: PostDetailStatus.failure),
      ],
    );

    blocTest<PostDetailCubit, PostDetailState>(
      'el like es optimista y vuelve atrás si el servidor falla',
      build: () => PostDetailCubit(posts, '7'),
      seed: () => PostDetailState(
        status: PostDetailStatus.ready,
        post: fakePost('7', likes: 2),
      ),
      act: (cubit) {
        posts.failNext = const ServerFailure('x');
        return cubit.toggleLike();
      },
      expect: () => [
        isA<PostDetailState>()
            .having((s) => s.post?.isLiked, 'liked', true)
            .having((s) => s.post?.likes, 'likes', 3),
        isA<PostDetailState>()
            .having((s) => s.post?.isLiked, 'liked', false)
            .having((s) => s.post?.likes, 'likes', 2),
        isA<PostDetailState>().having(
          (s) => s.notice,
          'notice',
          PostDetailNotice.likeFailed,
        ),
      ],
    );

    blocTest<PostDetailCubit, PostDetailState>(
      'borrarla deja la pantalla en "borrada" para que la View la cierre',
      build: () => PostDetailCubit(posts, '7'),
      seed: () =>
          PostDetailState(status: PostDetailStatus.ready, post: fakePost('7')),
      act: (cubit) => cubit.delete(),
      expect: () => [
        isA<PostDetailState>().having(
          (s) => s.status,
          'status',
          PostDetailStatus.deleted,
        ),
      ],
      verify: (_) => expect(posts.posts, isEmpty),
    );

    // Un like o un comentario desde otra pantalla deja el contador al día,
    // sin perder el "guardado", que es local.
    test('a change elsewhere refreshes it and keeps what is local', () async {
      final cubit = PostDetailCubit(posts, '7');
      await cubit.load();
      cubit.toggleSave();

      await posts.setLiked('7', liked: true);
      await pumpEventQueue();

      final post = cubit.state.post!;
      expect(post.isLiked, isTrue);
      expect(post.likes, 3);
      expect(post.isSaved, isTrue);
      await cubit.close();
    });

    test('editing keeps the saved mark', () async {
      final cubit = PostDetailCubit(posts, '7');
      await cubit.load();
      cubit.toggleSave();

      await cubit.edit('texto nuevo');

      expect(cubit.state.post!.body, 'texto nuevo');
      expect(cubit.state.post!.isSaved, isTrue);
      await cubit.close();
    });

    test('closing stops listening to the repository', () async {
      final cubit = PostDetailCubit(posts, '7');
      await cubit.load();
      await cubit.close();

      // Sin la suscripción cancelada, esto emitiría sobre un cubit cerrado.
      posts.emitChange();
      await pumpEventQueue();
    });
  });

  group('las fotos se abren', () {
    setUp(AppHarness.bootstrap);

    testWidgets('tocar la foto de una publicación abre el visor', (
      tester,
    ) async {
      final post = Post(
        id: '9',
        author: 'elena_ux',
        name: 'Elena Vega',
        body: 'Mi plancha nueva',
        tags: const [],
        likes: 0,
        comments: 0,
        createdAt: DateTime(2026),
        media: PostMedia.image,
        mediaUrl: 'https://example.com/foto.jpg',
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.nexo,
          home: Scaffold(
            body: SingleChildScrollView(
              child: PostCard(post: post, onLike: () {}, onSave: () {}),
            ),
          ),
        ),
      );
      await tester.tap(find.byKey(const Key('post-image-open')));
      await tester.pumpAndSettle();

      expect(find.byType(PhotoViewer), findsOneWidget);

      await tester.tap(find.byKey(const Key('photo-viewer-close')));
      await tester.pumpAndSettle();
      expect(find.byType(PhotoViewer), findsNothing);
    });

    testWidgets('tocar una publicación de la grilla del perfil la abre', (
      tester,
    ) async {
      await AppHarness.bootstrap(
        initialPreferences: {
          'mock_session':
              '{"id":"creator-1","username":"elena_ux","name":"Elena Vega","role":"creator"}',
        },
      );
      await sl<AuthCubit>().restore();
      tester.view.physicalSize = const Size(400, 2200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) =>
                const Scaffold(body: ProfilePage(username: 'elena_ux')),
          ),
          GoRoute(
            path: AppRoutes.postPath,
            builder: (_, state) =>
                Text('post-page-${state.pathParameters['postId']}'),
          ),
        ],
      );
      await tester.pumpWidget(
        BlocProvider.value(
          value: sl<AuthCubit>(),
          child: MaterialApp.router(theme: AppTheme.nexo, routerConfig: router),
        ),
      );
      await AppHarness.settle(tester);

      final tile = find.byWidgetPredicate(
        (widget) =>
            widget.key is ValueKey<String> &&
            (widget.key! as ValueKey<String>).value.startsWith('profile-post-'),
      );
      expect(tile, findsWidgets);
      final id = (tester.widget(tile.first).key! as ValueKey<String>).value
          .replaceFirst('profile-post-', '');

      await tester.tap(tile.first);
      await AppHarness.settle(tester);
      expect(find.text('post-page-$id'), findsOneWidget);
    });
  });

  group('PostDetailPage', () {
    late FakePostRepository posts;

    setUp(() async {
      await AppHarness.bootstrap();
      posts = FakePostRepository([fakePost('7')]);
      sl
        ..unregister<PostRepository>()
        ..registerLazySingleton<PostRepository>(() => posts);
    });

    Future<void> pump(WidgetTester tester, String id) async {
      final router = GoRouter(
        initialLocation: AppRoutes.post(id),
        routes: [
          GoRoute(path: '/', builder: (_, _) => const Text('inicio')),
          GoRoute(
            path: AppRoutes.signIn,
            builder: (_, state) =>
                Text('login-${state.uri.queryParameters[AppRoutes.fromParam]}'),
          ),
          GoRoute(
            path: AppRoutes.postPath,
            builder: (_, state) =>
                PostDetailPage(postId: state.pathParameters['postId']!),
          ),
        ],
      );
      await tester.pumpWidget(
        BlocProvider.value(
          value: sl<AuthCubit>(),
          child: MaterialApp.router(theme: AppTheme.nexo, routerConfig: router),
        ),
      );
      await AppHarness.settle(tester);
    }

    testWidgets('muestra la publicación con su botón de comentarios', (
      tester,
    ) async {
      await pump(tester, '7');

      expect(find.text('post 7'), findsOneWidget);
      expect(find.byKey(const Key('post-detail-comments')), findsOneWidget);
    });

    testWidgets('una publicación borrada lo dice y ofrece volver al inicio', (
      tester,
    ) async {
      await pump(tester, '404');

      expect(find.byKey(const Key('post-detail-not-found')), findsOneWidget);
      expect(find.text('Esta publicación ya no está'), findsOneWidget);
    });

    testWidgets('desde un enlace, atrás lleva al inicio', (tester) async {
      await pump(tester, '7');

      await tester.tap(find.byKey(const Key('post-detail-back')));
      await AppHarness.settle(tester);
      expect(find.text('inicio'), findsOneWidget);
    });

    Future<void> openComments(WidgetTester tester) async {
      await tester.tap(find.byKey(const Key('post-detail-comments')));
      await AppHarness.settle(tester);
    }

    // Regresión: un visitante podía escribir y recibía "Esta publicación no
    // acepta comentarios" en un post abierto.
    testWidgets('un visitante ve la invitación a iniciar sesión, no el campo', (
      tester,
    ) async {
      await sl<AuthCubit>().guest();
      await pump(tester, '7');
      await openComments(tester);

      expect(find.byKey(const Key('comment-input')), findsNothing);
      expect(find.text('Inicia sesión para comentar'), findsOneWidget);

      await tester.tap(find.byKey(const Key('comments-sign-in')));
      await AppHarness.settle(tester);
      // Al iniciar sesión se vuelve a la publicación, no al feed.
      expect(find.text('login-${AppRoutes.post('7')}'), findsOneWidget);
    });

    group('con sesión', () {
      setUp(() async {
        await AppHarness.bootstrap(
          initialPreferences: {
            'mock_session':
                '{"id":"creator-1","username":"elena_ux","name":"Elena Vega","role":"creator"}',
          },
        );
        posts = FakePostRepository([fakePost('7')]);
        sl
          ..unregister<PostRepository>()
          ..registerLazySingleton<PostRepository>(() => posts);
        await sl<AuthCubit>().restore();
      });

      testWidgets('una cuenta ve el campo para comentar', (tester) async {
        await pump(tester, '7');
        await openComments(tester);

        expect(find.byKey(const Key('comment-input')), findsOneWidget);
        expect(find.byKey(const Key('comments-sign-in')), findsNothing);
      });

      // Regresión: el aviso se mostraba en el messenger de la página, debajo
      // de la barrera del modal, y nadie lo veía.
      testWidgets('el aviso de un fallo se ve dentro de la hoja', (
        tester,
      ) async {
        await pump(tester, '7');
        await openComments(tester);

        posts.failNext = const ServerFailure('500');
        await tester.enterText(find.byKey(const Key('comment-input')), 'Hola');
        await tester.tap(find.byKey(const Key('comment-send')));
        await AppHarness.settle(tester);

        expect(
          find.descendant(
            of: find.byType(BottomSheet),
            matching: find.byType(SnackBar),
          ),
          findsOneWidget,
        );
      });
    });
  });

  group('a dónde lleva', () {
    AppNotification notification(NotificationType type, {String? postId}) =>
        AppNotification(
          id: 'n1',
          type: type,
          actor: 'Tomás',
          actorUsername: 'tomas',
          postId: postId,
          createdAt: DateTime(2026),
        );

    test('un like o un comentario abren la publicación', () {
      expect(
        notification(NotificationType.like, postId: '7').destination,
        NotificationDestination.post,
      );
      expect(
        notification(NotificationType.comment, postId: '7').destination,
        NotificationDestination.post,
      );
    });

    test('sin id de publicación (el mock) siguen yendo al perfil propio', () {
      expect(
        notification(NotificationType.like).destination,
        NotificationDestination.ownProfile,
      );
    });

    test('compartir una publicación lleva su enlace si hay base', () {
      expect(
        postShareText(fakePost('7'), baseUrl: 'https://nexo.example'),
        endsWith('\n\nhttps://nexo.example/p/7'),
      );
      expect(
        postShareText(fakePost('7'), baseUrl: ''),
        isNot(contains('http')),
      );
    });
  });
}
