import 'package:flutter/material.dart';

import '../../app/theme/app_tokens.dart';

/// El tema de lo que se dibuja **sobre video**: la sala en vivo.
///
/// El video es la misma luz en un tema claro que en uno oscuro, así que el
/// texto encima no puede seguir al tema: en Editorial claro, el `textPrimary`
/// es casi negro y desaparecería sobre la transmisión. Adentro de esto, el
/// texto y los íconos por defecto son [AppColors.onMedia].
class MediaStageTheme extends StatelessWidget {
  const MediaStageTheme({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context);
    return Theme(
      data: base.copyWith(
        textTheme: base.textTheme.apply(
          bodyColor: AppColors.onMedia,
          displayColor: AppColors.onMedia,
        ),
        iconTheme: base.iconTheme.copyWith(color: AppColors.onMedia),
      ),
      child: child,
    );
  }
}
