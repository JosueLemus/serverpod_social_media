import 'package:flutter_test/flutter_test.dart';

import 'source_scan.dart';

/// Colours come from `AppColors`, routes from `AppRoutes`.
///
/// Both bugs are the same shape: a literal compiles, renders and looks almost
/// right, so nothing ever fails — the app just drifts into two blues and a
/// path nobody can grep for.
void main() {
  final files = SourceScan.lib();

  group('colours', () {
    /// The palette itself, and the one sanctioned exception: a third party's
    /// brand colour is theirs, and re-theming it is a branding violation, not
    /// a fix. Each entry states why.
    const allowed = <String, String>{
      'lib/app/theme/app_tokens.dart': 'es la paleta',
      'lib/features/auth/presentation/pages/auth_pages.dart':
          'el azul de Google en el botón de identidad es marca de un tercero',
    };

    test('no raw hex outside the palette', () {
      final hex = RegExp(r'Color\(0x[0-9a-fA-F]{8}\)');
      final offenders = <String>[];

      for (final file in files) {
        if (allowed.containsKey(file.path)) continue;
        for (final match in hex.allMatches(file.code)) {
          offenders.add('${file.path}: ${match.group(0)}');
        }
      }

      expect(
        offenders,
        isEmpty,
        reason:
            'Un literal suelto es invisible a un cambio de tema. Agregá el '
            'token a AppColors, o declará la excepción con su motivo.',
      );
    });

    test('no Material colour constants outside the palette', () {
      // Colors.white / Colors.black / Colors.transparent are allowed: they are
      // absolutes, not palette choices, and they are what you put on top of a
      // brand surface.
      // The lookbehind matters: without it `Colors\.` also matches the tail
      // of `AppColors.error`, so the guard reports the palette itself.
      final material = RegExp(
        r'(?<![A-Za-z])Colors\.(?!white|black|transparent)[a-z]\w*',
      );
      final offenders = <String>[];

      for (final file in files) {
        if (allowed.containsKey(file.path)) continue;
        for (final match in material.allMatches(file.code)) {
          offenders.add('${file.path}: ${match.group(0)}');
        }
      }

      expect(
        offenders,
        isEmpty,
        reason: 'Colors.blue no es el azul de Nexo. Usá AppColors.',
      );
    });
  });

  group('routes', () {
    test('navigation never takes a path literal', () {
      // `context.go('/live')`, `.push("/u/x")`, `.replace('/')` — the forms
      // that hardcode a path at a call site.
      final literalNavigation = RegExp(
        '''\\.(go|push|replace|pushReplacement)\\(\\s*['"]/''',
      );
      final offenders = <String>[];

      for (final file in files) {
        // AppRoutes is where the strings live.
        if (file.path.endsWith('app_routes.dart')) continue;
        for (final line in file.lines) {
          if (literalNavigation.hasMatch(line)) {
            offenders.add('${file.path}: ${line.trim()}');
          }
        }
      }

      expect(
        offenders,
        isEmpty,
        reason:
            'Un literal mal escrito compila y aterriza en la pantalla de ruta '
            'no encontrada en runtime. Usá AppRoutes.',
      );
    });

    test('route paths are declared only in AppRoutes', () {
      // GoRoute(path: …) must reference a constant, so renaming a route is one
      // edit rather than a grep.
      final routePath = RegExp('''path:\\s*['"]''');
      final offenders = <String>[];

      for (final file in files) {
        if (file.path.endsWith('app_routes.dart')) continue;
        for (final line in file.lines) {
          if (routePath.hasMatch(line)) {
            offenders.add('${file.path}: ${line.trim()}');
          }
        }
      }

      expect(offenders, isEmpty);
    });
  });
}
