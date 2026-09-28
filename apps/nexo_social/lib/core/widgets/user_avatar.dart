import 'package:flutter/material.dart';

import '../../app/theme/app_tokens.dart';

/// El avatar circular de una persona.
///
/// No hay fotos en el build de hackathon, así que dibuja la inicial sobre el
/// degradado de marca. Es deliberadamente **no** un ícono genérico de persona:
/// con contenido mock, cinco avatares idénticos hacen que una lista de
/// creadores se lea como una sola fila repetida.
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.name,
    this.size = 40,
    this.ring,
    this.ringWidth = 2.5,
  });

  final String name;
  final double size;

  /// Anillo alrededor del avatar — rojo para "en vivo", verde para "online".
  /// Null lo dibuja sin anillo.
  final Color? ring;
  final double ringWidth;

  /// La primera **grafema**, no `name[0]`: un nombre que empieza con emoji o
  /// con una letra acentuada compuesta se cortaría a mitad de rune y saldría
  /// como el cuadrito de reemplazo.
  String get _initial =>
      name.characters.isEmpty ? '?' : name.characters.first.toUpperCase();

  @override
  Widget build(BuildContext context) {
    final avatar = Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDeep],
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        _initial,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: size * .4,
        ),
      ),
    );

    if (ring == null) return avatar;

    return Container(
      padding: EdgeInsets.all(ringWidth + 1.5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        // El anillo va separado del avatar por un aro del color de la
        // superficie: pegado al borde se lee como un borde del avatar y no
        // como un estado.
        border: Border.all(color: ring!, width: ringWidth),
      ),
      child: avatar,
    );
  }
}
