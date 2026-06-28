import 'package:equatable/equatable.dart';

import '../../domain/entities/transaction.dart';

/// Transaction list/summary states.
abstract class TransactionState extends Equatable {
  const TransactionState();

  @override
  List<Object?> get props => [];
}

class TransactionInitial extends TransactionState {}

class TransactionLoading extends TransactionState {}

class TransactionLoaded extends TransactionState {
  final List<Transaction> transactions;
  final FinancialSummary summary;
  final List<Category> categories;
  final int currentPage;
  final int totalPages;
  final bool isLoadingMore;

  const TransactionLoaded({
    required this.transactions,
    required this.summary,
    required this.categories,
    this.currentPage = 1,
    this.totalPages = 1,
    this.isLoadingMore = false,
  });

  TransactionLoaded copyWith({
    List<Transaction>? transactions,
    FinancialSummary? summary,
    List<Category>? categories,
    int? currentPage,
    int? totalPages,
    bool? isLoadingMore,
  }) {
    return TransactionLoaded(
      transactions: transactions ?? this.transactions,
      summary: summary ?? this.summary,
      categories: categories ?? this.categories,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }

  @override
  List<Object?> get props => [transactions, summary, categories, currentPage, totalPages, isLoadingMore];
}

class TransactionError extends TransactionState {
  final String message;

  const TransactionError({required this.message});

  @override
  List<Object?> get props => [message];
}

/// State for add/edit form operations.
abstract class TransactionFormState extends Equatable {
  const TransactionFormState();

  @override
  List<Object?> get props => [];
}

class TransactionFormInitial extends TransactionFormState {}

class TransactionFormLoading extends TransactionFormState {}

class TransactionFormSuccess extends TransactionFormState {
  final String message;

  const TransactionFormSuccess({required this.message});

  @override
  List<Object?> get props => [message];
}

class TransactionFormError extends TransactionFormState {
  final String message;

  const TransactionFormError({required this.message});

  @override
  List<Object?> get props => [message];
}
