import 'package:dio/dio.dart';

import '../../../../core/constants/constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/transaction_model.dart';

/// Remote data source for transaction and category API calls.
class TransactionRemoteDataSource {
  final Dio dio;

  TransactionRemoteDataSource({required this.dio});

  /// Get transactions list with filters.
  Future<Map<String, dynamic>> getTransactions({
    String? type,
    String? categoryId,
    String? startDate,
    String? endDate,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
        'sort': 'date',
        'order': 'desc',
      };
      if (type != null) queryParams['type'] = type;
      if (categoryId != null) queryParams['category_id'] = categoryId;
      if (startDate != null) queryParams['start_date'] = startDate;
      if (endDate != null) queryParams['end_date'] = endDate;

      final response = await dio.get(
        ApiConstants.transactions,
        queryParameters: queryParams,
      );

      if (response.data['success'] == true) {
        final data = response.data['data'];
        final transactions = (data['transactions'] as List)
            .map((json) => TransactionModel.fromJson(json))
            .toList();
        return {
          'transactions': transactions,
          'pagination': data['pagination'],
        };
      }
      throw ServerException(message: response.data['message'] ?? 'Failed to load transactions');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Get a single transaction.
  Future<TransactionModel> getTransaction(String id) async {
    try {
      final response = await dio.get('${ApiConstants.transactions}/$id');
      if (response.data['success'] == true) {
        return TransactionModel.fromJson(response.data['data']['transaction']);
      }
      throw ServerException(message: response.data['message'] ?? 'Transaction not found');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Create transaction.
  Future<TransactionModel> createTransaction({
    required String type,
    required double amount,
    required String description,
    required String date,
    String? categoryId,
  }) async {
    try {
      final data = <String, dynamic>{
        'type': type,
        'amount': amount,
        'description': description,
        'date': date,
      };
      if (categoryId != null) data['category_id'] = categoryId;

      final response = await dio.post(ApiConstants.transactions, data: data);
      if (response.data['success'] == true) {
        return TransactionModel.fromJson(response.data['data']['transaction']);
      }
      throw ServerException(message: response.data['message'] ?? 'Failed to create transaction');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Update transaction.
  Future<TransactionModel> updateTransaction({
    required String id,
    String? type,
    double? amount,
    String? description,
    String? date,
    String? categoryId,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (type != null) data['type'] = type;
      if (amount != null) data['amount'] = amount;
      if (description != null) data['description'] = description;
      if (date != null) data['date'] = date;
      if (categoryId != null) data['category_id'] = categoryId;

      final response = await dio.put('${ApiConstants.transactions}/$id', data: data);
      if (response.data['success'] == true) {
        return TransactionModel.fromJson(response.data['data']['transaction']);
      }
      throw ServerException(message: response.data['message'] ?? 'Failed to update transaction');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Delete transaction.
  Future<void> deleteTransaction(String id) async {
    try {
      final response = await dio.delete('${ApiConstants.transactions}/$id');
      if (response.data['success'] != true) {
        throw ServerException(message: response.data['message'] ?? 'Failed to delete transaction');
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Get financial summary.
  Future<FinancialSummaryModel> getSummary({String? month, String? year}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (month != null) queryParams['month'] = month;
      if (year != null) queryParams['year'] = year;

      final response = await dio.get(
        ApiConstants.transactionSummary,
        queryParameters: queryParams,
      );
      if (response.data['success'] == true) {
        return FinancialSummaryModel.fromJson(response.data['data']);
      }
      throw ServerException(message: response.data['message'] ?? 'Failed to load summary');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Get categories.
  Future<List<CategoryModel>> getCategories({String? type}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (type != null) queryParams['type'] = type;

      final response = await dio.get(
        ApiConstants.categories,
        queryParameters: queryParams,
      );
      if (response.data['success'] == true) {
        return (response.data['data']['categories'] as List)
            .map((json) => CategoryModel.fromJson(json))
            .toList();
      }
      throw ServerException(message: response.data['message'] ?? 'Failed to load categories');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Create category.
  Future<CategoryModel> createCategory({
    required String name,
    required String type,
    String? icon,
    String? color,
  }) async {
    try {
      final data = <String, dynamic>{'name': name, 'type': type};
      if (icon != null) data['icon'] = icon;
      if (color != null) data['color'] = color;

      final response = await dio.post(ApiConstants.categories, data: data);
      if (response.data['success'] == true) {
        return CategoryModel.fromJson(response.data['data']['category']);
      }
      throw ServerException(message: response.data['message'] ?? 'Failed to create category');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Delete category.
  Future<void> deleteCategory(String id) async {
    try {
      final response = await dio.delete('${ApiConstants.categories}/$id');
      if (response.data['success'] != true) {
        throw ServerException(message: response.data['message'] ?? 'Failed to delete category');
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Exception _handleDioError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return const NetworkException(message: 'Connection timeout.');
    }
    if (e.type == DioExceptionType.connectionError) {
      return const NetworkException(message: 'Cannot connect to server.');
    }
    final message = e.response?.data?['message'] ?? 'An error occurred';
    return ServerException(message: message, statusCode: e.response?.statusCode);
  }
}
