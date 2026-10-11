import 'package:flutter/material.dart';

/// El gato de la marca, en cada momento en que la app necesita compañía.
///
/// Es el mismo personaje del logo (generado con GPT Image usando el logo como
/// referencia), así que un estado vacío o un error todavía se siente Nexo y no
/// un ícono gris de "nada por aquí".
enum NexoMascot {
  /// Bienvenida: saluda con la pata.
  wave,

  /// Vacío genérico: espía detrás de un sticker despegado.
  peek,

  /// La plancha está en blanco: no hay publicaciones todavía.
  empty,

  /// Algo se rompió: enredado en el ovillo.
  error,

  /// Sin conexión: dormido junto al cable desenchufado.
  offline,

  /// Salió bien.
  success,

  /// Actividad vacía.
  bell,

  /// Búsqueda sin resultados.
  search,

  /// Salir al aire.
  mic,

  /// Contenido o cuenta bloqueada.
  lock,

  /// VIP, membresías.
  crown,

  /// Moderación: la cola está limpia.
  shield,

  /// Studio: la cámara lista.
  camera,

  /// Me gusta, guardados.
  heart,

  /// Shows programados.
  calendar;

  String get asset => 'assets/mascot/$name.webp';
}

class MascotIllustration extends StatelessWidget {
  const MascotIllustration(this.mascot, {super.key, this.size = 148});

  final NexoMascot mascot;
  final double size;

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.maybeDevicePixelRatioOf(context) ?? 3;
    return Image.asset(
      mascot.asset,
      width: size,
      height: size,
      fit: BoxFit.contain,
      // El asset es de 560 px: decodificarlo entero para dibujarlo a 120
      // guarda en memoria un bitmap cuatro veces más grande que lo que se ve.
      cacheWidth: (size * dpr).round(),
      excludeFromSemantics: true,
      gaplessPlayback: true,
    );
  }
}
