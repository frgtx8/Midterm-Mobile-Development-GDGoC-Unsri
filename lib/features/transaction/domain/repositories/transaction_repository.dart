import '../entities/transaction.dart';

/// Abstract repository contract for transaction operations.
abstract class TransactionRepository {
  /// Get list of transactions with optional filters and pagination.
  Future<Map<String, dynamic>> getTransactions({
    String? type,
    String? categoryId,
    String? startDate,
    String? endDate,
    int page = 1,
    int limit = 20,
  });

  /// Get a single transaction by ID.
  Future<Transaction> getTransaction(String id);

  /// Create a new transaction.
  Future<Transaction> createTransaction({
    required String type,
    required double amount,
    required String description,
    required String date,
    String? categoryId,
  });

  /// Update an existing transaction.
  Future<Transaction> updateTransaction({
    required String id,
    String? type,
    double? amount,
    String? description,
    String? date,
    String? categoryId,
  });

  /// Delete a transaction.
  Future<void> deleteTransaction(String id);

  /// Get financial summary.
  Future<FinancialSummary> getSummary({String? month, String? year});

  /// Get all categories.
  Future<List<Category>> getCategories({String? type});

  /// Create a custom category.
  Future<Category> createCategory({
    required String name,
    required String type,
    String? icon,
    String? color,
  });

  /// Delete a category.
  Future<void> deleteCategory(String id);
}
