import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_tracker/data/models/expense_model.dart';
import 'package:expense_tracker/domain/repositories/expense_repository.dart';
import 'providers.dart';

/// State notifier for managing expense list
class ExpenseNotifier extends StateNotifier<AsyncValue<List<ExpenseModel>>> {
  final ExpenseRepository _repository;

  ExpenseNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadExpenses();
  }

  /// Load all expenses
  Future<void> loadExpenses({
    DateTime? startDate,
    DateTime? endDate,
    String? category,
  }) async {
    state = const AsyncValue.loading();
    
    try {
      final expenses = await _repository.getAllExpenses(
        startDate: startDate,
        endDate: endDate,
        category: category,
      );
      state = AsyncValue.data(expenses);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Add new expense
  Future<void> addExpense(ExpenseModel expense) async {
    try {
      await _repository.addExpense(expense);
      await loadExpenses(); // Reload list
    } catch (error) {
      rethrow; // Let UI handle error
    }
  }

  /// Update existing expense
  Future<void> updateExpense(ExpenseModel expense) async {
    try {
      await _repository.updateExpense(expense);
      await loadExpenses();
    } catch (error) {
      rethrow;
    }
  }

  /// Delete expense
  Future<void> deleteExpense(String id) async {
    try {
      await _repository.deleteExpense(id);
      await loadExpenses();
    } catch (error) {
      rethrow;
    }
  }

  /// Search expenses
  Future<void> searchExpenses(String query) async {
    state = const AsyncValue.loading();
    
    try {
      final expenses = await _repository.searchExpenses(query);
      state = AsyncValue.data(expenses);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

/// Provider for expense list
final expenseProvider = StateNotifierProvider<ExpenseNotifier, AsyncValue<List<ExpenseModel>>>((ref) {
  final repository = ref.watch(expenseRepositoryProvider);
  return ExpenseNotifier(repository);
});

/// Provider for total expenses (computed)
final totalExpensesProvider = FutureProvider.family<double, DateRange?>((ref, dateRange) async {
  final repository = ref.watch(expenseRepositoryProvider);
  return await repository.getTotalExpenses(
    startDate: dateRange?.start,
    endDate: dateRange?.end,
  );
});

/// Provider for expenses by category
final expensesByCategoryProvider = FutureProvider.family<Map<String, double>, DateRange?>((ref, dateRange) async {
  final repository = ref.watch(expenseRepositoryProvider);
  return await repository.getExpensesByCategory(
    startDate: dateRange?.start,
    endDate: dateRange?.end,
  );
});

/// Helper class for date range parameters
class DateRange {
  final DateTime start;
  final DateTime end;

  DateRange(this.start, this.end);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DateRange &&
          runtimeType == other.runtimeType &&
          start == other.start &&
          end == other.end;

  @override
  int get hashCode => start.hashCode ^ end.hashCode;
}