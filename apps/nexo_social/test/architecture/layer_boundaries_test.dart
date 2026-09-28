import 'package:flutter_test/flutter_test.dart';

import 'source_scan.dart';

/// Clean Architecture, enforced instead of documented.
///
/// These violations are invisible at runtime — the app compiles and works —
/// so they only ever surface as pain months later, when the mock repositories
/// are swapped for the real backend and a widget turns out to be talking to
/// Dio directly.
void main() {
  final files = SourceScan.lib();

  group('the domain layer is pure', () {
    test('never imports Flutter', () {
      final offenders = files
          .where((file) => file.isDomain)
          .where((file) => file.code.contains("import 'package:flutter/"))
          .map((file) => file.path);

      expect(
        offenders,
        isEmpty,
        reason:
            'Un IconData, un Color o un Widget en domain/ atan las reglas de '
            'negocio al toolkit de UI. La presentación de un valor de dominio '
            'va en una extensión de presentation/ — ver LiveStatusUI y '
            'NotificationTypeUI.',
      );
    });

    test('never imports the data layer', () {
      final offenders = files
          .where((file) => file.isDomain)
          .where((file) => file.code.contains('/data/'))
          .map((file) => file.path);

      expect(
        offenders,
        isEmpty,
        reason:
            'La dependencia apunta hacia el dominio, nunca desde él. Un '
            'dominio que conoce su implementación no se puede sustituir.',
      );
    });
  });

  group('the presentation layer owns no I/O', () {
    const forbidden = {
      "import 'package:dio/": 'Dio',
      'SharedPreferences': 'SharedPreferences',
      'FlutterSecureStorage': 'FlutterSecureStorage',
    };

    test('no network or storage client is reachable from a widget', () {
      final offenders = <String>[];
      for (final file in files.where((file) => file.isPresentation)) {
        for (final entry in forbidden.entries) {
          if (file.code.contains(entry.key)) {
            offenders.add('${file.path} → ${entry.value}');
          }
        }
      }

      expect(
        offenders,
        isEmpty,
        reason:
            'Todo I/O pasa por un repositorio. Una pantalla que llama a la red '
            'no se puede testear sin red y duplica el parseo — así apareció '
            'una segunda copia de la lectura de sesión dentro de ProfilePage.',
      );
    });
  });

  group('the service locator is not a global variable', () {
    /// `sl<T>()` is legitimate when a screen builds its own cubit. Anywhere
    /// else it hides a dependency that should have been passed in.
    test(
      'sl<T>() outside a BlocProvider create: is declared, not accidental',
      () {
        // Each entry is a file allowed to resolve outside a provider, with the
        // reason. Adding one is a decision; leaving the list empty is the norm.
        const allowed = <String, String>{
          'lib/app/app.dart': 'compone el grafo: resuelve la sesión raíz',
          'lib/app/di/injection.dart': 'es el grafo',
          'lib/features/profile/presentation/pages/profile_page.dart':
              'la hoja de cerrar sesión corre fuera del árbol del provider',
        };

        final offenders = <String>[];
        for (final file in files.where((file) => file.isPresentation)) {
          if (allowed.containsKey(file.path)) continue;
          for (final line in file.lines) {
            final usesLocator = line.contains('sl<') || line.contains('sl()');
            if (!usesLocator) continue;
            // The common, sanctioned shape: `create: (_) => sl<X>()`.
            if (line.contains('create:') || line.contains('=> sl')) continue;
            offenders.add('${file.path}: ${line.trim()}');
          }
        }

        expect(
          offenders,
          isEmpty,
          reason: 'Pasá la dependencia por constructor.',
        );
      },
    );
  });

  group('every bloc state carries value equality', () {
    test('a state class extends Equatable', () {
      final offenders = <String>[];
      final statePattern = RegExp(
        r'^(?:abstract\s+)?(?:sealed\s+)?class\s+(\w*State|\w*Loaded|\w*Loading|\w*Failure)\b[^{]*',
        multiLine: true,
      );

      for (final file in files.where(
        (file) => file.path.contains('/presentation/bloc/'),
      )) {
        for (final match in statePattern.allMatches(file.code)) {
          final declaration = match.group(0)!;
          final name = match.group(1)!;
          final inherits =
              declaration.contains('extends') ||
              declaration.contains('implements');
          if (!inherits) {
            offenders.add('${file.path}: $name');
          }
        }
      }

      expect(
        offenders,
        isEmpty,
        reason:
            'props incompleto o ausente es un no-rebuild silencioso: el cubit '
            'emite, el estado compara igual y la UI no se redibuja.',
      );
    });
  });
}
