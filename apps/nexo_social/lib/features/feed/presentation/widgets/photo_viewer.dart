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

/// La foto sola sobre el liner, como en cualquier app de fotos:
///
/// - **pellizcar** hace zoom (hasta 4×) y, con zoom, arrastrar la mueve;
/// - **doble toque** acerca al punto tocado y otro doble toque la devuelve;
/// - **deslizar** con un dedo y sin zoom la cierra.
///
/// Todos los gestos pasan por el mismo reconocedor de escala del
/// `InteractiveViewer`. Antes, deslizar para cerrar era un `GestureDetector`
/// de arrastre vertical que envolvía al visor: en la arena de gestos ganaba
/// apenas el primer dedo se movía en vertical, antes de que apoyara el
/// segundo, y el pellizco no llegaba nunca.
class PhotoViewer extends StatefulWidget {
  const PhotoViewer({super.key, required this.url});

  final String url;

  /// El zoom máximo, y hasta dónde acerca el doble toque.
  static const maxScale = 4.0;
  static const doubleTapScale = 2.5;

  @override
  State<PhotoViewer> createState() => _PhotoViewerState();
}

class _PhotoViewerState extends State<PhotoViewer>
    with SingleTickerProviderStateMixin {
  final _zoom = TransformationController();
  late final AnimationController _zoomAnimation = AnimationController(
    vsync: this,
    duration: AppMotion.feedbackDuration,
  )..addListener(_stepZoomAnimation);
  Animation<Matrix4>? _zoomTween;

  var _drag = 0.0;
  var _zoomed = false;

  /// Si el gesto en curso tuvo dos dedos alguna vez: entonces es un pellizco
  /// y no puede terminar cerrando el visor, aunque al final quede uno solo.
  var _multiTouch = false;
  Offset? _doubleTapAt;

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
    _zoomAnimation.dispose();
    _zoom
      ..removeListener(_trackZoom)
      ..dispose();
    super.dispose();
  }

  void _close() => unawaited(Navigator.of(context).maybePop());

  void _onInteractionStart(ScaleStartDetails details) {
    _zoomAnimation.stop();
    _multiTouch = details.pointerCount > 1;
  }

  void _onInteractionUpdate(ScaleUpdateDetails details) {
    if (details.pointerCount > 1) {
      _multiTouch = true;
      // Si venía deslizando para cerrar y apoyó otro dedo, es un pellizco: la
      // foto vuelve a su lugar.
      if (_drag != 0) setState(() => _drag = 0);
      return;
    }
    if (_zoomed || _multiTouch) return;
    setState(() => _drag += details.focalPointDelta.dy);
  }

  void _onInteractionEnd(ScaleEndDetails details) {
    final dismissing = !_zoomed && !_multiTouch && _drag != 0;
    _multiTouch = false;
    if (!dismissing) return;
    final fling = details.velocity.pixelsPerSecond.dy.abs() > _dismissVelocity;
    if (fling || _drag.abs() > _dismissDistance) {
      _close();
    } else {
      setState(() => _drag = 0);
    }
  }

  /// Doble toque: acerca al punto tocado o, si ya hay zoom, vuelve al
  /// tamaño original. Animado, para que se entienda qué pasó.
  void _onDoubleTap() {
    final at = _doubleTapAt;
    if (at == null) return;
    final Matrix4 target;
    if (_zoomed) {
      target = Matrix4.identity();
    } else {
      const scale = PhotoViewer.doubleTapScale;
      // Escalar alrededor del punto tocado: queda bajo el dedo.
      target = Matrix4.identity()
        ..translateByDouble(-at.dx * (scale - 1), -at.dy * (scale - 1), 0, 1)
        ..scaleByDouble(scale, scale, 1, 1);
    }
    _zoomTween = Matrix4Tween(begin: _zoom.value, end: target).animate(
      // Sin rebote: el zoom que se pasa y vuelve se lee como un error.
      CurvedAnimation(parent: _zoomAnimation, curve: Curves.easeOutCubic),
    );
    unawaited(_zoomAnimation.forward(from: 0));
  }

  void _stepZoomAnimation() {
    final tween = _zoomTween;
    if (tween != null) _zoom.value = tween.value;
  }

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
          Transform.translate(
            offset: Offset(0, _drag),
            child: GestureDetector(
              key: const Key('photo-viewer'),
              onDoubleTapDown: (details) =>
                  _doubleTapAt = details.localPosition,
              onDoubleTap: _onDoubleTap,
              child: InteractiveViewer(
                key: const Key('photo-viewer-zoom'),
                transformationController: _zoom,
                maxScale: PhotoViewer.maxScale,
                // Sin zoom no hay nada que mover: el arrastre de un dedo es
                // para cerrar, y lo lee `_onInteractionUpdate`.
                panEnabled: _zoomed,
                onInteractionStart: _onInteractionStart,
                onInteractionUpdate: _onInteractionUpdate,
                onInteractionEnd: _onInteractionEnd,
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
