import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:nexo_client/nexo_client.dart' as serverpod;
import 'package:serverpod_auth_core_client/serverpod_auth_core_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/network/dio_client.dart';
import '../../core/constants/environment.dart';
import '../../core/mock/mock_platform.dart';
import '../../core/storage/mock_social_store.dart';
import '../../core/storage/session_storage.dart';
import '../../features/feed/data/datasources/feed_remote_data_source.dart';
import '../../features/feed/data/repositories/feed_repository_impl.dart';
import '../../features/feed/domain/repositories/feed_repository.dart';
import '../../features/feed/domain/usecases/get_feed_status.dart';
import '../../features/feed/presentation/bloc/feed_cubit.dart';
import '../../features/auth/data/datasources/auth_local_data_source.dart';
import '../../features/auth/data/datasources/serverpod_auth_storage.dart';
import '../../features/auth/data/repositories/mock_auth_repository.dart';
import '../../features/auth/data/repositories/serverpod_auth_repository.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/presentation/bloc/auth_cubit.dart';
import '../../features/posts/presentation/bloc/post_composer_cubit.dart';
import '../../features/explore/data/repositories/mock_discovery_repository.dart';
import '../../features/explore/domain/repositories/discovery_repository.dart';
import '../../features/live/data/repositories/mock_live_repository.dart';
import '../../features/live/domain/repositories/live_repository.dart';
import '../../features/live/presentation/bloc/live_list_cubit.dart';
import '../../features/moderation/data/repositories/mock_moderation_repository.dart';
import '../../features/moderation/domain/repositories/moderation_repository.dart';
import '../../features/moderation/presentation/bloc/moderation_cubit.dart';
import '../../features/subscriptions/data/repositories/mock_subscription_repository.dart';
import '../../features/subscriptions/domain/repositories/subscription_repository.dart';
import '../../features/admin/data/repositories/mock_admin_repository.dart';
import '../../features/admin/domain/repositories/admin_repository.dart';
import '../../features/admin/presentation/bloc/account_detail_cubit.dart';
import '../../features/admin/presentation/bloc/admin_console_cubit.dart';
import '../../features/admin/presentation/bloc/audit_log_cubit.dart';
import '../../features/profile/data/repositories/mock_profile_repository.dart';
import '../../features/profile/domain/repositories/profile_repository.dart';

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
        : ServerpodAuthRepository(
            sl<serverpod.Client>(),
            sl<ClientAuthSessionManager>(),
            sl<StreamController<AuthSuccess?>>().stream,
          ),
  );
  sl.registerLazySingleton<DioClient>(
    () => DioClient(
      readToken: () => sl<FlutterSecureStorage>().read(key: 'access_token'),
    ),
  );
  sl.registerLazySingleton<Dio>(() => sl<DioClient>().instance);
  sl.registerLazySingleton<FeedRemoteDataSource>(
    () => Environment.dataSourceMode == DataSourceMode.mock
        ? const FeedMockDataSource()
        : FeedApiDataSource(sl()),
  );
  sl.registerLazySingleton<FeedRepository>(() => FeedRepositoryImpl(sl()));
  sl.registerLazySingleton(() => GetFeedStatus(sl()));
  sl.registerFactory(() => FeedCubit(sl(), sl()));
  sl.registerFactory(() => PostComposerCubit(sl()));
  // The session is app-wide state: the router redirect, the shell and the
  // profile all read the same instance. A factory here would hand each caller
  // its own cubit, so signing out in one place would leave the others
  // authenticated.
  sl.registerLazySingleton<AuthCubit>(() => AuthCubit(sl()));
  sl.registerLazySingleton<LiveRepository>(() => MockLiveRepository(sl()));
  sl.registerFactory(() => LiveListCubit(sl()));
  sl.registerLazySingleton<DiscoveryRepository>(MockDiscoveryRepository.new);
  sl.registerLazySingleton<ModerationRepository>(
    () => MockModerationRepository(sl()),
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
  sl.registerLazySingleton<ProfileRepository>(
    () => MockProfileRepository(sl()),
  );
}

/// Tears the graph down so the next `configureDependencies()` rebuilds it.
///
/// `configureDependencies` short-circuits on an already-registered graph, so
/// without this every test in a suite would share one container: whatever the
/// first test wrote to SharedPreferences would leak into the rest and the
/// suite would pass or fail depending on file order.
Future<void> resetDependencies() => sl.reset();
