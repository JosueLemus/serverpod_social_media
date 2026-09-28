import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../app/theme/app_tokens.dart';

/// La marca sobre su disco claro, con la insignia de verificado.
///
/// Es la forma "de presentación": onboarding, splash y muros de acceso.
/// Para el header usá [NexoWordmark], que es la marca chica junto al nombre.
class NexoLogo extends StatelessWidget {
  const NexoLogo({super.key, this.size = 92, this.showBadge = true});

  final double size;
  final bool showBadge;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        DecoratedBox(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(size * .08),
            child: SvgPicture.asset('assets/branding/nexo_mark.svg'),
          ),
        ),
        if (showBadge)
          Positioned(
            right: -size * .04,
            bottom: -size * .02,
            child: Container(
              width: size * .31,
              height: size * .31,
              decoration: const BoxDecoration(
                color: AppColors.primaryDeep,
                shape: BoxShape.circle,
                border: Border.fromBorderSide(
                  BorderSide(color: AppColors.surface, width: 2),
                ),
              ),
              child: Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: size * .21,
              ),
            ),
          ),
      ],
    ),
  );
}

/// La marca sola, sin disco ni insignia.
///
/// El asset trae su propio círculo de fondo, así que se recorta a un círculo
/// en vez de dibujarse suelto: sin el recorte el disco claro del SVG aparece
/// como un cuadrado detrás de la marca.
class NexoMark extends StatelessWidget {
  const NexoMark({super.key, this.size = 26});

  final double size;

  @override
  Widget build(BuildContext context) => ClipOval(
    child: SvgPicture.asset(
      'assets/branding/nexo_mark.svg',
      width: size,
      height: size,
    ),
  );
}

/// Marca + nombre, tal como aparece arriba a la izquierda en todas las
/// pantallas del diseño.
class NexoWordmark extends StatelessWidget {
  const NexoWordmark({super.key, this.markSize = 26});

  final double markSize;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      NexoMark(size: markSize),
      const SizedBox(width: AppSpacing.xs),
      Text(
        // Nombre propio: no se traduce y no se acorta.
        'Nexo',
        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18),
      ),
    ],
  );
}
