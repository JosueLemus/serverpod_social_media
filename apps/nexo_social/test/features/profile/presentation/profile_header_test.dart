import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_social/app/di/injection.dart';
import 'package:nexo_social/core/errors/failures.dart';
import 'package:nexo_social/features/auth/domain/entities/app_user.dart';
import 'package:nexo_social/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:nexo_social/features/feed/domain/entities/post_extras.dart';
import 'package:nexo_social/features/feed/presentation/widgets/photo_viewer.dart';
import 'package:nexo_social/features/profile/domain/entities/public_profile.dart';
import 'package:nexo_social/features/profile/domain/repositories/profile_repository.dart';
import 'package:nexo_social/features/profile/presentation/pages/profile_page.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

import '../../../support/app_harness.dart';

/// Un perfil con todo lo que puede tener: banner, foto, enlace y número de
/// publicaciones.
const _ana = PublicProfile(
  id: 'uuid-ana',
  username: 'ana',
  name: 'Ana Ruiz',
  bio: 'Fotografía y diseño editorial.',
  avatarUrl: 'https://api.nexo.dev/avatars/ana.jpg',
  coverUrl: 'https://api.nexo.dev/covers/ana.jpg',
  website: 'https://ana.dev/portfolio-de-fotografia-editorial-y-diseno',
  posts: 12,
  followers: 340,
  following: 21,
);

class _OneProfile implements ProfileRepository {
  _OneProfile(this.profile);

  final PublicProfile profile;

  @override
  Future<PublicProfile> byUsername(String username) async =>
      username == profile.username
      ? profile
      : throw const NotFoundFailure('profile');

  @override
  Future<PostPage> postsOf(PublicProfile profile, {String? cursor}) async =>
      const PostPage([]);

  @override
  Future<AccountStatus> statusOf(String username) async => AccountStatus.active;

  @override
  Stream<void> changes() => const Stream.empty();
}

/// El navegador del sistema, reemplazado: guarda qué se pidió abrir.
class _RecordingLauncher extends Fake
    with MockPlatformInterfaceMixin
    implements UrlLauncherPlatform {
  final opened = <String>[];

  @override
  LinkDelegate? get linkDelegate => null;

  @override
  Future<bool> canLaunch(String url) async => true;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    opened.add(url);
    return true;
  }
}

void main() {
  late _RecordingLauncher launcher;

  setUp(() async {
    // Una sesión iniciada: sin ella la pantalla espera la sesión o muestra
    // la invitación a crear una cuenta.
    await AppHarness.bootstrap(
      initialPreferences: {
        'mock_session':
            '{"id":"creator-1","username":"elena_ux","name":"Elena Vega","role":"creator"}',
      },
    );
    await sl<AuthCubit>().restore();
    sl
      ..unregister<ProfileRepository>()
      ..registerLazySingleton<ProfileRepository>(() => _OneProfile(_ana));
    UrlLauncherPlatform.instance = launcher = _RecordingLauncher();
  });

  Future<void> pumpProfile(WidgetTester tester, {double width = 390}) async {
    tester.view.physicalSize = Size(width, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      AppHarness.wrap(const ProfilePage(username: 'ana')),
    );
    await AppHarness.settle(tester);
  }

  testWidgets('shows the banner, the photo, the link and the post count', (
    tester,
  ) async {
    await pumpProfile(tester);

    expect(find.byKey(const Key('profile-cover')), findsOneWidget);
    expect(find.byKey(const Key('profile-avatar')), findsOneWidget);
    expect(find.byKey(const Key('profile-website')), findsOneWidget);
    // El enlace se muestra sin el esquema.
    expect(
      find.text('ana.dev/portfolio-de-fotografia-editorial-y-diseno'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('profile-posts')), findsOneWidget);
    expect(find.text('Publicaciones'), findsWidgets);
    expect(find.text('12'), findsOneWidget);
  });

  testWidgets('tapping the photo or the banner opens it full screen', (
    tester,
  ) async {
    await pumpProfile(tester);

    await tester.tap(find.byKey(const Key('profile-avatar')));
    await AppHarness.settle(tester);
    expect(find.byType(PhotoViewer), findsOneWidget);
    expect(
      tester.widget<PhotoViewer>(find.byType(PhotoViewer)).url,
      _ana.avatarUrl,
    );

    await tester.tap(find.byTooltip('Cerrar'));
    await AppHarness.settle(tester);
    expect(find.byType(PhotoViewer), findsNothing);

    await tester.tap(find.byKey(const Key('profile-cover')));
    await AppHarness.settle(tester);
    expect(
      tester.widget<PhotoViewer>(find.byType(PhotoViewer)).url,
      _ana.coverUrl,
    );
  });

  testWidgets('tapping the link opens it outside the app', (tester) async {
    await pumpProfile(tester);

    await tester.tap(find.byKey(const Key('profile-website')));
    await tester.pump();
    expect(launcher.opened, [_ana.website]);
  });

  testWidgets('nothing overflows at 320 with a long link', (tester) async {
    await pumpProfile(tester, width: 320);
    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('profile-website')), findsOneWidget);
  });

  testWidgets('someone without an account gets a way to join, not buttons '
      'that do nothing', (tester) async {
    await sl<AuthCubit>().signOut();
    await pumpProfile(tester);

    expect(find.byKey(const Key('profile-join')), findsOneWidget);
    expect(find.byKey(const Key('profile-follow')), findsNothing);
    expect(find.byKey(const Key('profile-message')), findsNothing);
    // El perfil se ve completo igual.
    expect(find.byKey(const Key('profile-avatar')), findsOneWidget);
  });
}
