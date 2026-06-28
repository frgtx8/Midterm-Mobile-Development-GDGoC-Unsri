import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../datasources/transaction_remote_datasource.dart';
import '../datasources/transaction_local_datasource.dart';

/// Implementation of [TransactionRepository] that supports both remote and local SQLite storage.
class TransactionRepositoryImpl implements TransactionRepository {
  final TransactionRemoteDataSource remoteDataSource;
  final TransactionLocalDataSource localDataSource;
  final SharedPreferences sharedPreferences;
  final FlutterSecureStorage secureStorage;

  TransactionRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.sharedPreferences,
    required this.secureStorage,
  });

  bool get _isOffline => sharedPreferences.getBool(StorageKeys.isOfflineMode) ?? false;

  @override
  Future<Map<String, dynamic>> getTransactions({
    String? type,
    String? categoryId,
    String? startDate,
    String? endDate,
    int page = 1,
    int limit = 20,
  }) async {
    if (_isOffline) {
      try {
        final txs = await localDataSource.getTransactions(
          type: type,
          categoryId: categoryId,
          startDate: startDate,
          endDate: endDate,
        );
        return {
          'transactions': txs,
          'pagination': {
            'page': 1,
            'limit': limit,
            'total': txs.length,
            'totalPages': 1,
          }
        };
      } catch (e) {
        throw CacheFailure(message: e.toString());
      }
    }

    try {
      return await remoteDataSource.getTransactions(
        type: type,
        categoryId: categoryId,
        startDate: startDate,
        endDate: endDate,
        page: page,
        limit: limit,
      );
    } on NetworkException catch (e) {
      throw NetworkFailure(message: e.message);
    } on ServerException catch (e) {
      throw ServerFailure(message: e.message, statusCode: e.statusCode);
    } catch (e) {
      throw UnexpectedFailure(message: e.toString());
    }
  }

  @override
  Future<Transaction> getTransaction(String id) async {
    if (_isOffline) {
      throw const CacheFailure(message: 'Detail transaksi offline tidak didukung.');
    }

    try {
      return await remoteDataSource.getTransaction(id);
    } on NetworkException catch (e) {
      throw NetworkFailure(message: e.message);
    } on ServerException catch (e) {
      throw ServerFailure(message: e.message, statusCode: e.statusCode);
    } catch (e) {
      throw UnexpectedFailure(message: e.toString());
    }
  }

  @override
  Future<Transaction> createTransaction({
    required String type,
    required double amount,
    required String description,
    required String date,
    String? categoryId,
  }) async {
    if (_isOffline) {
      try {
        final userId = await secureStorage.read(key: StorageKeys.userId) ?? 'local_user';
        return await localDataSource.createTransaction(
          userId: userId,
          type: type,
          amount: amount,
          description: description,
          date: date,
          categoryId: categoryId,
        );
      } catch (e) {
        throw CacheFailure(message: e.toString());
      }
    }

    try {
      return await remoteDataSource.createTransaction(
        type: type,
        amount: amount,
        description: description,
        date: date,
        categoryId: categoryId,
      );
    } on NetworkException catch (e) {
      throw NetworkFailure(message: e.message);
    } on ServerException catch (e) {
      throw ServerFailure(message: e.message, statusCode: e.statusCode);
    } catch (e) {
      throw UnexpectedFailure(message: e.toString());
    }
  }

  @override
  Future<Transaction> updateTransaction({
    required String id,
    String? type,
    double? amount,
    String? description,
    String? date,
    String? categoryId,
  }) async {
    if (_isOffline) {
      try {
        return await localDataSource.updateTransaction(
          id: id,
          type: type,
          amount: amount,
          description: description,
          date: date,
          categoryId: categoryId,
        );
      } catch (e) {
        throw CacheFailure(message: e.toString());
      }
    }

    try {
      return await remoteDataSource.updateTransaction(
        id: id,
        type: type,
        amount: amount,
        description: description,
        date: date,
        categoryId: categoryId,
      );
    } on NetworkException catch (e) {
      throw NetworkFailure(message: e.message);
    } on ServerException catch (e) {
      throw ServerFailure(message: e.message, statusCode: e.statusCode);
    } catch (e) {
      throw UnexpectedFailure(message: e.toString());
    }
  }

  @override
  Future<void> deleteTransaction(String id) async {
    if (_isOffline) {
      try {
        await localDataSource.deleteTransaction(id);
        return;
      } catch (e) {
        throw CacheFailure(message: e.toString());
      }
    }

    try {
      await remoteDataSource.deleteTransaction(id);
    } on NetworkException catch (e) {
      throw NetworkFailure(message: e.message);
    } on ServerException catch (e) {
      throw ServerFailure(message: e.message, statusCode: e.statusCode);
    } catch (e) {
      throw UnexpectedFailure(message: e.toString());
    }
  }

  @override
  Future<FinancialSummary> getSummary({String? month, String? year}) async {
    if (_isOffline) {
      try {
        return await localDataSource.getSummary();
      } catch (e) {
        throw CacheFailure(message: e.toString());
      }
    }

    try {
      return await remoteDataSource.getSummary(month: month, year: year);
    } on NetworkException catch (e) {
      throw NetworkFailure(message: e.message);
    } on ServerException catch (e) {
      throw ServerFailure(message: e.message, statusCode: e.statusCode);
    } catch (e) {
      throw UnexpectedFailure(message: e.toString());
    }
  }

  @override
  Future<List<Category>> getCategories({String? type}) async {
    if (_isOffline) {
      try {
        return await localDataSource.getCategories(type: type);
      } catch (e) {
        throw CacheFailure(message: e.toString());
      }
    }

    try {
      return await remoteDataSource.getCategories(type: type);
    } on NetworkException catch (e) {
      throw NetworkFailure(message: e.message);
    } on ServerException catch (e) {
      throw ServerFailure(message: e.message, statusCode: e.statusCode);
    } catch (e) {
      throw UnexpectedFailure(message: e.toString());
    }
  }

  @override
  Future<Category> createCategory({
    required String name,
    required String type,
    String? icon,
    String? color,
  }) async {
    if (_isOffline) {
      try {
        return await localDataSource.createCategory(
          name: name,
          type: type,
          icon: icon,
          color: color,
        );
      } catch (e) {
        throw CacheFailure(message: e.toString());
      }
    }

    try {
      return await remoteDataSource.createCategory(
        name: name,
        type: type,
        icon: icon,
        color: color,
      );
    } on NetworkException catch (e) {
      throw NetworkFailure(message: e.message);
    } on ServerException catch (e) {
      throw ServerFailure(message: e.message, statusCode: e.statusCode);
    } catch (e) {
      throw UnexpectedFailure(message: e.toString());
    }
  }

  @override
  Future<void> deleteCategory(String id) async {
    if (_isOffline) {
      try {
        await localDataSource.deleteCategory(id);
        return;
      } catch (e) {
        throw CacheFailure(message: e.toString());
      }
    }

    try {
      await remoteDataSource.deleteCategory(id);
    } on NetworkException catch (e) {
      throw NetworkFailure(message: e.message);
    } on ServerException catch (e) {
      throw ServerFailure(message: e.message, statusCode: e.statusCode);
    } catch (e) {
      throw UnexpectedFailure(message: e.toString());
    }
  }
}
