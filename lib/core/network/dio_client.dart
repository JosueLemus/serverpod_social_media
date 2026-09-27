import 'package:dio/dio.dart';
import '../constants/environment.dart';
import '../errors/exceptions.dart';

class DioClient {
  DioClient({Dio? dio, Future<String?> Function()? readToken})
    : _dio = dio ?? Dio(BaseOptions(baseUrl: Environment.apiBaseUrl)) {
    _dio.interceptors.add(_AuthInterceptor(readToken));
    if (Environment.enableNetworkLogs) _dio.interceptors.add(LogInterceptor());
  }
  final Dio _dio;
  Dio get instance => _dio;
  Future<Response<T>> get<T>(String path) async {
    try {
      return await _dio.get<T>(path);
    } on DioException catch (error) {
      throw _map(error);
    }
  }

  Exception _map(DioException error) =>
      error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.connectionTimeout
      ? const NetworkException('Connection unavailable')
      : ServerException(
          error.message ?? 'Request failed',
          statusCode: error.response?.statusCode,
        );
}

class _AuthInterceptor extends Interceptor {
  _AuthInterceptor(this.readToken);
  final Future<String?> Function()? readToken;
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await readToken?.call();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}
