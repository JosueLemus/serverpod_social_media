import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../app/theme/app_tokens.dart';

/// Los íconos propios de Nexo.
///
/// Salen de planchas generadas con GPT Image (Higgsfield) y vectorizadas, así
/// que comparten trazo, terminaciones redondeadas y escala: el mismo grosor
/// que el contorno del gato del logo. Los que tienen dos estados traen una
/// versión `_outline` (reposo) y una rellena (seleccionado o activo).
///
/// Mezclar acá un ícono de Material rompe exactamente eso: es otro trazo y
/// otra mano, y se nota en la barra antes que en ningún otro lado.
enum NexoGlyph {
  home,
  explore,
  activity,
  profile,
  studio,
  moderation,
  console,
  search,
  heart,
  comment,
  share,
  bookmark,
  live,
  settings,
  crown,
  media,
  calendar,
  flag,
  lock,
  hidden,
  trash,
  community,
  stats,
  play,
  check,
  edit,
  gift,
  equalizer,
  logout,
  refresh,
  switchAccount(file: 'switch_account'),
  sparkles,
  add(hasOutline: false),
  close(hasOutline: false),
  more(hasOutline: false),
  send(hasOutline: false),
  mic(hasOutline: false),
  micOff(file: 'mic_off', hasOutline: false),
  verified(hasOutline: false),
  star(hasOutline: false),
  back(hasOutline: false),
  forward(hasOutline: false),
  clock(hasOutline: false),
  link(hasOutline: false),
  emoji(hasOutline: false),
  hashtag(hasOutline: false),
  mention(hasOutline: false),
  flipCamera(file: 'flip_camera', hasOutline: false);

  const NexoGlyph({this.file, this.hasOutline = true});

  final String? file;

  /// Los de un solo trazo no tienen variante rellena: un "+" o una "X" no
  /// cambian de forma al activarse.
  final bool hasOutline;

  String asset({required bool filled}) {
    final base = file ?? name;
    return 'assets/icons/${filled || !hasOutline ? base : '${base}_outline'}.svg';
  }
}

class NexoIcon extends StatelessWidget {
  const NexoIcon(
    this.glyph, {
    super.key,
    this.size,
    this.color,
    this.filled = false,
    this.semanticLabel,
  });

  final NexoGlyph glyph;
  final double? size;

  /// Por defecto, el color del [IconTheme] más cercano: así un [NexoIcon]
  /// dentro de un botón toma el color del botón como lo haría un [Icon].
  final Color? color;

  /// Relleno = seleccionado o activo. En reposo va el contorno.
  final bool filled;

  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = IconTheme.of(context);
    final side = size ?? theme.size ?? AppSizes.icon;
    final tint = color ?? theme.color ?? AppColors.textPrimary;
    final picture = SvgPicture.asset(
      glyph.asset(filled: filled),
      width: side,
      height: side,
      colorFilter: ColorFilter.mode(tint, BlendMode.srcIn),
      excludeFromSemantics: semanticLabel == null,
      semanticsLabel: semanticLabel,
    );
    return SizedBox.square(dimension: side, child: picture);
  }
}
