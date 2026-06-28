import 'package:dio/dio.dart';

import '../../../../core/constants/constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/user_model.dart';

/// Remote data source for authentication API calls.
class AuthRemoteDataSource {
  final Dio dio;

  AuthRemoteDataSource({required this.dio});

  /// Register a new user. Returns user data and tokens.
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final response = await dio.post(
        ApiConstants.register,
        data: {'name': name, 'email': email, 'password': password},
      );

      if (response.data['success'] == true) {
        return response.data['data'];
      }
      throw ServerException(
        message: response.data['message'] ?? 'Registration failed',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Login with email and password. Returns user data and tokens.
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await dio.post(
        ApiConstants.login,
        data: {'email': email, 'password': password},
      );

      if (response.data['success'] == true) {
        return response.data['data'];
      }
      throw AuthException(
        message: response.data['message'] ?? 'Login failed',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Logout and invalidate refresh token.
  Future<void> logout(String? refreshToken) async {
    try {
      await dio.post(
        ApiConstants.logout,
        data: refreshToken != null ? {'refreshToken': refreshToken} : {},
      );
    } on DioException {
      // Silently ignore logout errors — we clear local data anyway
    }
  }

  /// Get current user profile.
  Future<UserModel> getProfile() async {
    try {
      final response = await dio.get(ApiConstants.profile);

      if (response.data['success'] == true) {
        return UserModel.fromJson(response.data['data']['user']);
      }
      throw ServerException(
        message: response.data['message'] ?? 'Failed to get profile',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Update user profile.
  Future<UserModel> updateProfile({required String name}) async {
    try {
      final response = await dio.put(
        ApiConstants.profile,
        data: {'name': name},
      );

      if (response.data['success'] == true) {
        return UserModel.fromJson(response.data['data']['user']);
      }
      throw ServerException(
        message: response.data['message'] ?? 'Failed to update profile',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Convert DioException to app-specific exceptions.
  Exception _handleDioError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return const NetworkException(message: 'Connection timeout. Please try again.');
    }

    if (e.type == DioExceptionType.connectionError) {
      return const NetworkException(message: 'Cannot connect to server. Is the backend running?');
    }

    final statusCode = e.response?.statusCode;
    final message = e.response?.data?['message'] ?? 'An error occurred';

    if (statusCode == 401) {
      return AuthException(message: message, statusCode: statusCode);
    }

    if (statusCode == 409) {
      return AuthException(message: message, statusCode: statusCode);
    }

    return ServerException(message: message, statusCode: statusCode);
  }
}
