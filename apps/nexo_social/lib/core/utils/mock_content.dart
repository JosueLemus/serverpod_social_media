import '../../features/feed/domain/entities/post.dart';

/// Seed content for the mock data source.
///
/// Timestamps are relative to process start so the feed always reads as fresh
/// — a fixed date would show "hace 3 años" at the demo.
abstract final class MockContent {
  static DateTime _ago(Duration elapsed) => DateTime.now().subtract(elapsed);

  static List<Post> seed() => [
    Post(
      id: 'post-1',
      author: 'elena_ux',
      name: 'Elena Vega',
      body:
          'Rediseñando la experiencia de micro-comunidades. ¿Qué parte de tu comunidad quieres hacer más humana?',
      tags: const ['UIUX', 'Flutter'],
      likes: 482,
      comments: 64,
      createdAt: _ago(const Duration(minutes: 25)),
      media: PostMedia.image,
      isLive: true,
      isFollowed: true,
      authorIsVerified: true,
    ),
    Post(
      id: 'post-2',
      author: 'carlos_dev',
      name: 'Carlos Méndez',
      body:
          'Publicamos una guía corta para organizar proyectos creativos sin perder foco. Disponible para toda la comunidad.',
      tags: const ['Creadores', 'Productividad'],
      likes: 319,
      comments: 41,
      createdAt: _ago(const Duration(hours: 3)),
      isFollowed: true,
      authorIsVerified: true,
      authorIsPro: true,
    ),
    Post(
      id: 'post-3',
      author: 'lucia_design',
      name: 'Lucía Torres',
      body:
          'Hoy comparto tres aprendizajes después de diseñar para audiencias en vivo.',
      tags: const ['Diseño', 'Live'],
      likes: 124,
      comments: 18,
      createdAt: _ago(const Duration(days: 1)),
      media: PostMedia.video,
      authorIsVerified: true,
    ),
  ];

  static const liveTitles = [
    'Masterclass de Diseño Mobile',
    'Café entre creadores',
    'Construyendo en público',
  ];
}
