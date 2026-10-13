import 'package:flutter/material.dart';

import '../../app/theme/app_tokens.dart';
import 'nexo_mascot.dart';
import 'offline_view.dart';

/// Estado vacío: el gato, qué falta y la única acción que lo arregla.
class AppEmptyView extends StatelessWidget {
  const AppEmptyView({
    super.key,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
    this.icon = Icons.auto_awesome_outlined,
    this.mascot = NexoMascot.peek,
  });

  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  /// Se mantiene por compatibilidad con quien ya lo pasa. Sólo se dibuja si
  /// [mascot] es null: un estado vacío de Nexo lo acompaña el gato, no un
  /// ícono gris.
  final IconData icon;

  final NexoMascot? mascot;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (mascot != null)
          MascotIllustration(mascot!)
        else
          Icon(icon, color: AppColors.textSecondary, size: 40),
        const SizedBox(height: AppSpacing.md),
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xs),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 340),
          child: Text(
            message,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        FilledButton(onPressed: onAction, child: Text(actionLabel)),
      ],
    ),
  );
}

class AppErrorView extends StatelessWidget {
  const AppErrorView({
    super.key,
    required this.onRetry,
    this.isOffline = false,
  });

  final VoidCallback onRetry;

  /// Perder la red y que el servidor falle son dos promesas distintas al
  /// usuario: una dice que el problema se puede esperar, la otra que es
  /// nuestro. Sin conexión, la vista además ofrece lo que sí funciona.
  final bool isOffline;

  @override
  Widget build(BuildContext context) => isOffline
      ? AppOfflineView(onRetry: onRetry, savedReadings: _demoReadings)
      : AppEmptyView(
          mascot: NexoMascot.error,
          title: 'Algo no salió como esperábamos',
          message: 'Inténtalo nuevamente o vuelve más tarde.',
          actionLabel: 'Reintentar',
          onAction: onRetry,
        );

  /// Mock hasta que exista caché offline de verdad. Nombrado así para que no
  /// se confunda con contenido realmente descargado.
  static const _demoReadings = [
    SavedReading(
      title: 'Arquitecturas modernas de streaming y micro-frontends',
      summary: 'Reflexiones sobre diseño reactivo y sincronización de estado.',
      author: 'Elena Rostova',
      minutes: 4,
    ),
    SavedReading(
      title: 'Guía de diseño para experiencias táctiles',
      summary: 'Cómo convertir micro-estados y pantallas en sistemas.',
      author: 'Marc Dupont',
      minutes: 8,
    ),
  ];
}

/// Una barra de un placeholder de carga.
class AppSkeleton extends StatelessWidget {
  const AppSkeleton({super.key, this.height = 18, this.width});

  final double height;
  final double? width;

  @override
  Widget build(BuildContext context) => Container(
    height: height,
    width: width,
    decoration: BoxDecoration(
      color: AppColors.linerHigh,
      borderRadius: AppRadii.small,
    ),
  );
}

/// Hace respirar a su hijo para que una carga lenta se lea como trabajo y no
/// como algo congelado.
///
/// El pulso va dentro de un [RepaintBoundary]: sin él, el repintado que
/// programa cada frame sube hasta la barrera más cercana y vuelve a
/// rasterizar todo lo que comparte esa capa.
class PulsingSkeleton extends StatefulWidget {
  const PulsingSkeleton({super.key, required this.child});

  final Widget child;

  @override
  State<PulsingSkeleton> createState() => _PulsingSkeletonState();
}

class _PulsingSkeletonState extends State<PulsingSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: FadeTransition(
      opacity: Tween<double>(
        begin: .45,
        end: 1,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut)),
      child: widget.child,
    ),
  );
}

/// Placeholder de carga del feed.
///
/// Un Column, no un ListView: se dibuja como un ítem dentro de la lista de
/// slivers de la página, y un scrollable anidado ahí no tiene alto acotado:
/// revienta en layout en vez de degradarse.
class FeedSkeleton extends StatelessWidget {
  const FeedSkeleton({super.key, this.count = 3});

  final int count;

  @override
  Widget build(BuildContext context) => PulsingSkeleton(
    child: Column(
      children: [
        for (var index = 0; index < count; index++)
          const Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.lg),
            // La key va en el hijo y no en el Padding: los Padding son
            // hermanos, y una key repetida entre hermanos revienta el árbol.
            child: _SkeletonPost(key: Key('feed-skeleton-item')),
          ),
      ],
    ),
  );
}

/// Con la forma de un post sobre el liner: avatar redondo, dos líneas y la
/// media. Sin tarjeta alrededor, igual que el post de verdad.
class _SkeletonPost extends StatelessWidget {
  const _SkeletonPost({super.key});

  @override
  Widget build(BuildContext context) => const Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          ClipOval(child: AppSkeleton(height: 42, width: 42)),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppSkeleton(width: 120, height: 14),
                SizedBox(height: 6),
                AppSkeleton(width: 80, height: 11),
              ],
            ),
          ),
        ],
      ),
      SizedBox(height: AppSpacing.md),
      AppSkeleton(height: 14),
      SizedBox(height: AppSpacing.xs),
      AppSkeleton(width: 220, height: 14),
      SizedBox(height: AppSpacing.md),
      ClipRRect(borderRadius: AppRadii.medium, child: AppSkeleton(height: 180)),
    ],
  );
}
