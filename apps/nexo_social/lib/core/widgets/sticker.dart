import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme/app_tokens.dart';
import '../../app/theme/nexo_themes.dart';

/// El borde de un sticker, y lo que dice sobre su estado.
///
/// Es el vocabulario de estados de toda la app, así que cada valor tiene un
/// solo significado:
enum StickerEdge {
  /// Recién despegado: borde troquelado blanco. Lo normal, y lo que queda
  /// cuando un vivo termina y pasa a replay.
  kissCut,

  /// **Al aire.** El foil holográfico del logo, girando despacio. Nada que no
  /// esté pasando ahora lleva este borde.
  holo,

  /// Todavía en la plancha: línea de corte punteada. Un show programado.
  dashed,

  /// Sin borde: la media sola, para cuando el sticker ya está dentro de otro.
  none,
}

/// Un sticker troquelado: lo que está adentro, recortado con su borde.
///
/// El radio exterior crece con el ancho del borde para que el troquel siga la
/// forma del contenido, como en el logo, en vez de dejar esquinas más
/// cerradas por fuera que por dentro.
class StickerFrame extends StatelessWidget {
  const StickerFrame({
    super.key,
    required this.child,
    this.edge = StickerEdge.kissCut,
    this.radius = 18,
    this.edgeWidth = AppStroke.kissCut,
    this.fill,
  });

  final Widget child;
  final StickerEdge edge;

  /// Radio del contenido. El del borde es éste más [edgeWidth].
  final double radius;
  final double edgeWidth;

  /// Relleno detrás del contenido, para media que todavía no cargó.
  final Color? fill;

  @override
  Widget build(BuildContext context) {
    final inner = ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: fill == null ? child : ColoredBox(color: fill!, child: child),
    );
    final outer = BorderRadius.circular(radius + edgeWidth);
    return switch (edge) {
      StickerEdge.none => inner,
      // Sin troquel en el tema, el borde "normal" es un filete fino: la
      // superficie ya separa la media del suelo.
      StickerEdge.kissCut when !NexoThemes.active.stickerCut => DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: AppColors.border),
        ),
        child: inner,
      ),
      StickerEdge.kissCut => DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.sticker,
          borderRadius: outer,
        ),
        child: Padding(padding: EdgeInsets.all(edgeWidth), child: inner),
      ),
      StickerEdge.holo => HoloRing(
        radius: radius + edgeWidth,
        width: edgeWidth,
        child: Padding(padding: EdgeInsets.all(edgeWidth), child: inner),
      ),
      StickerEdge.dashed => CustomPaint(
        foregroundPainter: _DashedCutPainter(
          radius: radius + edgeWidth,
          width: edgeWidth * .7,
        ),
        child: Padding(padding: EdgeInsets.all(edgeWidth), child: inner),
      ),
    };
  }
}

/// El foil holográfico del logo como anillo que gira.
///
/// Gira una vuelta cada ocho segundos: lo suficiente para que el ojo lo lea
/// como "vivo", nunca tanto como para competir con el video. Con "reducir
/// movimiento" queda quieto. Va aislado en su [RepaintBoundary]: sin esa
/// barrera el repintado de cada frame sube y vuelve a rasterizar la miniatura
/// que envuelve.
class HoloRing extends StatefulWidget {
  const HoloRing({
    super.key,
    required this.child,
    this.radius = 999,
    this.width = AppStroke.kissCut,
    this.shape = BoxShape.rectangle,
  });

  final Widget child;
  final double radius;
  final double width;
  final BoxShape shape;

  @override
  State<HoloRing> createState() => _HoloRingState();
}

class _HoloRingState extends State<HoloRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _turn = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 8),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _turn.stop();
    } else if (!_turn.isAnimating) {
      _turn.repeat();
    }
  }

  @override
  void dispose() {
    _turn.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: CustomPaint(
      painter: _HoloPainter(
        turn: _turn,
        radius: widget.radius,
        width: widget.width,
        shape: widget.shape,
      ),
      child: widget.child,
    ),
  );
}

class _HoloPainter extends CustomPainter {
  _HoloPainter({
    required this.turn,
    required this.radius,
    required this.width,
    required this.shape,
  }) : super(repaint: turn);

  final Animation<double> turn;
  final double radius;
  final double width;
  final BoxShape shape;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..shader = SweepGradient(
        colors: AppColors.holo,
        transform: GradientRotation(turn.value * 2 * math.pi),
      ).createShader(rect);
    final deflated = rect.deflate(width / 2);
    paint
      ..style = PaintingStyle.stroke
      ..strokeWidth = width;
    if (shape == BoxShape.circle) {
      canvas.drawOval(deflated, paint);
    } else {
      canvas.drawRRect(
        RRect.fromRectAndRadius(deflated, Radius.circular(radius - width / 2)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_HoloPainter old) =>
      old.radius != radius || old.width != width || old.shape != shape;
}

class _DashedCutPainter extends CustomPainter {
  _DashedCutPainter({required this.radius, required this.width});

  final double radius;
  final double width;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      (Offset.zero & size).deflate(width / 2),
      Radius.circular(radius),
    );
    final paint = Paint()
      ..color = AppColors.textSecondary
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round;
    const dash = 6.0, gap = 5.0;
    for (final metric in (Path()..addRRect(rrect)).computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += dash + gap) {
        canvas.drawPath(metric.extractPath(d, d + dash), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedCutPainter old) =>
      old.radius != radius || old.width != width;
}

/// Un color de vinilo estable para una persona o un tema.
///
/// Un avatar sin foto toma su color de su propio nombre: así una lista de
/// creadores es una plancha variada y no una fila del mismo círculo repetido,
/// y la misma persona tiene el mismo color en toda la app.
Color vinylFor(String seed) {
  final vinyls = [
    AppColors.vinylCyan,
    AppColors.vinylViolet,
    AppColors.vinylLime,
    AppColors.vinylMagenta,
    AppColors.vinylGreen,
    AppColors.vinylBlue,
  ];
  var hash = 0;
  for (final unit in seed.codeUnits) {
    hash = (hash * 31 + unit) & 0x7fffffff;
  }
  return vinyls[hash % vinyls.length];
}

/// Una tarjeta cortada como el gato del logo: relleno blanco, contorno de
/// tinta y troquel blanco alrededor, sobre el liner.
///
/// Es para lo que la pantalla quiere que se vea como **un objeto**: un
/// reporte en la cola, un plan, un aviso del staff. No para listas densas,
/// que van directo sobre el liner separadas por filetes.
///
/// Adentro todo se invierte: el texto pasa a tinta, el texto secundario a
/// [AppColors.inkSecondary] y el CTA (`FilledButton`) a relleno de tinta con
/// texto blanco, porque un sticker blanco sobre otro sticker blanco no se ve.
/// Lo que vaya adentro tiene que tomar sus colores del tema, no de
/// `AppColors.textPrimary`/`textSecondary` escritos a mano, y leerlo con un
/// contexto que esté **adentro** de la tarjeta (un `Builder` o un widget
/// hijo). Un `Theme.of(context).textTheme` leído antes de construir la
/// tarjeta trae el texto claro del liner: blanco sobre blanco.
class StickerCard extends StatelessWidget {
  const StickerCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.radius = 22,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final VoidCallback? onTap;

  static const _outline = AppStroke.ink;
  static const _cut = AppStroke.kissCut;

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context);
    final inked = base.textTheme.apply(
      bodyColor: AppColors.ink,
      displayColor: AppColors.ink,
    );
    final theme = base.copyWith(
      textTheme: inked.copyWith(
        bodySmall: inked.bodySmall?.copyWith(color: AppColors.inkSecondary),
      ),
      iconTheme: base.iconTheme.copyWith(color: AppColors.ink),
      dividerTheme: base.dividerTheme.copyWith(
        color: AppColors.ink.withValues(alpha: .12),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: base.filledButtonTheme.style?.copyWith(
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.disabled)
                ? AppColors.ink.withValues(alpha: .12)
                : AppColors.ink,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.disabled)
                ? AppColors.inkSecondary
                : AppColors.sticker,
          ),
          // Con la opacidad por estado de Material (8% hover, 10% presionado).
          // Un WidgetStatePropertyAll es opaco en todos los estados, y en
          // hover o al presionar tapaba la etiqueta con blanco.
          overlayColor: FilledButton.styleFrom(
            overlayColor: AppColors.sticker,
          ).overlayColor,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: base.outlinedButtonTheme.style?.copyWith(
          foregroundColor: WidgetStatePropertyAll(AppColors.ink),
          side: WidgetStatePropertyAll(
            BorderSide(color: AppColors.ink, width: 1.6),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: base.textButtonTheme.style?.copyWith(
          foregroundColor: WidgetStatePropertyAll(AppColors.primaryDeep),
        ),
      ),
      colorScheme: base.colorScheme.copyWith(
        onSurface: AppColors.ink,
        onSurfaceVariant: AppColors.inkSecondary,
      ),
    );

    Widget body = Padding(padding: padding, child: child);
    if (onTap != null) {
      body = InkWell(onTap: onTap, child: body);
    }
    // Sin troquel en el tema, la tarjeta es una superficie elevada más: con su
    // filete y los colores del tema, sin invertir el texto.
    if (!NexoThemes.active.stickerCut) {
      return Material(
        color: AppColors.surface,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius + _cut),
          side: BorderSide(color: AppColors.border),
        ),
        child: body,
      );
    }
    return Container(
      padding: const EdgeInsets.all(_cut),
      decoration: BoxDecoration(
        color: AppColors.sticker,
        borderRadius: BorderRadius.circular(radius + _outline + _cut),
      ),
      child: Container(
        padding: const EdgeInsets.all(_outline),
        decoration: BoxDecoration(
          color: AppColors.ink,
          borderRadius: BorderRadius.circular(radius + _outline),
        ),
        child: Material(
          color: AppColors.sticker,
          borderRadius: BorderRadius.circular(radius),
          clipBehavior: Clip.antiAlias,
          child: Theme(
            data: theme,
            child: DefaultTextStyle.merge(
              style: TextStyle(color: AppColors.ink),
              child: IconTheme.merge(
                data: IconThemeData(color: AppColors.ink),
                child: body,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
