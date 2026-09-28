import 'package:flutter/material.dart';

import '../../app/theme/app_tokens.dart';
import 'offline_view.dart';

/// Empty state: says what is missing and offers the one action that fixes it.
class AppEmptyView extends StatelessWidget {
  const AppEmptyView({
    super.key,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
    this.icon = Icons.auto_awesome_outlined,
  });

  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 34,
          backgroundColor: AppColors.primarySurface,
          child: Icon(icon, color: AppColors.primary, size: 32),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          message,
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.md),
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
          icon: Icons.error_outline,
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

/// One grey bar of a loading placeholder.
class AppSkeleton extends StatelessWidget {
  const AppSkeleton({super.key, this.height = 18, this.width});

  final double height;
  final double? width;

  @override
  Widget build(BuildContext context) => Container(
    height: height,
    width: width,
    decoration: BoxDecoration(
      color: AppColors.border.withValues(alpha: .65),
      borderRadius: AppRadii.small,
    ),
  );
}

/// Breathes its child so a slow load reads as working rather than frozen.
///
/// The pulse is wrapped in a [RepaintBoundary]: without one, the repaint it
/// schedules every frame walks up to the nearest boundary and re-rasterises
/// whatever else shares that layer.
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

/// Loading placeholder for the feed.
///
/// A Column, not a ListView: it is rendered as one item inside the page's
/// sliver list, and a nested scrollable there has no bounded height — it
/// throws on layout rather than degrading.
class FeedSkeleton extends StatelessWidget {
  const FeedSkeleton({super.key, this.count = 3});

  final int count;

  @override
  Widget build(BuildContext context) => PulsingSkeleton(
    child: Column(
      children: [
        for (var index = 0; index < count; index++)
          const Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.md),
            child: _SkeletonCard(),
          ),
      ],
    ),
  );
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) => const Card(
    child: Padding(
      padding: EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppSkeleton(height: 42, width: 42),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppSkeleton(width: 110),
                    SizedBox(height: 6),
                    AppSkeleton(width: 80, height: 12),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          AppSkeleton(),
          SizedBox(height: AppSpacing.xs),
          AppSkeleton(width: 220),
          SizedBox(height: AppSpacing.md),
          AppSkeleton(height: 140),
        ],
      ),
    ),
  );
}
