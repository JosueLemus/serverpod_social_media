import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_social/app/theme/app_tokens.dart';
import 'package:nexo_social/app/theme/nexo_themes.dart';

/// Contraste WCAG entre dos colores opacos.
double contrast(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  return (math.max(la, lb) + .05) / (math.min(la, lb) + .05);
}

void main() {
  tearDown(() => NexoThemes.activate(NexoThemes.byId(NexoThemes.defaultId)));

  test('Aurora es el tema por defecto', () {
    expect(NexoThemes.defaultId, 'aurora');
    expect(NexoThemes.byId(null).id, 'aurora');
  });

  test('los ids son únicos: es lo que se persiste', () {
    final ids = NexoThemes.all.map((t) => t.id).toList();
    expect(ids.toSet().length, ids.length);
  });

  test('un id desconocido cae al tema por defecto', () {
    // Una versión que tenía un tema que ésta ya no tiene.
    expect(NexoThemes.byId('tema-borrado').id, NexoThemes.defaultId);
  });

  test('activar un tema cambia la paleta y las fuentes de toda la app', () {
    final editorial = NexoThemes.byId('editorial');
    NexoThemes.activate(editorial);
    expect(AppColors.background, editorial.palette.liner);
    expect(AppColors.palette.isDark, isFalse);
    expect(NexoThemes.active.displayFont, 'InstrumentSerif');
  });

  test('toda fuente de un tema está declarada en el pubspec', () {
    // Una familia que no está empaquetada no falla: Flutter cae a la fuente
    // del sistema en silencio, y el tema se ve como otro.
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final missing = {
      for (final t in NexoThemes.all) ...[t.displayFont, t.textFont],
    }.where((family) => !pubspec.contains('family: $family'));
    expect(missing, isEmpty);
  });

  group('contraste', () {
    for (final theme in NexoThemes.all) {
      final p = theme.palette;
      test(theme.name, () {
        // Texto de lectura sobre el suelo y sobre una tarjeta.
        expect(contrast(p.textPrimary, p.liner), greaterThanOrEqualTo(7));
        expect(contrast(p.textPrimary, p.linerRaised), greaterThanOrEqualTo(7));
        expect(
          contrast(p.textSecondary, p.liner),
          greaterThanOrEqualTo(4.5),
          reason: 'el texto secundario se lee: no es decoración',
        );
        // La tinta sobre el sticker: CTA neutro, chip elegido, snackbar.
        expect(contrast(p.ink, p.sticker), greaterThanOrEqualTo(4.5));
        // El CTA de marca y lo que lleva encima.
        expect(
          contrast(p.onPrimaryDeep, p.primaryDeep),
          greaterThanOrEqualTo(3),
        );
        // La insignia EN VIVO.
        expect(contrast(p.onSecondary, p.secondary), greaterThanOrEqualTo(3));
        // El acento como texto: enlaces, hashtags.
        expect(contrast(p.primary, p.liner), greaterThanOrEqualTo(3));
        // Un avatar sin foto: la inicial en tinta sobre su vinilo.
        for (final vinyl in [
          p.vinylCyan,
          p.vinylBlue,
          p.vinylViolet,
          p.vinylMagenta,
          p.vinylLime,
          p.vinylGreen,
        ]) {
          expect(contrast(p.ink, vinyl), greaterThanOrEqualTo(3));
        }
      });
    }
  });

  test('el error es un rojo aunque el en vivo no lo sea', () {
    for (final theme in NexoThemes.all) {
      final hue = HSVColor.fromColor(theme.palette.error).hue;
      expect(hue >= 330 || hue <= 15, isTrue, reason: theme.name);
    }
  });

  test('sólo las planchas llevan troquel', () {
    expect(
      NexoThemes.all.where((t) => t.stickerCut).map((t) => t.id),
      unorderedEquals(['plancha', 'holo']),
    );
  });
}
