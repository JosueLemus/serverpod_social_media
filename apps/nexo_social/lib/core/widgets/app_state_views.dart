import 'package:flutter/material.dart';
import '../../app/theme/app_tokens.dart';

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
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
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
  final bool isOffline;
  @override
  Widget build(BuildContext context) => AppEmptyView(
    icon: isOffline ? Icons.wifi_off_outlined : Icons.error_outline,
    title: isOffline
        ? 'Sin conexión a Internet'
        : 'Algo no salió como esperábamos',
    message: isOffline
        ? 'Puedes continuar con contenido guardado y borradores locales.'
        : 'Inténtalo nuevamente o vuelve más tarde.',
    actionLabel: 'Reintentar conexión',
    onAction: onRetry,
  );
}

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

class FeedSkeleton extends StatelessWidget {
  const FeedSkeleton({super.key});
  @override
  Widget build(BuildContext context) => ListView.separated(
    padding: const EdgeInsets.only(top: AppSpacing.md),
    itemCount: 3,
    separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.md),
    itemBuilder: (context, index) => Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AppSkeleton(height: 40, width: 40),
                SizedBox(width: 12),
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
            SizedBox(height: 18),
            AppSkeleton(),
            SizedBox(height: 8),
            AppSkeleton(width: 220),
            SizedBox(height: 18),
            AppSkeleton(height: 120),
          ],
        ),
      ),
    ),
  );
}
