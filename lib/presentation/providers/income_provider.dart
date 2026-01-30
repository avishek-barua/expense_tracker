import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_tracker/data/models/income_model.dart';
import 'package:expense_tracker/domain/repositories/income_repository.dart';
import 'providers.dart';
import 'expense_provider.dart'; // For DateRange

/// State notifier for managing income list
class IncomeNotifier extends StateNotifier<AsyncValue<List<IncomeModel>>> {
  final IncomeRepository _repository;

  IncomeNotifier(this._repository) : super(const AsyncValue.data([])) {
    // Don't auto-load - let screens call loadIncome() when needed
  }

  /// Load all income entries
  Future<void> loadIncome({
    DateTime? startDate,
    DateTime? endDate,
    String? category,
  }) async {
    state = const AsyncValue.loading();

    try {
      final income = await _repository.getAllIncome(
        startDate: startDate,
        endDate: endDate,
        category: category,
      );
      state = AsyncValue.data(income);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Add new income
  Future<void> addIncome(IncomeModel income) async {
    try {
      await _repository.addIncome(income);
      await loadIncome();
    } catch (error) {
      rethrow;
    }
  }

  /// Update existing income
  Future<void> updateIncome(IncomeModel income) async {
    try {
      await _repository.updateIncome(income);
      await loadIncome();
    } catch (error) {
      rethrow;
    }
  }

  /// Delete income
  Future<void> deleteIncome(String id) async {
    try {
      await _repository.deleteIncome(id);
      await loadIncome();
    } catch (error) {
      rethrow;
    }
  }

  /// Search income
  Future<void> searchIncome(String query) async {
    state = const AsyncValue.loading();

    try {
      final income = await _repository.searchIncome(query);
      state = AsyncValue.data(income);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

/// Provider for income list
final incomeProvider =
    StateNotifierProvider<IncomeNotifier, AsyncValue<List<IncomeModel>>>((ref) {
      final repository = ref.watch(incomeRepositoryProvider);
      return IncomeNotifier(repository);
    });

/// Provider for total income (computed)
final totalIncomeProvider = FutureProvider.family<double, DateRange?>((
  ref,
  dateRange,
) async {
  final repository = ref.watch(incomeRepositoryProvider);
  return await repository.getTotalIncome(
    startDate: dateRange?.start,
    endDate: dateRange?.end,
  );
});

/// Provider for income by source
final incomeBySourceProvider =
    FutureProvider.family<Map<String, double>, DateRange?>((
      ref,
      dateRange,
    ) async {
      final repository = ref.watch(incomeRepositoryProvider);
      return await repository.getIncomeBySource(
        startDate: dateRange?.start,
        endDate: dateRange?.end,
      );
    });
