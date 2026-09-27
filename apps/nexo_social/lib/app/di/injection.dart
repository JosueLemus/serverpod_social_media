import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/network/dio_client.dart';
import '../../core/constants/environment.dart';
import '../../core/storage/mock_social_store.dart';
import '../../features/feed/data/datasources/feed_remote_data_source.dart';
import '../../features/feed/data/repositories/feed_repository_impl.dart';
import '../../features/feed/domain/repositories/feed_repository.dart';
import '../../features/feed/domain/usecases/get_feed_status.dart';
import '../../features/feed/presentation/bloc/feed_cubit.dart';
import '../../features/auth/data/datasources/auth_local_data_source.dart';
import '../../features/auth/data/repositories/mock_auth_repository.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/presentation/bloc/auth_cubit.dart';
import '../../features/posts/presentation/bloc/post_composer_cubit.dart';
import '../../features/live/data/repositories/mock_live_repository.dart';
import '../../features/live/domain/repositories/live_repository.dart';
import '../../features/live/presentation/bloc/live_list_cubit.dart';
import '../../features/moderation/data/repositories/mock_moderation_repository.dart';
import '../../features/moderation/domain/repositories/moderation_repository.dart';
import '../../features/moderation/presentation/bloc/moderation_cubit.dart';
import '../../features/subscriptions/data/repositories/mock_subscription_repository.dart';
import '../../features/subscriptions/domain/repositories/subscription_repository.dart';

final sl = GetIt.instance;
Future<void> configureDependencies() async {
  if (sl.isRegistered<Dio>()) return;
  sl.registerLazySingleton<FlutterSecureStorage>(
    () => const FlutterSecureStorage(),
  );
  final preferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton<MockSocialStore>(() => MockSocialStore(preferences));
  sl.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSource(preferences),
  );
  sl.registerLazySingleton<AuthRepository>(() => MockAuthRepository(sl()));
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
  sl.registerFactory(() => AuthCubit(sl()));
  sl.registerLazySingleton<LiveRepository>(MockLiveRepository.new);
  sl.registerFactory(() => LiveListCubit(sl()));
  sl.registerLazySingleton<ModerationRepository>(MockModerationRepository.new);
  sl.registerFactory(() => ModerationCubit(sl()));
  sl.registerLazySingleton<SubscriptionRepository>(
    MockSubscriptionRepository.new,
  );
}
