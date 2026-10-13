import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:nexo_client/nexo_client.dart' as serverpod;
import 'package:serverpod_auth_core_client/serverpod_auth_core_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/network/dio_client.dart';
import '../theme/nexo_themes.dart';
import '../../core/constants/environment.dart';
import '../../core/media/agora_live_media_engine.dart';
import '../../core/media/simulated_live_media_engine.dart';
import '../../core/mock/mock_platform.dart';
import '../../core/storage/mock_social_store.dart';
import '../../core/storage/session_storage.dart';
import '../../features/appearance/data/repositories/local_theme_preference_repository.dart';
import '../../features/appearance/domain/repositories/theme_preference_repository.dart';
import '../../features/appearance/presentation/bloc/theme_cubit.dart';
import '../../features/feed/data/repositories/mock_home_feed_repository.dart';
import '../../features/feed/data/repositories/mock_post_repository.dart';
import '../../features/feed/data/repositories/serverpod_home_feed_repository.dart';
import '../../features/feed/data/repositories/serverpod_post_repository.dart';
import '../../features/feed/domain/repositories/home_feed_repository.dart';
import '../../features/feed/domain/repositories/post_repository.dart';
import '../../features/feed/presentation/bloc/comments_cubit.dart';
import '../../features/feed/presentation/bloc/post_detail_cubit.dart';
import '../../features/feed/presentation/bloc/feed_cubit.dart';
import '../../features/auth/data/datasources/auth_local_data_source.dart';
import '../../features/auth/data/datasources/serverpod_auth_storage.dart';
import '../../features/auth/data/repositories/bridged_auth_repository.dart';
import '../../features/auth/data/repositories/mock_auth_repository.dart';
import '../../features/auth/data/repositories/serverpod_auth_repository.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/presentation/bloc/auth_cubit.dart';
import '../../features/posts/presentation/bloc/post_composer_cubit.dart';
import '../../features/explore/data/repositories/mock_discovery_repository.dart';
import '../../features/explore/data/repositories/serverpod_discovery_repository.dart';
import '../../features/explore/domain/repositories/discovery_repository.dart';
import '../../features/live/data/repositories/mock_live_repository.dart';
import '../../features/live/data/repositories/serverpod_live_repository.dart';
import '../../features/live/domain/repositories/live_repository.dart';
import '../../features/live/presentation/bloc/live_list_cubit.dart';
import '../../features/live/presentation/bloc/live_media_cubit.dart';
import '../../features/live/presentation/children/schedule_show/data/datasources/show_draft_local_data_source.dart';
import '../../features/live/presentation/children/schedule_show/data/repositories/mock_show_schedule_repository.dart';
import '../../features/live/presentation/children/schedule_show/data/repositories/serverpod_show_schedule_repository.dart';
import '../../features/live/presentation/children/schedule_show/domain/repositories/show_schedule_repository.dart';
import '../../features/live/presentation/children/schedule_show/domain/usecases/schedule_show.dart';
import '../../features/live/presentation/children/schedule_show/presentation/bloc/schedule_show_cubit.dart';
import '../../features/moderation/data/repositories/mock_moderation_repository.dart';
import '../../features/moderation/data/repositories/serverpod_moderation_repository.dart';
import '../../features/moderation/domain/repositories/moderation_repository.dart';
import '../../features/moderation/presentation/bloc/moderation_cubit.dart';
import '../../features/subscriptions/data/repositories/mock_subscription_repository.dart';
import '../../features/subscriptions/domain/repositories/subscription_repository.dart';
import '../../features/admin/data/repositories/mock_admin_repository.dart';
import '../../features/admin/domain/repositories/admin_repository.dart';
import '../../features/admin/presentation/bloc/account_detail_cubit.dart';
import '../../features/admin/presentation/bloc/admin_console_cubit.dart';
import '../../features/admin/presentation/bloc/audit_log_cubit.dart';
import '../../features/profile/data/repositories/mock_account_repository.dart';
import '../../features/profile/data/repositories/mock_follow_repository.dart';
import '../../features/profile/data/repositories/mock_profile_repository.dart';
import '../../features/profile/data/repositories/serverpod_account_repository.dart';
import '../../features/profile/data/repositories/serverpod_follow_repository.dart';
import '../../features/profile/data/repositories/serverpod_profile_repository.dart';
import '../../features/profile/domain/entities/follow.dart';
import '../../features/profile/domain/repositories/account_repository.dart';
import '../../features/profile/domain/repositories/follow_repository.dart';
import '../../features/profile/domain/repositories/profile_repository.dart';
import '../../features/profile/presentation/bloc/edit_profile_cubit.dart';
import '../../features/profile/presentation/bloc/follow_cubit.dart';
import '../../features/profile/presentation/bloc/follow_list_cubit.dart';
import '../../features/profile/presentation/bloc/public_profile_cubit.dart';
import '../../features/notifications/data/repositories/mock_notification_repository.dart';
import '../../features/notifications/data/repositories/serverpod_notification_repository.dart';
import '../../features/notifications/domain/repositories/notification_repository.dart';
import '../../features/notifications/presentation/bloc/activity_cubit.dart';
import '../../features/notifications/presentation/bloc/unread_activity_cubit.dart';
import '../../features/explore/data/repositories/mock_search_repository.dart';
import '../../features/explore/data/repositories/serverpod_search_repository.dart';
import '../../features/explore/domain/repositories/search_repository.dart';
import '../../features/messages/data/repositories/mock_messages_repository.dart';
import '../../features/messages/data/repositories/serverpod_messages_repository.dart';
import '../../features/messages/domain/repositories/messages_repository.dart';
import '../../features/messages/presentation/bloc/unread_messages_cubit.dart';

final sl = GetIt.instance;

/// Wires the object graph.
///
/// [preferences] exists so tests can inject an in-memory instance. Without it
/// this function awaits `SharedPreferences.getInstance()`, and in a test that
/// future never completes: the plugin has no platform side, so the await hangs
/// until the 10-minute suite timeout instead of failing. Two tests in this repo
/// died that way. `AppHarness.bootstrap()` is the supported entry point for
/// tests; production calls this with no arguments.
Future<void> configureDependencies({
  SharedPreferences? preferences,
  AuthSourceMode? authSourceMode,
}) async {
  if (sl.isRegistered<Dio>()) return;
  sl.registerLazySingleton<FlutterSecureStorage>(
    () => const FlutterSecureStorage(),
  );
  final resolved = preferences ?? await SharedPreferences.getInstance();
  sl.registerSingleton<SharedPreferences>(resolved);
  sl.registerLazySingleton<MockSocialStore>(() => MockSocialStore(sl()));
  // El servidor falso: una sola fuente de verdad para auth, vivos,
  // moderación y consola. Con `DATA_SOURCE=api`, los módulos que todavía no
  // tienen backend siguen cayendo acá.
  sl.registerLazySingleton<MockPlatform>(
    () => MockPlatform(sl()),
    dispose: (platform) => platform.dispose(),
  );
  sl.registerLazySingleton<SessionStorage>(() => SessionStorage(sl()));
  sl.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSource(sl()),
  );
  final resolvedAuthSource = authSourceMode ?? Environment.authSourceMode;
  if (resolvedAuthSource == AuthSourceMode.serverpod) {
    sl.registerLazySingleton<StreamController<AuthSuccess?>>(
      () => StreamController<AuthSuccess?>.broadcast(),
      dispose: (controller) => controller.close(),
    );
    sl.registerLazySingleton<ServerpodSecureKeyValueStorage>(
      () => ServerpodSecureKeyValueStorage(
        sl(),
        apiBaseUrl: Environment.apiBaseUrl,
      ),
    );
    sl.registerLazySingleton<ClientAuthSessionManager>(
      () => ClientAuthSessionManager(
        storage: KeyValueClientAuthSuccessStorage(
          keyValueStorage: sl<ServerpodSecureKeyValueStorage>(),
        ),
        onAuthInfoChanged: sl<StreamController<AuthSuccess?>>().add,
      ),
    );
    sl.registerLazySingleton<serverpod.Client>(() {
      final client = serverpod.Client(Environment.apiBaseUrl);
      client.authSessionManager = sl<ClientAuthSessionManager>();
      return client;
    });
  }
  sl.registerLazySingleton<AuthRepository>(
    () => resolvedAuthSource == AuthSourceMode.mock
        ? MockAuthRepository(sl(), sl())
        // El puente lleva la sesión real a los módulos que todavía son mock
        // (vivos, programar, consola). Se va con M7: ver SDD 0007, F1.
        : BridgedAuthRepository(
            ServerpodAuthRepository(
              sl<serverpod.Client>(),
              sl<ClientAuthSessionManager>(),
              sl<StreamController<AuthSuccess?>>().stream,
            ),
            sl(),
          ),
  );
  sl.registerLazySingleton<DioClient>(
    () => DioClient(
      readToken: () => sl<FlutterSecureStorage>().read(key: 'access_token'),
    ),
  );
  sl.registerLazySingleton<Dio>(() => sl<DioClient>().instance);
  // Con cuentas reales, publicaciones reales: el mismo interruptor que el
  // login. Una sesión de Serverpod leyendo el feed del mock es justo la doble
  // fuente de verdad que el SDD 0004 quiere sacar.
  sl.registerLazySingleton<PostRepository>(
    () => resolvedAuthSource == AuthSourceMode.mock
        ? MockPostRepository(sl())
        : ServerpodPostRepository(sl<serverpod.Client>()),
  );
  // Seguir y el inicio por secciones (SDD 0008, M2): el mismo interruptor.
  sl.registerLazySingleton<FollowRepository>(
    () => resolvedAuthSource == AuthSourceMode.mock
        ? MockFollowRepository(sl(), sl())
        : ServerpodFollowRepository(sl<serverpod.Client>()),
  );
  sl.registerLazySingleton<HomeFeedRepository>(
    () => resolvedAuthSource == AuthSourceMode.mock
        ? MockHomeFeedRepository(sl(), lives: sl(), follows: sl())
        : ServerpodHomeFeedRepository(sl<serverpod.Client>()),
  );
  sl.registerFactory(() => FeedCubit(sl(), sl(), sl()));
  sl.registerFactoryParam<PostDetailCubit, String, void>(
    (postId, _) => PostDetailCubit(sl(), postId),
  );
  sl.registerFactoryParam<CommentsCubit, String, void>(
    (postId, _) => CommentsCubit(sl(), postId),
  );
  sl.registerFactory(() => PostComposerCubit(sl()));
  // The session is app-wide state: the router redirect, the shell and the
  // profile all read the same instance. A factory here would hand each caller
  // its own cubit, so signing out in one place would leave the others
  // authenticated.
  sl.registerLazySingleton<AuthCubit>(() => AuthCubit(sl()));
  // El tema es del dispositivo y lo lee la raíz: singleton por lo mismo que la
  // sesión. Con un factory, la pantalla de Temas cambiaría un cubit que la
  // raíz no escucha.
  sl.registerLazySingleton<ThemePreferenceRepository>(
    () => LocalThemePreferenceRepository(sl()),
  );
  sl.registerLazySingleton<ThemeCubit>(
    () => ThemeCubit(sl(), defaultId: NexoThemes.defaultId),
  );
  // Actividad (SDD 0008, M5): con cuentas reales, la bandeja del servidor.
  sl.registerLazySingleton<NotificationRepository>(
    () => resolvedAuthSource == AuthSourceMode.mock
        ? MockNotificationRepository()
        : ServerpodNotificationRepository(sl<serverpod.Client>()),
  );
  sl.registerFactory(() => ActivityCubit(sl()));
  // El badge de la campana sigue a la sesión, como el shell: singleton, o
  // cada pestaña tendría su propio conteo.
  sl.registerLazySingleton<UnreadActivityCubit>(
    () => UnreadActivityCubit(sl(), sl<AuthCubit>()),
  );
  // Mensajes directos (SDD 0010). El badge de "Mensajes" es app-wide como el
  // de la campana.
  sl.registerLazySingleton<MessagesRepository>(
    () => resolvedAuthSource == AuthSourceMode.mock
        ? MockMessagesRepository(() => sl<MockPlatform>().sessionAccountId)
        : ServerpodMessagesRepository(sl<serverpod.Client>()),
  );
  sl.registerLazySingleton<UnreadMessagesCubit>(
    () => UnreadMessagesCubit(sl(), sl<AuthCubit>()),
  );
  // Con cuentas reales, vivos reales (SDD 0006): el mismo interruptor que
  // los posts. Una sesión de Serverpod sobre los vivos del mock es la que
  // contestaba "sin permiso" a todos.
  sl.registerLazySingleton<LiveRepository>(
    () => resolvedAuthSource == AuthSourceMode.mock
        ? MockLiveRepository(sl())
        : ServerpodLiveRepository(
            sl<serverpod.Client>(),
            sl<ClientAuthSessionManager>(),
          ),
  );
  sl.registerFactory(() => LiveListCubit(sl()));
  // Un motor por pantalla: el cubit lo libera al cerrarse. Sin App ID de
  // Agora, el video es el simulado de siempre.
  sl.registerFactory<LiveMediaEngine>(
    () => Environment.agoraAppId.isEmpty
        ? SimulatedLiveMediaEngine()
        : AgoraLiveMediaEngine(Environment.agoraAppId),
  );
  sl.registerFactory(() => LiveMediaCubit(sl(), sl()));
  sl.registerLazySingleton<ShowScheduleRepository>(
    () => resolvedAuthSource == AuthSourceMode.mock
        ? MockShowScheduleRepository(sl(), ShowDraftLocalDataSource(sl()))
        : ServerpodShowScheduleRepository(
            sl<serverpod.Client>(),
            sl<ClientAuthSessionManager>(),
            ShowDraftLocalDataSource(sl()),
          ),
  );
  sl.registerLazySingleton(() => ScheduleShow(sl()));
  sl.registerFactory(() => ScheduleShowCubit(sl(), sl()));
  // El buscador de Inicio: con cuentas reales, `client.search`.
  sl.registerLazySingleton<SearchRepository>(
    () => resolvedAuthSource == AuthSourceMode.mock
        ? MockSearchRepository(sl(), sl())
        : ServerpodSearchRepository(sl<serverpod.Client>()),
  );
  sl.registerLazySingleton<DiscoveryRepository>(
    () => resolvedAuthSource == AuthSourceMode.mock
        ? MockDiscoveryRepository()
        : ServerpodDiscoveryRepository(sl<serverpod.Client>(), sl()),
  );
  // Con cuentas reales, la cola junta los reportes de posts del servidor con
  // los del chat, que siguen en el mock hasta M6 (SDD 0007, F9).
  sl.registerLazySingleton<ModerationRepository>(
    () => resolvedAuthSource == AuthSourceMode.mock
        ? MockModerationRepository(sl())
        : ServerpodModerationRepository(sl<serverpod.Client>(), sl()),
  );
  sl.registerFactory(() => ModerationCubit(sl()));
  sl.registerLazySingleton<SubscriptionRepository>(
    MockSubscriptionRepository.new,
  );
  sl.registerLazySingleton<AdminRepository>(() => MockAdminRepository(sl()));
  sl.registerFactory(() => AdminConsoleCubit(sl()));
  sl.registerFactory(() => AuditLogCubit(sl()));
  sl.registerFactoryParam<AccountDetailCubit, String, void>(
    (accountId, _) => AccountDetailCubit(sl(), accountId),
  );
  // El perfil lee de `profiles` y `posts.byAuthor` con cuentas reales. La
  // plataforma mock sólo aporta las sanciones de la consola, hasta M6.
  sl.registerLazySingleton<ProfileRepository>(
    () => resolvedAuthSource == AuthSourceMode.mock
        ? MockProfileRepository(sl(), sl())
        : ServerpodProfileRepository(sl<serverpod.Client>(), sl()),
  );
  sl.registerFactoryParam<PublicProfileCubit, String, void>(
    (username, _) => PublicProfileCubit(sl(), sl(), sl(), username, sl()),
  );
  sl.registerFactoryParam<FollowListCubit, String, FollowListKind>(
    (userId, kind) => FollowListCubit(sl(), userId, kind),
  );
  sl.registerFactoryParam<FollowCubit, String, void>(
    (username, _) => FollowCubit(sl(), sl(), username),
  );
  // La cuenta propia (SDD 0008, M1): editar el perfil, la foto y volverse
  // creador. El mock no la modela y lo dice.
  sl.registerLazySingleton<AccountRepository>(
    () => resolvedAuthSource == AuthSourceMode.mock
        ? const MockAccountRepository()
        : ServerpodAccountRepository(sl<serverpod.Client>()),
  );
  sl.registerFactory(() => EditProfileCubit(sl(), sl()));
}

/// Tears the graph down so the next `configureDependencies()` rebuilds it.
///
/// `configureDependencies` short-circuits on an already-registered graph, so
/// without this every test in a suite would share one container: whatever the
/// first test wrote to SharedPreferences would leak into the rest and the
/// suite would pass or fail depending on file order.
Future<void> resetDependencies() => sl.reset();
