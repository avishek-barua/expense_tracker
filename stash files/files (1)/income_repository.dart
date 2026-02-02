import 'package:expense_tracker/data/models/income_model.dart';

/// Abstract interface for income data operations
abstract class IncomeRepository {
  /// Get all income entries, optionally filtered and sorted
  Future<List<IncomeModel>> getAllIncome({
    DateTime? startDate,
    DateTime? endDate,
    String? category,
    int? limit,
    int? offset,
  });

  /// Get a single income entry by ID
  Future<IncomeModel?> getIncomeById(String id);

  /// Get total income for a date range
  Future<double> getTotalIncome({
    DateTime? startDate,
    DateTime? endDate,
    String? category,
  });

  /// Add a new income entry
  Future<void> addIncome(IncomeModel income);

  /// Update an existing income entry
  Future<void> updateIncome(IncomeModel income);

  /// Delete an income entry by ID
  Future<void> deleteIncome(String id);

  /// Delete all income entries (use with caution!)
  Future<void> deleteAllIncome();

  /// Search income by description or source
  Future<List<IncomeModel>> searchIncome(String query);

  /// Get income grouped by source
  Future<Map<String, double>> getIncomeBySource({
    DateTime? startDate,
    DateTime? endDate,
  });
}
