import '../../domain/entities/transaction.dart';

/// Transaction model with JSON serialization.
class TransactionModel extends Transaction {
  const TransactionModel({
    required super.id,
    required super.userId,
    super.categoryId,
    required super.type,
    required super.amount,
    required super.description,
    required super.date,
    super.categoryName,
    super.categoryIcon,
    super.categoryColor,
    super.createdAt,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      categoryId: json['category_id'] as String?,
      type: json['type'] as String,
      amount: (json['amount'] as num).toDouble(),
      description: json['description'] as String? ?? '',
      date: DateTime.parse(json['date'] as String),
      categoryName: json['category_name'] as String?,
      categoryIcon: json['category_icon'] as String?,
      categoryColor: json['category_color'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }
}

/// Category model with JSON serialization.
class CategoryModel extends Category {
  const CategoryModel({
    required super.id,
    required super.name,
    required super.icon,
    required super.color,
    required super.type,
    super.isDefault,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as String,
      name: json['name'] as String,
      icon: json['icon'] as String? ?? 'category',
      color: json['color'] as String? ?? '#6C63FF',
      type: json['type'] as String,
      isDefault: json['is_default'] == 1,
    );
  }
}

/// Summary models.
class FinancialSummaryModel extends FinancialSummary {
  const FinancialSummaryModel({
    required super.totalIncome,
    required super.totalExpense,
    required super.balance,
    super.expenseByCategory,
    super.incomeByCategory,
    super.monthlyTrend,
  });

  factory FinancialSummaryModel.fromJson(Map<String, dynamic> json) {
    return FinancialSummaryModel(
      totalIncome: (json['totalIncome'] as num).toDouble(),
      totalExpense: (json['totalExpense'] as num).toDouble(),
      balance: (json['balance'] as num).toDouble(),
      expenseByCategory: (json['expenseByCategory'] as List?)
              ?.map((e) => CategoryBreakdownModel.fromJson(e))
              .toList() ??
          [],
      incomeByCategory: (json['incomeByCategory'] as List?)
              ?.map((e) => CategoryBreakdownModel.fromJson(e))
              .toList() ??
          [],
      monthlyTrend: (json['monthlyTrend'] as List?)
              ?.map((e) => MonthlyTrendModel.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class CategoryBreakdownModel extends CategoryBreakdown {
  const CategoryBreakdownModel({
    required super.categoryName,
    required super.categoryIcon,
    required super.categoryColor,
    required super.total,
  });

  factory CategoryBreakdownModel.fromJson(Map<String, dynamic> json) {
    return CategoryBreakdownModel(
      categoryName: json['category_name'] as String? ?? 'Lainnya',
      categoryIcon: json['category_icon'] as String? ?? 'category',
      categoryColor: json['category_color'] as String? ?? '#6C63FF',
      total: (json['total'] as num).toDouble(),
    );
  }
}

class MonthlyTrendModel extends MonthlyTrend {
  const MonthlyTrendModel({
    required super.month,
    required super.income,
    required super.expense,
  });

  factory MonthlyTrendModel.fromJson(Map<String, dynamic> json) {
    return MonthlyTrendModel(
      month: json['month'] as String,
      income: (json['income'] as num).toDouble(),
      expense: (json['expense'] as num).toDouble(),
    );
  }
}
