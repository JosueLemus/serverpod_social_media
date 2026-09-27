import 'package:dio/dio.dart';

abstract interface class FeedRemoteDataSource {
  Future<bool> healthCheck();
}

class FeedMockDataSource implements FeedRemoteDataSource {
  const FeedMockDataSource();
  @override
  Future<bool> healthCheck() async => true;
}

class FeedApiDataSource implements FeedRemoteDataSource {
  const FeedApiDataSource(this._dio);
  final Dio _dio;
  @override
  Future<bool> healthCheck() async {
    if (_dio.options.baseUrl.isEmpty) return false;
    final response = await _dio.get<void>('/health');
    return response.statusCode == 200;
  }
}
