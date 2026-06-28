import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/network/dio_client.dart';
import 'core/network/local_database_helper.dart';
import 'features/auth/data/datasources/auth_remote_datasource.dart';
import 'features/auth/data/datasources/auth_local_datasource.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/presentation/cubit/auth_cubit.dart';
import 'features/settings/presentation/cubit/theme_cubit.dart';
import 'features/transaction/data/datasources/transaction_remote_datasource.dart';
import 'features/transaction/data/datasources/transaction_local_datasource.dart';
import 'features/transaction/data/repositories/transaction_repository_impl.dart';
import 'features/transaction/domain/repositories/transaction_repository.dart';
import 'features/transaction/presentation/cubit/transaction_cubit.dart';

final sl = GetIt.instance;

/// Initialize all dependencies using GetIt service locator.
Future<void> initDependencies() async {
  // ─── External ──────────────────────────────────────────
  final prefs = await SharedPreferences.getInstance();
  sl.registerSingleton<SharedPreferences>(prefs);

  const secureStorage = FlutterSecureStorage();
  sl.registerSingleton<FlutterSecureStorage>(secureStorage);

  // ─── Local Database ─────────────────────────────────────
  sl.registerSingleton<LocalDatabaseHelper>(LocalDatabaseHelper.instance);

  // ─── Network ──────────────────────────────────────────
  sl.registerSingleton<DioClient>(
    DioClient(secureStorage: sl<FlutterSecureStorage>()),
  );
  sl.registerSingleton<Dio>(sl<DioClient>().dio);

  // ─── Data Sources ─────────────────────────────────────
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSource(dio: sl<Dio>()),
  );
  sl.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSource(dbHelper: sl<LocalDatabaseHelper>()),
  );

  sl.registerLazySingleton<TransactionRemoteDataSource>(
    () => TransactionRemoteDataSource(dio: sl<Dio>()),
  );
  sl.registerLazySingleton<TransactionLocalDataSource>(
    () => TransactionLocalDataSource(dbHelper: sl<LocalDatabaseHelper>()),
  );

  // ─── Repositories ─────────────────────────────────────
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDataSource: sl<AuthRemoteDataSource>(),
      localDataSource: sl<AuthLocalDataSource>(),
      secureStorage: sl<FlutterSecureStorage>(),
      sharedPreferences: sl<SharedPreferences>(),
    ),
  );
  sl.registerLazySingleton<TransactionRepository>(
    () => TransactionRepositoryImpl(
      remoteDataSource: sl<TransactionRemoteDataSource>(),
      localDataSource: sl<TransactionLocalDataSource>(),
      sharedPreferences: sl<SharedPreferences>(),
      secureStorage: sl<FlutterSecureStorage>(),
    ),
  );

  // ─── Cubits ───────────────────────────────────────────
  sl.registerFactory<AuthCubit>(
    () => AuthCubit(authRepository: sl<AuthRepository>()),
  );
  sl.registerFactory<TransactionCubit>(
    () => TransactionCubit(repository: sl<TransactionRepository>()),
  );
  sl.registerFactory<TransactionFormCubit>(
    () => TransactionFormCubit(repository: sl<TransactionRepository>()),
  );
  sl.registerSingleton<ThemeCubit>(
    ThemeCubit(prefs: sl<SharedPreferences>()),
  );
}
