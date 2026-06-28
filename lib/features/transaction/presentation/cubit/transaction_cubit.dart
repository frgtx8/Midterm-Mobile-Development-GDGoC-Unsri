import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/repositories/transaction_repository.dart';
import 'transaction_state.dart';

/// Cubit managing the transaction list, summary, and categories.
class TransactionCubit extends Cubit<TransactionState> {
  final TransactionRepository repository;

  TransactionCubit({required this.repository}) : super(TransactionInitial());

  /// Load all data: transactions, summary, and categories.
  Future<void> loadAll() async {
    emit(TransactionLoading());
    try {
      final results = await Future.wait([
        repository.getTransactions(page: 1, limit: 50),
        repository.getSummary(),
        repository.getCategories(),
      ]);

      final txData = results[0] as Map<String, dynamic>;
      final summary = results[1] as FinancialSummary;
      final categories = results[2] as List<Category>;

      emit(TransactionLoaded(
        transactions: txData['transactions'] as List<Transaction>,
        summary: summary,
        categories: categories,
        currentPage: txData['pagination']?['page'] ?? 1,
        totalPages: txData['pagination']?['totalPages'] ?? 1,
      ));
    } on Failure catch (e) {
      emit(TransactionError(message: e.message));
    } catch (e) {
      emit(TransactionError(message: e.toString()));
    }
  }

  /// Refresh just the summary.
  Future<void> refreshSummary() async {
    if (state is! TransactionLoaded) return;
    try {
      final summary = await repository.getSummary();
      emit((state as TransactionLoaded).copyWith(summary: summary));
    } catch (_) {}
  }

  /// Delete a transaction and refresh data.
  Future<void> deleteTransaction(String id) async {
    try {
      await repository.deleteTransaction(id);
      await loadAll();
    } on Failure catch (e) {
      emit(TransactionError(message: e.message));
    }
  }
}

/// Cubit for add/edit transaction form.
class TransactionFormCubit extends Cubit<TransactionFormState> {
  final TransactionRepository repository;

  TransactionFormCubit({required this.repository}) : super(TransactionFormInitial());

  /// Create a new transaction.
  Future<void> createTransaction({
    required String type,
    required double amount,
    required String description,
    required String date,
    String? categoryId,
  }) async {
    emit(TransactionFormLoading());
    try {
      await repository.createTransaction(
        type: type,
        amount: amount,
        description: description,
        date: date,
        categoryId: categoryId,
      );
      emit(const TransactionFormSuccess(message: 'Transaksi berhasil ditambahkan!'));
    } on Failure catch (e) {
      emit(TransactionFormError(message: e.message));
    } catch (e) {
      emit(TransactionFormError(message: e.toString()));
    }
  }

  /// Update an existing transaction.
  Future<void> updateTransaction({
    required String id,
    String? type,
    double? amount,
    String? description,
    String? date,
    String? categoryId,
  }) async {
    emit(TransactionFormLoading());
    try {
      await repository.updateTransaction(
        id: id,
        type: type,
        amount: amount,
        description: description,
        date: date,
        categoryId: categoryId,
      );
      emit(const TransactionFormSuccess(message: 'Transaksi berhasil diperbarui!'));
    } on Failure catch (e) {
      emit(TransactionFormError(message: e.message));
    } catch (e) {
      emit(TransactionFormError(message: e.toString()));
    }
  }
}
