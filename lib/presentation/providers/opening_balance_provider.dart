import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/opening_balance_model.dart';
import '../../domain/repositories/opening_balance_repository.dart';
import 'providers.dart';

/// Provider for opening balance repository
final openingBalanceRepositoryProvider = Provider<OpeningBalanceRepository>((ref) {
  return ref.watch(openingBalanceRepositoryImplProvider);
});

/// Provider for getting opening balance for a specific month/year
final openingBalanceProvider = FutureProvider.family<double, (int, int)>((ref, monthYear) async {
  final repository = ref.watch(openingBalanceRepositoryProvider);
  final (month, year) = monthYear;
  
  final balance = await repository.getOpeningBalance(month, year);
  return balance?.amount ?? 0.0;
});

/// Provider for getting closing balance for a specific month/year
final closingBalanceProvider = FutureProvider.family<double, (int, int)>((ref, monthYear) async {
  final repository = ref.watch(openingBalanceRepositoryProvider);
  final (month, year) = monthYear;
  
  return await repository.calculateClosingBalance(month, year);
});

/// State notifier for managing opening balance
class OpeningBalanceNotifier extends StateNotifier<AsyncValue<List<OpeningBalanceModel>>> {
  final OpeningBalanceRepository _repository;
  final Uuid _uuid = const Uuid();

  OpeningBalanceNotifier(this._repository) : super(const AsyncValue.data([]));

  /// Load all opening balances
  Future<void> loadAll() async {
    state = const AsyncValue.loading();
    try {
      final balances = await _repository.getAllOpeningBalances();
      state = AsyncValue.data(balances);
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
    }
  }

  /// Set opening balance for a month/year
  Future<void> setOpeningBalance(int month, int year, double amount) async {
    try {
      final balance = OpeningBalanceModel(
        id: _uuid.v4(),
        month: month,
        year: year,
        amount: amount,
        createdAt: DateTime.now(),
      );
      
      await _repository.setOpeningBalance(balance);
      
      // Reload all balances
      await loadAll();
    } catch (error) {
      rethrow;
    }
  }

  /// Delete opening balance for a month/year
  Future<void> deleteOpeningBalance(int month, int year) async {
    try {
      await _repository.deleteOpeningBalance(month, year);
      await loadAll();
    } catch (error) {
      rethrow;
    }
  }
}

/// Provider for opening balance notifier
final openingBalanceNotifierProvider = 
    StateNotifierProvider<OpeningBalanceNotifier, AsyncValue<List<OpeningBalanceModel>>>((ref) {
  return OpeningBalanceNotifier(ref.watch(openingBalanceRepositoryProvider));
});
