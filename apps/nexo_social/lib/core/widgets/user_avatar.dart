import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../../app/theme/app_tokens.dart';
import 'sticker.dart';

/// El avatar de una persona, como un sticker redondo troquelado.
///
/// Sin foto dibuja la inicial en tinta sobre un vinilo que sale del propio
/// nombre ([vinylFor]): con contenido mock, cinco avatares del mismo color
/// harían que una lista de creadores se lea como una sola fila repetida.
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.name,
    this.size = 40,
    this.ring,
    this.ringWidth = 2.5,
    this.imageUrl,
    this.onAir = false,
  });

  final String name;
  final double size;

  /// Anillo de estado alrededor del sticker (verde = online). Null lo dibuja
  /// sólo con su borde troquelado blanco.
  final Color? ring;
  final double ringWidth;

  /// La foto real. Si falla o todavía no cargó, queda la inicial.
  final String? imageUrl;

  /// Al aire: el anillo pasa a ser el foil holográfico, que es la marca de
  /// "está pasando ahora" en toda la app. Gana sobre [ring].
  final bool onAir;

  /// La primera **grafema**, no `name[0]`: un nombre que empieza con emoji o
  /// con una letra acentuada compuesta se cortaría a mitad de rune y saldría
  /// como el cuadrito de reemplazo.
  String get _initial =>
      name.characters.isEmpty ? '?' : name.characters.first.toUpperCase();

  @override
  Widget build(BuildContext context) {
    final initial = ColoredBox(
      color: vinylFor(name),
      child: Center(
        child: Text(
          _initial,
          style: TextStyle(
            fontFamily: AppFonts.display,
            color: AppColors.ink,
            fontSize: size * .42,
            height: 1,
          ),
        ),
      ),
    );
    final face = imageUrl == null
        ? initial
        : Image.network(
            imageUrl!,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => initial,
            frameBuilder: (_, child, frame, sync) =>
                frame == null && !sync ? initial : child,
          );

    // El troquel: un aro blanco fino pegado a la cara del sticker. Escala con
    // el tamaño para que un avatar de lista y uno de perfil sean el mismo
    // sticker y no dos estilos.
    final cut = (size * .06).clamp(1.5, 4.0);
    final sticker = Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(cut),
      decoration: const BoxDecoration(
        color: AppColors.sticker,
        shape: BoxShape.circle,
      ),
      child: ClipOval(child: face),
    );

    if (!onAir && ring == null) return sticker;

    final gap = ringWidth + 1.5;
    if (onAir) {
      return HoloRing(
        shape: BoxShape.circle,
        width: ringWidth,
        child: Padding(padding: EdgeInsets.all(gap), child: sticker),
      );
    }
    return Container(
      padding: EdgeInsets.all(gap),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        // El anillo va separado del sticker por un aro del color del liner:
        // pegado al troquel se lee como parte del borde y no como un estado.
        border: Border.all(color: ring!, width: ringWidth),
      ),
      child: sticker,
    );
  }
}
