import 'package:equatable/equatable.dart';

/// Transaction entity.
class Transaction extends Equatable {
  final String id;
  final String userId;
  final String? categoryId;
  final String type; // 'income' or 'expense'
  final double amount;
  final String description;
  final DateTime date;
  final String? categoryName;
  final String? categoryIcon;
  final String? categoryColor;
  final String? createdAt;

  const Transaction({
    required this.id,
    required this.userId,
    this.categoryId,
    required this.type,
    required this.amount,
    required this.description,
    required this.date,
    this.categoryName,
    this.categoryIcon,
    this.categoryColor,
    this.createdAt,
  });

  bool get isIncome => type == 'income';
  bool get isExpense => type == 'expense';

  @override
  List<Object?> get props => [id, userId, type, amount, date, categoryId];
}

/// Category entity.
class Category extends Equatable {
  final String id;
  final String name;
  final String icon;
  final String color;
  final String type; // 'income' or 'expense'
  final bool isDefault;

  const Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.type,
    this.isDefault = false,
  });

  @override
  List<Object?> get props => [id, name, type];
}

/// Financial summary entity.
class FinancialSummary extends Equatable {
  final double totalIncome;
  final double totalExpense;
  final double balance;
  final List<CategoryBreakdown> expenseByCategory;
  final List<CategoryBreakdown> incomeByCategory;
  final List<MonthlyTrend> monthlyTrend;

  const FinancialSummary({
    required this.totalIncome,
    required this.totalExpense,
    required this.balance,
    this.expenseByCategory = const [],
    this.incomeByCategory = const [],
    this.monthlyTrend = const [],
  });

  @override
  List<Object?> get props => [totalIncome, totalExpense, balance];
}

/// Category breakdown for charts.
class CategoryBreakdown extends Equatable {
  final String categoryName;
  final String categoryIcon;
  final String categoryColor;
  final double total;

  const CategoryBreakdown({
    required this.categoryName,
    required this.categoryIcon,
    required this.categoryColor,
    required this.total,
  });

  @override
  List<Object?> get props => [categoryName, total];
}

/// Monthly trend data.
class MonthlyTrend extends Equatable {
  final String month;
  final double income;
  final double expense;

  const MonthlyTrend({
    required this.month,
    required this.income,
    required this.expense,
  });

  @override
  List<Object?> get props => [month, income, expense];
}
