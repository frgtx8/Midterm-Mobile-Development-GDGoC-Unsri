import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../constants/constants.dart';

/// Interceptor that automatically attaches JWT access tokens to requests,
/// and handles token refresh when a 401 TOKEN_EXPIRED response is received.
class AuthInterceptor extends Interceptor {
  final Dio dio;
  final FlutterSecureStorage secureStorage;
  bool _isRefreshing = false;

  AuthInterceptor({required this.dio, required this.secureStorage});

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // Skip auth header for login/register/refresh endpoints
    final noAuthPaths = [
      ApiConstants.login,
      ApiConstants.register,
      ApiConstants.refreshToken,
    ];

    if (!noAuthPaths.any((path) => options.path.contains(path))) {
      final token = await secureStorage.read(key: StorageKeys.accessToken);
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401 &&
        err.response?.data?['code'] == 'TOKEN_EXPIRED' &&
        !_isRefreshing) {
      _isRefreshing = true;

      try {
        final refreshToken = await secureStorage.read(key: StorageKeys.refreshToken);

        if (refreshToken == null) {
          _isRefreshing = false;
          return handler.next(err);
        }

        // Attempt to refresh the token
        final response = await Dio(BaseOptions(baseUrl: dio.options.baseUrl)).post(
          ApiConstants.refreshToken,
          data: {'refreshToken': refreshToken},
        );

        if (response.data['success'] == true) {
          final newAccessToken = response.data['data']['accessToken'];
          await secureStorage.write(key: StorageKeys.accessToken, value: newAccessToken);

          // Retry the failed request with new token
          final retryOptions = err.requestOptions;
          retryOptions.headers['Authorization'] = 'Bearer $newAccessToken';

          final retryResponse = await dio.fetch(retryOptions);
          _isRefreshing = false;
          return handler.resolve(retryResponse);
        }
      } catch (e) {
        // Refresh failed — clear tokens (user must re-login)
        await secureStorage.deleteAll();
      }

      _isRefreshing = false;
    }

    handler.next(err);
  }
}
