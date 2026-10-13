import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../app/theme/app_tokens.dart';
import '../../../../core/animations/app_motion.dart';
import '../../domain/entities/live_reaction.dart';

/// Reacciones efímeras del vivo (D7 del SDD 0011).
///
/// Son cinco fijas, no un emoji libre: el repertorio chico es lo que las hace
/// legibles sobre video a 24 px, y lo que deja al servidor saber qué contar
/// (la caja de un conteo tipado la limita el tamaño del enum, no la variedad
/// de un string).
///
/// La hoja arma la decisión; aplicar es del cubit (como la hoja de persona).
/// Para que el usuario vea el feedback de que su tap llegó, también publica
/// localmente en [LiveReactionBus]: así quien tocó ve el emoji flotar aun si
/// el servidor todavía no eco'ó el evento.
Future<void> showReactionsSheet(
  BuildContext context, {
  required void Function(LiveReactionKind kind) onPick,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    backgroundColor: AppColors.surface,
    builder: (sheetContext) => _ReactionsSheet(
      onPick: (kind) {
        Navigator.of(sheetContext).pop();
        onPick(kind);
      },
    ),
  );
}

class _ReactionsSheet extends StatelessWidget {
  const _ReactionsSheet({required this.onPick});

  final void Function(LiveReactionKind kind) onPick;

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
            Text('Reaccionar', style: text.titleLarge),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Tu reacción flota un momento y después desaparece.',
              style: text.bodySmall,
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (final kind in LiveReactionKind.values)
                  _ReactionButton(kind: kind, onTap: () => onPick(kind)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ReactionButton extends StatelessWidget {
  const _ReactionButton({required this.kind, required this.onTap});

  final LiveReactionKind kind;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: kind.semanticLabel,
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        key: Key('react-${kind.name}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Container(
          width: 56,
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.linerHigh,
            shape: BoxShape.circle,
          ),
          child: Text(kind.emoji, style: const TextStyle(fontSize: 28)),
        ),
      ),
    ),
  );
}

/// El bus que recibe las reacciones **recibidas** (propias y de los demás).
///
/// Lo escucha [LiveReactionsOverlay] y lo alimentan el cubit (cuando el
/// servidor emita `reaction`) y, por ahora, la hoja de reacciones directamente
/// — así quien tocó ve el feedback aunque el backend no haya devuelto el eco
/// todavía. El día que el servidor emita el evento, la hoja deja de publicar
/// local y el cubit es la única fuente.
class LiveReactionBus {
  LiveReactionBus._();

  static final LiveReactionBus instance = LiveReactionBus._();

  final _controller = StreamController<LiveReactionKind>.broadcast();

  Stream<LiveReactionKind> get stream => _controller.stream;

  void publish(LiveReactionKind kind) {
    if (!_controller.isClosed) _controller.add(kind);
  }

  /// Para los tests: deja el bus en un estado limpio entre pruebas sin
  /// cerrar el controller (el singleton vive la sesión entera).
  @visibleForTesting
  Stream<LiveReactionKind> get streamForTests => _controller.stream;
}

/// Un emoji que flota un instante desde el pie de pantalla hasta un poco más
/// arriba y se desvanece. Se dibuja sobre la sala por el padre: no sabe nada
/// del Stack ni del layout.
///
/// Está aislado en su propio [RepaintBoundary]: cada reacción programa un
/// repintado por frame, y sin la barrera eso sube al Stack entero —donde la
/// cara de la cámara se tesela y es cara de rasterizar.
class LiveReactionsOverlay extends StatefulWidget {
  const LiveReactionsOverlay({super.key, this.maxConcurrent = 12});

  /// Tope de emojis flotando al mismo tiempo. Con una banda llena de público,
  /// un vivo activo manda decenas por segundo y la pantalla se vuelve una
  /// pared de corazones.
  final int maxConcurrent;

  @override
  State<LiveReactionsOverlay> createState() => _LiveReactionsOverlayState();
}

class _LiveReactionsOverlayState extends State<LiveReactionsOverlay> {
  final _active = <_FloatingReaction>[];
  StreamSubscription<LiveReactionKind>? _subscription;
  final _random = math.Random();
  int _nextId = 0;

  @override
  void initState() {
    super.initState();
    _subscription = LiveReactionBus.instance.stream.listen(_spawn);
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    super.dispose();
  }

  void _spawn(LiveReactionKind kind) {
    if (!mounted) return;
    if (_active.length >= widget.maxConcurrent) {
      // Descartamos las más viejas, no la que llegó: quien tocó espera ver la
      // suya, no la de alguien que empezó 1,2 s antes.
      _active.removeAt(0);
    }
    setState(() {
      _active.add(
        _FloatingReaction(
          id: _nextId++,
          kind: kind,
          driftX: (_random.nextDouble() - .5) * 60,
          onDone: _remove,
        ),
      );
    });
  }

  void _remove(int id) {
    if (!mounted) return;
    setState(() => _active.removeWhere((r) => r.id == id));
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: Stack(
          fit: StackFit.expand,
          children: [
            for (final reaction in _active)
              _FloatingReactionView(
                key: ValueKey(reaction.id),
                reaction: reaction,
              ),
          ],
        ),
      ),
    );
  }
}

class _FloatingReaction {
  _FloatingReaction({
    required this.id,
    required this.kind,
    required this.driftX,
    required this.onDone,
  });

  final int id;
  final LiveReactionKind kind;
  final double driftX;
  final ValueChanged<int> onDone;
}

class _FloatingReactionView extends StatefulWidget {
  const _FloatingReactionView({super.key, required this.reaction});

  final _FloatingReaction reaction;

  @override
  State<_FloatingReactionView> createState() => _FloatingReactionViewState();
}

class _FloatingReactionViewState extends State<_FloatingReactionView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppMotion.reactionDuration,
  );

  @override
  void initState() {
    super.initState();
    _controller.forward().whenComplete(() {
      widget.reaction.onDone(widget.reaction.id);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = reduce ? 1.0 : _controller.value;
        // Sale desde ~24 px del pie y sube ~220 px, desplazándose un poco
        // horizontalmente. Opacidad al final; sin eso, el emoji se desvanece
        // en seco a la mitad.
        final dy = 24 + t * 220;
        final dx = widget.reaction.driftX * t;
        final opacity = reduce
            ? 1.0
            : (t < .85 ? 1.0 : 1 - (t - .85) / .15);
        return Positioned(
          bottom: dy,
          right: MediaQuery.sizeOf(context).width * .5 - 14 + dx,
          child: Opacity(
            opacity: opacity.clamp(0.0, 1.0),
            child: Text(
              widget.reaction.kind.emoji,
              style: const TextStyle(fontSize: 28),
            ),
          ),
        );
      },
    );
  }
}
