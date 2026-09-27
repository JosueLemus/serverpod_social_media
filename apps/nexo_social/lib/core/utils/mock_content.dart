import '../../features/feed/domain/entities/post.dart';

abstract final class MockContent {
  static final posts = <Post>[
    const Post(
      id: 'post-1',
      author: 'elena_ux',
      name: 'Elena Vega',
      body:
          'Rediseñando la experiencia de micro-comunidades. ¿Qué parte de tu comunidad quieres hacer más humana?',
      tags: ['UIUX', 'Flutter'],
      likes: 482,
      comments: 64,
      isLive: true,
    ),
    const Post(
      id: 'post-2',
      author: 'carlos_dev',
      name: 'Carlos Méndez',
      body:
          'Publicamos una guía corta para organizar proyectos creativos sin perder foco. Disponible para toda la comunidad.',
      tags: ['Creadores', 'Productividad'],
      likes: 319,
      comments: 41,
    ),
    const Post(
      id: 'post-3',
      author: 'lucia_design',
      name: 'Lucía Torres',
      body:
          'Hoy comparto tres aprendizajes después de diseñar para audiencias en vivo.',
      tags: ['Diseño', 'Live'],
      likes: 124,
      comments: 18,
    ),
  ];
  static const liveTitles = [
    'Masterclass de Diseño Mobile',
    'Café entre creadores',
    'Construyendo en público',
  ];
  static const notifications = [
    'Marcos comenzó a seguirte',
    'Sofía comentó tu publicación',
    'Elena inicia un live en 15 min',
  ];

  static void addPost(String body) {
    posts.insert(
      0,
      Post(
        id: 'draft-${posts.length + 1}',
        author: 'nexo',
        name: 'Tu comunidad',
        body: body,
        tags: const ['Nuevo'],
        likes: 0,
        comments: 0,
      ),
    );
  }
}
