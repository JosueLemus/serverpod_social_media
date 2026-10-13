import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_social/app/theme/app_theme.dart';
import 'package:nexo_social/core/share/share_sheet.dart';
import 'package:nexo_social/features/feed/domain/entities/post.dart';
import 'package:nexo_social/features/feed/presentation/utils/post_share_text.dart';
import 'package:nexo_social/features/feed/presentation/widgets/post_card.dart';
import 'package:nexo_social/features/live/domain/entities/live_session.dart';
import 'package:nexo_social/features/live/presentation/utils/live_share_text.dart';
import 'package:nexo_social/features/live/presentation/widgets/featured_live_card.dart';
import 'package:nexo_social/features/profile/domain/entities/public_profile.dart';
import 'package:nexo_social/features/profile/presentation/utils/profile_share_text.dart';
import 'package:share_plus_platform_interface/share_plus_platform_interface.dart';

/// La hoja del sistema, reemplazada: guarda lo que se le pidió compartir.
class _RecordingSharePlatform extends SharePlatform {
  final shared = <ShareParams>[];

  @override
  Future<ShareResult> share(ShareParams params) async {
    shared.add(params);
    return const ShareResult('ok', ShareResultStatus.success);
  }
}

void main() {
  final post = Post(
    id: '12',
    author: 'elena_ux',
    name: 'Elena Vega',
    body: 'Rediseñando la experiencia de micro-comunidades.',
    tags: const ['uiux', 'comunidades'],
    likes: 3,
    comments: 1,
    createdAt: DateTime(2026, 10, 11),
  );
  final onAir = LiveSession(
    id: '7',
    title: 'Masterclass',
    hostName: 'Elena Vega',
    hostUsername: 'elena_ux',
    status: LiveStatus.live,
  );

  group('el texto que se comparte', () {
    test('una publicación: quién, la cita y las etiquetas, sin enlace', () {
      expect(
        postShareText(post),
        'Elena Vega (@elena_ux) en Nexo:\n\n'
        '“Rediseñando la experiencia de micro-comunidades.”\n\n'
        '#uiux #comunidades',
      );
    });

    test('una publicación larga se corta en 280', () {
      final long = Post(
        id: '13',
        author: 'elena_ux',
        name: 'Elena Vega',
        body: 'a' * 400,
        tags: const [],
        likes: 0,
        comments: 0,
        createdAt: DateTime(2026, 10, 11),
      );
      final quote = postShareText(long).split('\n\n')[1];
      // Las comillas más 279 letras y la elipsis.
      expect(quote.length, 2 + 279 + 1);
      expect(quote, endsWith('…”'));
    });

    test('un vivo al aire y uno programado dicen cosas distintas', () {
      expect(
        liveShareText(onAir, baseUrl: ''),
        'Elena Vega (@elena_ux) está en vivo en Nexo: «Masterclass»',
      );
      expect(
        liveShareText(
          onAir.copyWith(status: LiveStatus.scheduled),
          baseUrl: '',
        ),
        startsWith('Elena Vega (@elena_ux) va a transmitir en Nexo'),
      );
    });

    test('con SHARE_BASE_URL el vivo y el perfil llevan su enlace', () {
      expect(
        liveShareText(onAir, baseUrl: 'https://nexo.example/'),
        endsWith('\n\nhttps://nexo.example/live/7'),
      );
      const profile = PublicProfile(
        id: 'u1',
        username: 'elena_ux',
        name: 'Elena Vega',
        bio: 'Diseño de producto',
      );
      expect(
        profileShareText(profile, baseUrl: 'https://nexo.example'),
        'Seguí a Elena Vega (@elena_ux) en Nexo\n\n'
        'Diseño de producto\n\n'
        'https://nexo.example/u/elena_ux',
      );
    });

    test('sin base no hay enlace: un enlace roto es peor que ninguno', () {
      expect(shareLink('/u/elena_ux', baseUrl: '  '), isNull);
    });
  });

  group('los botones abren la hoja del sistema', () {
    // `SharePlus.instance` toma la plataforma la primera vez que se usa, así
    // que hay una sola falsa para todo el grupo y se vacía entre tests.
    final platform = _RecordingSharePlatform();
    setUpAll(() => SharePlatform.instance = platform);

    setUp(platform.shared.clear);

    Future<void> pump(WidgetTester tester, Widget child) => tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.nexo,
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    );

    testWidgets('compartir una publicación', (tester) async {
      await pump(tester, PostCard(post: post, onLike: () {}, onSave: () {}));
      await tester.tap(find.byKey(const Key('share-12')));
      await tester.pump();

      expect(platform.shared.single.text, postShareText(post));
    });

    testWidgets('compartir el vivo destacado', (tester) async {
      await pump(
        tester,
        FeaturedLiveCard(
          session: onAir,
          hostUsername: 'elena_ux',
          onJoin: () {},
        ),
      );
      await tester.tap(find.byKey(const Key('share-live-7')));
      await tester.pump();

      expect(platform.shared.single.text, liveShareText(onAir));
    });
  });
}
