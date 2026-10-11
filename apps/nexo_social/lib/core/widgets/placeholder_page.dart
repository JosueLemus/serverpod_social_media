import 'package:flutter/material.dart';

import '../../app/theme/app_tokens.dart';
import 'nexo_mascot.dart';

/// Una pantalla que todavía no existe, dicha sin vueltas y con el gato.
class PlaceholderPage extends StatelessWidget {
  const PlaceholderPage({
    super.key,
    required this.title,
    required this.description,
    this.icon = Icons.auto_awesome_outlined,
    this.mascot = NexoMascot.peek,
  });
  final String title;
  final String description;

  /// Se mantiene por compatibilidad; se dibuja sólo si [mascot] es null.
  final IconData icon;
  final NexoMascot? mascot;

  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (mascot != null)
              MascotIllustration(mascot!, size: 160)
            else
              Icon(icon, size: 48, color: AppColors.textSecondary),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              description,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    ),
  );
}
