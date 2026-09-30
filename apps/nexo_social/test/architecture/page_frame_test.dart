import 'package:flutter_test/flutter_test.dart';

import 'source_scan.dart';

/// Every screen inside the shell is built on `NexoPage`.
///
/// This is the guard for the bug that started the rewrite: the shell hands the
/// child zero horizontal padding so a profile cover can bleed to the edges,
/// and no page put it back. The feed's title rendered half off-screen and the
/// last filter chip ran past the right edge, on every phone — and nothing
/// failed, because a missing EdgeInsets is an absence.
void main() {
  final files = SourceScan.lib();

  /// Screens reached outside the shell — they are pushed full screen and carry
  /// their own Scaffold and AppBar, so the shell's frame does not apply.
  /// Each one states why.
  const outsideShell = <String, String>{
    'lib/features/auth/presentation/pages/auth_pages.dart':
        'splash y alta de cuenta: fuera del shell, sin barra de navegación',
    'lib/features/auth/presentation/pages/suspended_page.dart':
        'sesión revocada: fuera del shell, no hay a dónde navegar',
    'lib/features/posts/presentation/pages/create_post_page.dart':
        'compositor a pantalla completa, empujado sobre el shell',
    'lib/features/live/presentation/children/schedule_show/presentation/pages/schedule_show_page.dart':
        'agendar un show es una tarea a pantalla completa, empujada sobre el '
        'shell como el compositor',
    'lib/features/subscriptions/presentation/pages/subscription_page.dart':
        'paywall empujado sobre el shell',
    'lib/features/profile/presentation/pages/profile_page.dart':
        'portada full-bleed con slivers propios y tab bar fijada',
    'lib/features/profile/presentation/pages/account_profile_view.dart':
        'parte de profile_page: el perfil propio de una cuenta sin contenido',
    'lib/features/live/presentation/pages/live_room_page.dart':
        'sala inmersiva: el video ocupa todo y el chrome flota encima, así que '
        'no lleva margen ni ancho de lectura',
  };

  test('a shell page uses NexoPage', () {
    final offenders = <String>[];

    for (final file in files.where(
      (file) => file.path.contains('/presentation/pages/'),
    )) {
      if (outsideShell.containsKey(file.path)) continue;
      if (file.code.contains('NexoPage')) continue;
      offenders.add(file.path);
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'Sin NexoPage la pantalla queda sin margen lateral, sin ancho de '
          'lectura en escritorio y sin respiro bajo la barra inferior. Si es '
          'una pantalla de fuera del shell, declarala en outsideShell con su '
          'motivo.',
    );
  });

  test('a shell page does not nest its own Scaffold', () {
    // The shell already provides one. A second adds another Material layer,
    // its own bottom inset and its own snack-bar host, so a SnackBar shown
    // from the page appears behind the tab bar.
    const allowedScaffold = outsideShell;
    final offenders = <String>[];

    for (final file in files.where(
      (file) => file.path.contains('/presentation/pages/'),
    )) {
      if (allowedScaffold.containsKey(file.path)) continue;
      if (file.code.contains('Scaffold(')) offenders.add(file.path);
    }

    expect(offenders, isEmpty);
  });
}
