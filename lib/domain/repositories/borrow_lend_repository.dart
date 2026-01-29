import '../../data/models/borrow_lend_model.dart';
import '../../data/models/repayment_model.dart';

/// Abstract interface for borrow/lend data operations
abstract class BorrowLendRepository {
  /// Get all borrow/lend transactions
  Future<List<BorrowLendModel>> getAllTransactions({
    TransactionType? type,
    TransactionStatus? status,
    String? personName,
  });

  /// Get a single transaction by ID
  Future<BorrowLendModel?> getTransactionById(String id);

  /// Add a new borrow/lend transaction
  Future<void> addTransaction(BorrowLendModel transaction);

  /// Update an existing transaction
  Future<void> updateTransaction(BorrowLendModel transaction);

  /// Delete a transaction (cascades to repayments)
  Future<void> deleteTransaction(String id);

  /// Get all repayments for a specific transaction
  Future<List<RepaymentModel>> getRepayments(String borrowLendId);

  /// Add a repayment and update the parent transaction
  /// Returns updated BorrowLendModel
  Future<BorrowLendModel> addRepayment(RepaymentModel repayment);

  /// Delete a repayment and recalculate parent transaction
  Future<void> deleteRepayment(String repaymentId);

  /// Get total borrowed amount (active loans you owe)
  Future<double> getTotalBorrowed({bool activeOnly = true});

  /// Get total lent amount (active loans others owe you)
  Future<double> getTotalLent({bool activeOnly = true});

  /// Get net balance (money lent - money borrowed)
  Future<double> getNetBalance({bool activeOnly = true});

  /// Search transactions by person name
  Future<List<BorrowLendModel>> searchByPerson(String query);

  /// Validate repayment amount doesn't exceed remaining balance
  Future<bool> canAddRepayment(String borrowLendId, double amount);
}