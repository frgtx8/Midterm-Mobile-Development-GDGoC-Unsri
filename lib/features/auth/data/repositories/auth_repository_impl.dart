import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../datasources/auth_local_datasource.dart';
import '../models/user_model.dart';

/// Implementation of [AuthRepository] that coordinates remote data source,
/// local SQLite data source, and local secure storage.
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;
  final FlutterSecureStorage secureStorage;
  final SharedPreferences sharedPreferences;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.secureStorage,
    required this.sharedPreferences,
  });

  bool get _isOffline => sharedPreferences.getBool(StorageKeys.isOfflineMode) ?? false;

  @override
  Future<User> register({
    required String name,
    required String email,
    required String password,
  }) async {
    if (_isOffline) {
      try {
        final userModel = await localDataSource.register(
          name: name,
          email: email,
          password: password,
        );
        await _saveLocalAuthData(userModel);
        return userModel;
      } catch (e) {
        throw AuthFailure(message: e.toString().replaceAll('Exception: ', ''));
      }
    }

    try {
      final data = await remoteDataSource.register(
        name: name,
        email: email,
        password: password,
      );

      await _saveAuthData(data);
      return UserModel.fromJson(data['user']);
    } on AuthException catch (e) {
      throw AuthFailure(message: e.message, statusCode: e.statusCode);
    } on NetworkException catch (e) {
      throw NetworkFailure(message: e.message);
    } on ServerException catch (e) {
      throw ServerFailure(message: e.message, statusCode: e.statusCode);
    } catch (e) {
      throw UnexpectedFailure(message: e.toString());
    }
  }

  @override
  Future<User> login({
    required String email,
    required String password,
  }) async {
    if (_isOffline) {
      try {
        final userModel = await localDataSource.login(
          email: email,
          password: password,
        );
        await _saveLocalAuthData(userModel);
        return userModel;
      } catch (e) {
        throw AuthFailure(message: e.toString().replaceAll('Exception: ', ''));
      }
    }

    try {
      final data = await remoteDataSource.login(email: email, password: password);

      await _saveAuthData(data);
      return UserModel.fromJson(data['user']);
    } on AuthException catch (e) {
      throw AuthFailure(message: e.message, statusCode: e.statusCode);
    } on NetworkException catch (e) {
      throw NetworkFailure(message: e.message);
    } on ServerException catch (e) {
      throw ServerFailure(message: e.message, statusCode: e.statusCode);
    } catch (e) {
      throw UnexpectedFailure(message: e.toString());
    }
  }

  @override
  Future<void> logout() async {
    if (_isOffline) {
      await secureStorage.deleteAll();
      return;
    }

    try {
      final refreshToken = await secureStorage.read(key: StorageKeys.refreshToken);
      await remoteDataSource.logout(refreshToken);
    } catch (_) {
      // Ignore errors during logout API call
    } finally {
      await secureStorage.deleteAll();
    }
  }

  @override
  Future<User> getProfile() async {
    if (_isOffline) {
      final cached = await getCachedUser();
      if (cached != null) return cached;
      throw const AuthFailure(message: 'Profil tidak ditemukan secara lokal.');
    }

    try {
      return await remoteDataSource.getProfile();
    } on AuthException catch (e) {
      throw AuthFailure(message: e.message, statusCode: e.statusCode);
    } on NetworkException catch (e) {
      throw NetworkFailure(message: e.message);
    } on ServerException catch (e) {
      throw ServerFailure(message: e.message, statusCode: e.statusCode);
    } catch (e) {
      throw UnexpectedFailure(message: e.toString());
    }
  }

  @override
  Future<User> updateProfile({required String name}) async {
    if (_isOffline) {
      await secureStorage.write(key: StorageKeys.userName, value: name);
      final cached = await getCachedUser();
      return cached!;
    }

    try {
      final user = await remoteDataSource.updateProfile(name: name);
      await secureStorage.write(key: StorageKeys.userName, value: user.name);
      return user;
    } on AuthException catch (e) {
      throw AuthFailure(message: e.message, statusCode: e.statusCode);
    } on NetworkException catch (e) {
      throw NetworkFailure(message: e.message);
    } on ServerException catch (e) {
      throw ServerFailure(message: e.message, statusCode: e.statusCode);
    } catch (e) {
      throw UnexpectedFailure(message: e.toString());
    }
  }

  @override
  Future<bool> isAuthenticated() async {
    final token = await secureStorage.read(key: StorageKeys.accessToken);
    final isOfflineUser = await secureStorage.read(key: StorageKeys.userId) != null;
    return token != null || (_isOffline && isOfflineUser);
  }

  @override
  Future<User?> getCachedUser() async {
    final id = await secureStorage.read(key: StorageKeys.userId);
    final name = await secureStorage.read(key: StorageKeys.userName);
    final email = await secureStorage.read(key: StorageKeys.userEmail);

    if (id != null && name != null && email != null) {
      return User(id: id, name: name, email: email);
    }
    return null;
  }

  /// Save auth tokens and user data to secure storage.
  Future<void> _saveAuthData(Map<String, dynamic> data) async {
    await secureStorage.write(
      key: StorageKeys.accessToken,
      value: data['accessToken'],
    );
    await secureStorage.write(
      key: StorageKeys.refreshToken,
      value: data['refreshToken'],
    );

    final user = data['user'] as Map<String, dynamic>;
    await secureStorage.write(key: StorageKeys.userId, value: user['id']);
    await secureStorage.write(key: StorageKeys.userName, value: user['name']);
    await secureStorage.write(key: StorageKeys.userEmail, value: user['email']);
  }

  /// Save local auth data.
  Future<void> _saveLocalAuthData(UserModel user) async {
    // Generate dummy tokens to satisfy isAuthenticated check
    await secureStorage.write(key: StorageKeys.accessToken, value: 'local_token');
    await secureStorage.write(key: StorageKeys.userId, value: user.id);
    await secureStorage.write(key: StorageKeys.userName, value: user.name);
    await secureStorage.write(key: StorageKeys.userEmail, value: user.email);
  }
}
