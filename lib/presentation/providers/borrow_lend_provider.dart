import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_tracker/data/models/borrow_lend_model.dart';
import 'package:expense_tracker/data/models/repayment_model.dart';
import 'package:expense_tracker/domain/repositories/borrow_lend_repository.dart';
import 'providers.dart';

/// State notifier for managing borrow/lend transactions
class BorrowLendNotifier
    extends StateNotifier<AsyncValue<List<BorrowLendModel>>> {
  final BorrowLendRepository _repository;

  BorrowLendNotifier(this._repository) : super(const AsyncValue.data([])) {
    // Don't auto-load - let screens call loadTransactions() when needed
  }

  /// Load all transactions
  Future<void> loadTransactions({
    TransactionType? type,
    TransactionStatus? status,
    String? personName,
  }) async {
    state = const AsyncValue.loading();

    try {
      final transactions = await _repository.getAllTransactions(
        type: type,
        status: status,
        personName: personName,
      );
      state = AsyncValue.data(transactions);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Add new transaction
  Future<void> addTransaction(BorrowLendModel transaction) async {
    try {
      await _repository.addTransaction(transaction);
      await loadTransactions();
    } catch (error) {
      rethrow;
    }
  }

  /// Update existing transaction
  Future<void> updateTransaction(BorrowLendModel transaction) async {
    try {
      await _repository.updateTransaction(transaction);
      await loadTransactions();
    } catch (error) {
      rethrow;
    }
  }

  /// Delete transaction
  Future<void> deleteTransaction(String id) async {
    try {
      await _repository.deleteTransaction(id);
      await loadTransactions();
    } catch (error) {
      rethrow;
    }
  }

  /// Add repayment to a transaction
  Future<void> addRepayment(RepaymentModel repayment) async {
    try {
      await _repository.addRepayment(repayment);
      await loadTransactions();
    } catch (error) {
      rethrow;
    }
  }

  /// Delete repayment
  Future<void> deleteRepayment(String repaymentId) async {
    try {
      await _repository.deleteRepayment(repaymentId);
      await loadTransactions();
    } catch (error) {
      rethrow;
    }
  }

  /// Search by person name
  Future<void> searchByPerson(String query) async {
    state = const AsyncValue.loading();

    try {
      final transactions = await _repository.searchByPerson(query);
      state = AsyncValue.data(transactions);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

/// Provider for borrow/lend transaction list
final borrowLendProvider =
    StateNotifierProvider<
      BorrowLendNotifier,
      AsyncValue<List<BorrowLendModel>>
    >((ref) {
      final repository = ref.watch(borrowLendRepositoryProvider);
      return BorrowLendNotifier(repository);
    });

/// Provider for repayments of a specific transaction
final repaymentsProvider = FutureProvider.family<List<RepaymentModel>, String>((
  ref,
  borrowLendId,
) async {
  final repository = ref.watch(borrowLendRepositoryProvider);
  return await repository.getRepayments(borrowLendId);
});

/// Provider for total borrowed amount
final totalBorrowedProvider = FutureProvider.family<double, bool>((
  ref,
  activeOnly,
) async {
  final repository = ref.watch(borrowLendRepositoryProvider);
  return await repository.getTotalBorrowed(activeOnly: activeOnly);
});

/// Provider for total lent amount
final totalLentProvider = FutureProvider.family<double, bool>((
  ref,
  activeOnly,
) async {
  final repository = ref.watch(borrowLendRepositoryProvider);
  return await repository.getTotalLent(activeOnly: activeOnly);
});

/// Provider for net balance (lent - borrowed)
final netBalanceProvider = FutureProvider.family<double, bool>((
  ref,
  activeOnly,
) async {
  final repository = ref.watch(borrowLendRepositoryProvider);
  return await repository.getNetBalance(activeOnly: activeOnly);
});

/// Provider to check if repayment amount is valid
final canAddRepaymentProvider =
    FutureProvider.family<bool, RepaymentValidationParams>((ref, params) async {
      final repository = ref.watch(borrowLendRepositoryProvider);
      return await repository.canAddRepayment(
        params.borrowLendId,
        params.amount,
      );
    });

/// Helper class for repayment validation parameters
class RepaymentValidationParams {
  final String borrowLendId;
  final double amount;

  RepaymentValidationParams(this.borrowLendId, this.amount);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RepaymentValidationParams &&
          runtimeType == other.runtimeType &&
          borrowLendId == other.borrowLendId &&
          amount == other.amount;

  @override
  int get hashCode => borrowLendId.hashCode ^ amount.hashCode;
}
