import '../../data/models/expense_model.dart';

/// Abstract interface for expense data operations
/// 
/// This defines WHAT operations are available, not HOW they're implemented.
/// Implementation can be SQLite, cloud storage, or mock for testing.
abstract class ExpenseRepository {
  /// Get all expenses, optionally filtered and sorted
  Future<List<ExpenseModel>> getAllExpenses({
    DateTime? startDate,
    DateTime? endDate,
    String? category,
    int? limit,
    int? offset,
  });

  /// Get a single expense by ID
  Future<ExpenseModel?> getExpenseById(String id);

  /// Get total expenses for a date range
  Future<double> getTotalExpenses({
    DateTime? startDate,
    DateTime? endDate,
    String? category,
  });

  /// Add a new expense
  Future<void> addExpense(ExpenseModel expense);

  /// Update an existing expense
  Future<void> updateExpense(ExpenseModel expense);

  /// Delete an expense by ID
  Future<void> deleteExpense(String id);

  /// Delete all expenses (use with caution!)
  Future<void> deleteAllExpenses();

  /// Search expenses by description
  Future<List<ExpenseModel>> searchExpenses(String query);

  /// Get expenses grouped by category
  Future<Map<String, double>> getExpensesByCategory({
    DateTime? startDate,
    DateTime? endDate,
  });
}