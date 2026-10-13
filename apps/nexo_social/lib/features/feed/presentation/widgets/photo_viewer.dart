import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../app/theme/app_tokens.dart';
import '../../../../core/animations/app_motion.dart';
import '../../../../core/widgets/nexo_icon.dart';

/// Abre la foto de una publicación a pantalla completa, con zoom.
///
/// Va en el Navigator raíz: tapa la barra de pestañas, que es lo que se
/// espera de un visor. Aparece con un fundido y no con Hero, porque el feed
/// por secciones puede mostrar el mismo post dos veces en la misma pantalla y
/// dos Hero con la misma etiqueta en una ruta revientan en debug.
Future<void> showPhotoViewer(BuildContext context, {required String url}) =>
    Navigator.of(context, rootNavigator: true).push(
      PageRouteBuilder<void>(
        opaque: false,
        transitionDuration: AppMotion.staticDuration,
        reverseTransitionDuration: AppMotion.feedbackDuration,
        pageBuilder: (context, animation, secondaryAnimation) =>
            PhotoViewer(url: url),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );

/// La foto sola sobre el liner: pellizcar para hacer zoom, arrastrar para
/// moverla y, sin zoom, deslizar hacia arriba o abajo para cerrar.
class PhotoViewer extends StatefulWidget {
  const PhotoViewer({super.key, required this.url});

  final String url;

  @override
  State<PhotoViewer> createState() => _PhotoViewerState();
}

class _PhotoViewerState extends State<PhotoViewer> {
  final _zoom = TransformationController();
  var _drag = 0.0;
  var _zoomed = false;

  /// Cuánto hay que arrastrar para que cerrar sea intencional y no un roce.
  static const _dismissDistance = 120.0;
  static const _dismissVelocity = 900.0;

  @override
  void initState() {
    super.initState();
    _zoom.addListener(_trackZoom);
  }

  /// Con zoom, arrastrar mueve la foto; sin zoom, la cierra. Se recalcula
  /// sólo cuando cambia de un modo al otro, no en cada cuadro del gesto.
  void _trackZoom() {
    final zoomed = _zoom.value.getMaxScaleOnAxis() > 1.01;
    if (zoomed != _zoomed) setState(() => _zoomed = zoomed);
  }

  @override
  void dispose() {
    _zoom
      ..removeListener(_trackZoom)
      ..dispose();
    super.dispose();
  }

  void _close() => unawaited(Navigator.of(context).maybePop());

  @override
  Widget build(BuildContext context) {
    // El fondo se aclara mientras se arrastra: es la señal de que soltar
    // cierra.
    final fade = (_drag.abs() / (_dismissDistance * 2.5)).clamp(0.0, 1.0);
    return Material(
      color: AppColors.background.withValues(alpha: 1 - fade * .6),
      child: Stack(
        fit: StackFit.expand,
        children: [
          GestureDetector(
            key: const Key('photo-viewer'),
            onVerticalDragUpdate: _zoomed
                ? null
                : (details) => setState(() => _drag += details.delta.dy),
            onVerticalDragEnd: _zoomed
                ? null
                : (details) {
                    final fling =
                        (details.primaryVelocity ?? 0).abs() > _dismissVelocity;
                    if (fling || _drag.abs() > _dismissDistance) {
                      _close();
                    } else {
                      setState(() => _drag = 0);
                    }
                  },
            child: Transform.translate(
              offset: Offset(0, _drag),
              child: InteractiveViewer(
                transformationController: _zoom,
                maxScale: 5,
                // Sin zoom no hay nada que mover: el arrastre es para cerrar.
                panEnabled: _zoomed,
                child: Center(
                  child: Image.network(
                    widget.url,
                    key: const Key('photo-viewer-image'),
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, progress) =>
                        progress == null
                        ? child
                        : CircularProgressIndicator(
                            color: AppColors.textSecondary,
                          ),
                    errorBuilder: (context, error, stack) => NexoIcon(
                      NexoGlyph.media,
                      size: 48,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xs),
                child: IconButton(
                  key: const Key('photo-viewer-close'),
                  tooltip: 'Cerrar',
                  onPressed: _close,
                  icon: NexoIcon(NexoGlyph.close, color: AppColors.sticker),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
