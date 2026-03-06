import '../../data/models/opening_balance_model.dart';

/// Repository interface for opening balance operations
abstract class OpeningBalanceRepository {
  /// Get opening balance for a specific month/year
  Future<OpeningBalanceModel?> getOpeningBalance(int month, int year);

  /// Set opening balance for a specific month/year
  /// If already exists, updates it
  Future<void> setOpeningBalance(OpeningBalanceModel balance);

  /// Delete opening balance for a specific month/year
  Future<void> deleteOpeningBalance(int month, int year);

  /// Get all opening balances (for history/reports)
  Future<List<OpeningBalanceModel>> getAllOpeningBalances();

  /// Calculate closing balance for a month
  /// (Opening + Income - Expenses + Borrowed - Lent)
  Future<double> calculateClosingBalance(int month, int year);
}
