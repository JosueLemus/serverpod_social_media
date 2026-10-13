import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../../app/theme/app_tokens.dart';

const _logoAsset = 'assets/branding/nexo_logo.webp';

/// El logo: el gato sticker con su borde holográfico.
///
/// Es la forma de presentación (onboarding, splash, muros de acceso). Para el
/// header usá [NexoWordmark], que es la marca chica junto al nombre.
class NexoLogo extends StatelessWidget {
  const NexoLogo({super.key, this.size = 92});

  final double size;

  @override
  Widget build(BuildContext context) => _LogoImage(size: size);
}

/// La marca sola, a tamaño de header.
class NexoMark extends StatelessWidget {
  const NexoMark({super.key, this.size = 28});

  final double size;

  @override
  Widget build(BuildContext context) => _LogoImage(size: size);
}

/// Marca + nombre, tal como aparece arriba a la izquierda en todas las
/// pantallas.
class NexoWordmark extends StatelessWidget {
  const NexoWordmark({super.key, this.markSize = 30});

  final double markSize;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      NexoMark(size: markSize),
      const SizedBox(width: AppSpacing.xs),
      // Flexible: a 320 la barra de marca lleva además la sección, sus
      // acciones y el avatar, y un nombre de ancho fijo la desbordaba.
      Flexible(
        child: Text(
          // Nombre propio: no se traduce y no se acorta.
          'nexo',
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.clip,
          style: TextStyle(
            fontFamily: AppFonts.display,
            fontSize: 20,
            height: 1,
            letterSpacing: -.4,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    ],
  );
}

class _LogoImage extends StatelessWidget {
  const _LogoImage({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.maybeDevicePixelRatioOf(context) ?? 3;
    return Semantics(
      label: 'Nexo',
      image: true,
      child: Image.asset(
        _logoAsset,
        width: size,
        height: size,
        fit: BoxFit.contain,
        // Se decodifica al tamaño en que se dibuja: el asset es de 512 px y
        // en el header ocupa 30.
        cacheWidth: (size * dpr).round(),
        filterQuality: FilterQuality.medium,
        excludeFromSemantics: true,
      ),
    );
  }
}
