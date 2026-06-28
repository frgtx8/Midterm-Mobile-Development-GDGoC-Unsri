import 'dart:math';
import '../../../../core/network/local_database_helper.dart';
import '../models/transaction_model.dart';

class TransactionLocalDataSource {
  final LocalDatabaseHelper dbHelper;

  TransactionLocalDataSource({required this.dbHelper});

  String _generateId() {
    final rand = Random();
    final time = DateTime.now().microsecondsSinceEpoch;
    return '$time-${rand.nextInt(100000)}';
  }

  /// Get local transactions.
  Future<List<TransactionModel>> getTransactions({
    String? type,
    String? categoryId,
    String? startDate,
    String? endDate,
  }) async {
    final db = await dbHelper.database;

    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (type != null) {
      whereClause += 'type = ?';
      whereArgs.add(type);
    }

    if (categoryId != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'category_id = ?';
      whereArgs.add(categoryId);
    }

    if (startDate != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'date >= ?';
      whereArgs.add(startDate);
    }

    if (endDate != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'date <= ?';
      whereArgs.add(endDate);
    }

    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: whereClause.isEmpty ? null : whereClause,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'date DESC',
    );

    return maps.map((map) {
      // Map database row to JSON suitable for model
      final mapCopy = Map<String, dynamic>.from(map);
      mapCopy['user_id'] = map['user_id'] ?? '';
      return TransactionModel.fromJson(mapCopy);
    }).toList();
  }

  /// Create local transaction.
  Future<TransactionModel> createTransaction({
    required String userId,
    required String type,
    required double amount,
    required String description,
    required String date,
    String? categoryId,
  }) async {
    final db = await dbHelper.database;
    final id = _generateId();

    String? catName;
    String? catIcon;
    String? catColor;

    if (categoryId != null) {
      final List<Map<String, dynamic>> catMaps = await db.query(
        'categories',
        where: 'id = ?',
        whereArgs: [categoryId],
      );
      if (catMaps.isNotEmpty) {
        catName = catMaps.first['name'] as String;
        catIcon = catMaps.first['icon'] as String;
        catColor = catMaps.first['color'] as String;
      }
    }

    final txMap = {
      'id': id,
      'user_id': userId,
      'category_id': categoryId,
      'type': type,
      'amount': amount,
      'description': description,
      'date': date,
      'category_name': catName,
      'category_icon': catIcon,
      'category_color': catColor,
      'created_at': DateTime.now().toIso8601String(),
    };

    await db.insert('transactions', txMap);
    return TransactionModel.fromJson(txMap);
  }

  /// Update local transaction.
  Future<TransactionModel> updateTransaction({
    required String id,
    String? type,
    double? amount,
    String? description,
    String? date,
    String? categoryId,
  }) async {
    final db = await dbHelper.database;

    final List<Map<String, dynamic>> existing = await db.query(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (existing.isEmpty) {
      throw Exception('Transaksi tidak ditemukan.');
    }

    final updatedMap = Map<String, dynamic>.from(existing.first);
    if (type != null) updatedMap['type'] = type;
    if (amount != null) updatedMap['amount'] = amount;
    if (description != null) updatedMap['description'] = description;
    if (date != null) updatedMap['date'] = date;

    if (categoryId != null) {
      updatedMap['category_id'] = categoryId;
      final List<Map<String, dynamic>> catMaps = await db.query(
        'categories',
        where: 'id = ?',
        whereArgs: [categoryId],
      );
      if (catMaps.isNotEmpty) {
        updatedMap['category_name'] = catMaps.first['name'] as String;
        updatedMap['category_icon'] = catMaps.first['icon'] as String;
        updatedMap['category_color'] = catMaps.first['color'] as String;
      }
    }

    await db.update(
      'transactions',
      updatedMap,
      where: 'id = ?',
      whereArgs: [id],
    );

    return TransactionModel.fromJson(updatedMap);
  }

  /// Delete local transaction.
  Future<void> deleteTransaction(String id) async {
    final db = await dbHelper.database;
    await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Get local categories.
  Future<List<CategoryModel>> getCategories({String? type}) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'categories',
      where: type == null ? null : 'type = ?',
      whereArgs: type == null ? null : [type],
      orderBy: 'is_default DESC, name ASC',
    );

    return maps.map((m) => CategoryModel.fromJson(m)).toList();
  }

  /// Create local category.
  Future<CategoryModel> createCategory({
    required String name,
    required String type,
    String? icon,
    String? color,
  }) async {
    final db = await dbHelper.database;
    final id = _generateId();

    final catMap = {
      'id': id,
      'name': name,
      'type': type,
      'icon': icon ?? 'category',
      'color': color ?? '#6C63FF',
      'is_default': 0,
    };

    await db.insert('categories', catMap);
    return CategoryModel.fromJson(catMap);
  }

  /// Delete local category.
  Future<void> deleteCategory(String id) async {
    final db = await dbHelper.database;
    await db.delete(
      'categories',
      where: 'id = ? AND is_default = 0',
      whereArgs: [id],
    );
  }

  /// Get local financial summary.
  Future<FinancialSummaryModel> getSummary() async {
    final db = await dbHelper.database;

    final List<Map<String, dynamic>> incomeMaps = await db.rawQuery(
      "SELECT SUM(amount) as total FROM transactions WHERE type = 'income'"
    );
    final List<Map<String, dynamic>> expenseMaps = await db.rawQuery(
      "SELECT SUM(amount) as total FROM transactions WHERE type = 'expense'"
    );

    final double totalIncome = (incomeMaps.first['total'] as num?)?.toDouble() ?? 0.0;
    final double totalExpense = (expenseMaps.first['total'] as num?)?.toDouble() ?? 0.0;

    // Breakdown for expenses
    final List<Map<String, dynamic>> expenseBreakdown = await db.rawQuery('''
      SELECT category_name, category_icon, category_color, SUM(amount) as total
      FROM transactions
      WHERE type = 'expense'
      GROUP BY category_id
      ORDER BY total DESC
    ''');

    final List<CategoryBreakdownModel> expenseByCategory = expenseBreakdown.map((row) {
      return CategoryBreakdownModel(
        categoryName: row['category_name'] as String? ?? 'Lainnya',
        categoryIcon: row['category_icon'] as String? ?? 'category',
        categoryColor: row['category_color'] as String? ?? '#6C63FF',
        total: (row['total'] as num).toDouble(),
      );
    }).toList();

    // Breakdown for income
    final List<Map<String, dynamic>> incomeBreakdown = await db.rawQuery('''
      SELECT category_name, category_icon, category_color, SUM(amount) as total
      FROM transactions
      WHERE type = 'income'
      GROUP BY category_id
      ORDER BY total DESC
    ''');

    final List<CategoryBreakdownModel> incomeByCategory = incomeBreakdown.map((row) {
      return CategoryBreakdownModel(
        categoryName: row['category_name'] as String? ?? 'Lainnya',
        categoryIcon: row['category_icon'] as String? ?? 'category',
        categoryColor: row['category_color'] as String? ?? '#6C63FF',
        total: (row['total'] as num).toDouble(),
      );
    }).toList();

    // Monthly trend (dummy for offline trend to keep chart clean)
    final List<MonthlyTrendModel> monthlyTrend = [
      MonthlyTrendModel(month: '2026-05', income: totalIncome * 0.8, expense: totalExpense * 0.8),
      MonthlyTrendModel(month: '2026-06', income: totalIncome, expense: totalExpense),
    ];

    final summaryMap = {
      'totalIncome': totalIncome,
      'totalExpense': totalExpense,
      'balance': totalIncome - totalExpense,
      'expenseByCategory': expenseByCategory.map((e) => {
        'category_name': e.categoryName,
        'category_icon': e.categoryIcon,
        'category_color': e.categoryColor,
        'total': e.total,
      }).toList(),
      'incomeByCategory': incomeByCategory.map((e) => {
        'category_name': e.categoryName,
        'category_icon': e.categoryIcon,
        'category_color': e.categoryColor,
        'total': e.total,
      }).toList(),
      'monthlyTrend': monthlyTrend.map((t) => {
        'month': t.month,
        'income': t.income,
        'expense': t.expense,
      }).toList(),
    };

    return FinancialSummaryModel.fromJson(summaryMap);
  }
}
