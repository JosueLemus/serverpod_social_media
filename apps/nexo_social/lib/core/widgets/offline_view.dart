import 'package:flutter/material.dart';

import '../../app/theme/app_tokens.dart';
import 'pills.dart';

/// Un artículo disponible sin conexión.
class SavedReading {
  const SavedReading({
    required this.title,
    required this.summary,
    required this.author,
    required this.minutes,
  });

  final String title;
  final String summary;
  final String author;
  final int minutes;
}

/// El modo sin conexión.
///
/// No es un error genérico. Quien perdió la red no necesita que le digan que
/// falló algo —ya lo sabe—: necesita saber qué **sí** puede hacer mientras
/// tanto. De ahí que la pantalla ofrezca borradores y lecturas guardadas en
/// vez de sólo un botón de reintentar.
///
/// Pendiente: no hay detección de conectividad todavía, así que esta vista se
/// muestra sólo cuando quien la invoca ya sabe que el fallo fue de red.
class AppOfflineView extends StatelessWidget {
  const AppOfflineView({
    super.key,
    required this.onRetry,
    this.draftCount = 0,
    this.savedReadings = const [],
  });

  final VoidCallback onRetry;
  final int draftCount;
  final List<SavedReading> savedReadings;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: AppSpacing.md),
      const _OfflineBanner(),
      const SizedBox(height: AppSpacing.lg),
      Center(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 86,
              height: 86,
              decoration: const BoxDecoration(
                color: AppColors.primarySurface,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cloud_off_rounded,
                size: 38,
                color: AppColors.primaryDeep,
              ),
            ),
            const Positioned(
              right: -8,
              top: -4,
              child: StatusBadge(label: 'Offline'),
            ),
          ],
        ),
      ),
      const SizedBox(height: AppSpacing.md),
      Text(
        'Sin conexión a Internet',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      const SizedBox(height: AppSpacing.xs),
      Text(
        'Verifica tu red Wi-Fi o datos móviles. Puedes seguir disfrutando de '
        'tus publicaciones guardadas y borradores locales mientras '
        'restablecemos la señal.',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AppColors.textSecondary,
          height: 1.45,
        ),
      ),
      const SizedBox(height: AppSpacing.md),
      SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          key: const Key('offline-retry'),
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded, size: 18),
          label: const Text('Reintentar conexión'),
        ),
      ),
      if (draftCount > 0) ...[
        const SizedBox(height: AppSpacing.xs),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.edit_note_rounded, size: 18),
            label: Text('Ver borradores guardados ($draftCount)'),
          ),
        ),
      ],
      if (savedReadings.isNotEmpty) ...[
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            const Icon(
              Icons.download_done_rounded,
              size: 16,
              color: AppColors.tertiary,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Lectura disponible offline',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Text(
              '${savedReadings.length} historias',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        for (final reading in savedReadings)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: _SavedReadingCard(reading: reading),
          ),
        const SizedBox(height: AppSpacing.xs),
        Center(
          child: Text(
            'Sin consumo de datos móviles',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    ],
  );
}

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.sm),
    decoration: BoxDecoration(
      color: AppColors.primarySurface,
      borderRadius: AppRadii.medium,
    ),
    child: Row(
      children: [
        const Icon(
          Icons.wifi_off_rounded,
          size: 18,
          color: AppColors.textOnBrandSurface,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Modo sin conexión',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                'Mostrando contenido guardado en caché',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        const StatusBadge(
          label: 'Caché',
          color: AppColors.surface,
          foreground: AppColors.textSecondary,
        ),
      ],
    ),
  );
}

class _SavedReadingCard extends StatelessWidget {
  const _SavedReadingCard({required this.reading});

  final SavedReading reading;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const StatusBadge(
                label: 'Guardado localmente',
                color: AppColors.successSurface,
                foreground: AppColors.tertiary,
              ),
              const Spacer(),
              Text(
                '${reading.minutes} min de lectura',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            reading.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 2),
          Text(
            reading.summary,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Expanded(
                child: Text(
                  reading.author,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              TextButton.icon(
                onPressed: () {},
                iconAlignment: IconAlignment.end,
                icon: const Icon(Icons.arrow_forward_rounded, size: 15),
                label: const Text('Leer ahora'),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  textStyle: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
