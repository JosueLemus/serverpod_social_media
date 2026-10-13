import 'package:flutter/material.dart';

import '../../../../app/theme/app_tokens.dart';
import '../../../../core/widgets/nexo_icon.dart';

/// Qué eligió el host al tocar "Salir" o "Terminar" (D6 del SDD 0011).
enum HostLeaveChoice {
  /// Cortar el vivo: pasa a replay o se finaliza según la máquina de estados
  /// del servidor.
  endLive,

  /// Salir de la sala sin cortar el vivo. El Studio sigue dueño de la
  /// transmisión.
  leaveOnAir,
}

/// La hoja que el host ve antes de salir o terminar un vivo.
///
/// Es una sola hoja porque la decisión es la misma —qué pasa con el vivo— y
/// alcanza con una confirmación. "Terminar" es rojo y filled (destructivo),
/// "Seguir al aire" es un outline (reversible), y "Cancelar" al pie del
/// handle de la hoja o botón atrás descarta sin hacer nada.
///
/// El `endOnly: true` esconde "Seguir al aire" y es lo que llega del botón
/// "Terminar" de la barra de acciones: ahí no se puede "seguir al aire", el
/// único resultado del tap es terminar.
///
/// Nunca llama al cubit por su cuenta: devuelve la decisión y el llamador
/// aplica. Es la misma regla que la hoja de persona.
Future<HostLeaveChoice?> showHostEndSheet(
  BuildContext context, {
  bool endOnly = false,
}) {
  return showModalBottomSheet<HostLeaveChoice>(
    context: context,
    showDragHandle: true,
    backgroundColor: AppColors.surface,
    builder: (sheetContext) => _HostEndSheet(endOnly: endOnly),
  );
}

class _HostEndSheet extends StatelessWidget {
  const _HostEndSheet({required this.endOnly});

  final bool endOnly;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              endOnly ? 'Terminar el vivo' : '¿Qué querés hacer?',
              style: text.titleLarge,
              key: const Key('host-end-sheet-title'),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              endOnly
                  ? 'Esto corta la transmisión para todos. El replay queda '
                      'disponible si lo activaste al programar el vivo.'
                  : 'Si cortás, el vivo termina para todos. Si seguís al aire, '
                      'podés volver desde el Studio.',
              style: text.bodySmall,
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton.icon(
              key: const Key('host-end-sheet-end'),
              onPressed: () =>
                  Navigator.of(context).pop(HostLeaveChoice.endLive),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: AppColors.onError,
                minimumSize: const Size.fromHeight(AppSizes.buttonHeight),
              ),
              icon: NexoIcon(
                NexoGlyph.close,
                size: 18,
                color: AppColors.onError,
              ),
              label: const Text('Terminar el vivo'),
            ),
            if (!endOnly) ...[
              const SizedBox(height: AppSpacing.xs),
              OutlinedButton.icon(
                key: const Key('host-end-sheet-leave-on-air'),
                onPressed: () =>
                    Navigator.of(context).pop(HostLeaveChoice.leaveOnAir),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(AppSizes.buttonHeight),
                ),
                icon: NexoIcon(NexoGlyph.logout, size: 18),
                label: const Text('Seguir al aire'),
              ),
            ],
            const SizedBox(height: AppSpacing.xs),
            // Cancelar explícito: en Android el back cierra la hoja y en iOS
            // también, pero una acción destructiva pide una salida visible.
            TextButton(
              key: const Key('host-end-sheet-cancel'),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
          ],
        ),
      ),
    );
  }
}
