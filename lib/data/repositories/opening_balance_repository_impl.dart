import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../../domain/repositories/opening_balance_repository.dart';
import '../models/opening_balance_model.dart';
import '../datasources/local_database.dart';

class OpeningBalanceRepositoryImpl implements OpeningBalanceRepository {
  final LocalDatabase _localDatabase;
  final Uuid _uuid = const Uuid();
  
  // Cache database reference
  Database? _cachedDb;
  Future<Database> get _db async {
    _cachedDb ??= await _localDatabase.database;
    return _cachedDb!;
  }

  OpeningBalanceRepositoryImpl(this._localDatabase);

  @override
  Future<OpeningBalanceModel?> getOpeningBalance(int month, int year) async {
    final db = await _db;
    
    final results = await db.query(
      'opening_balances',
      where: 'month = ? AND year = ?',
      whereArgs: [month, year],
      limit: 1,
    );

    if (results.isEmpty) {
      return null;
    }

    return OpeningBalanceModel.fromMap(results.first);
  }

  @override
  Future<void> setOpeningBalance(OpeningBalanceModel balance) async {
    final validationError = balance.validate();
    if (validationError != null) {
      throw ArgumentError(validationError);
    }

    final db = await _db;
    
    // Check if already exists
    final existing = await getOpeningBalance(balance.month, balance.year);
    
    if (existing != null) {
      // Update existing
      await db.update(
        'opening_balances',
        balance.copyWith(
          id: existing.id, // Keep original ID
          createdAt: existing.createdAt, // Keep original creation date
        ).toMap(),
        where: 'id = ?',
        whereArgs: [existing.id],
      );
    } else {
      // Insert new
      await db.insert(
        'opening_balances',
        balance.toMap(),
        conflictAlgorithm: ConflictAlgorithm.fail,
      );
    }
  }

  @override
  Future<void> deleteOpeningBalance(int month, int year) async {
    final db = await _db;
    
    await db.delete(
      'opening_balances',
      where: 'month = ? AND year = ?',
      whereArgs: [month, year],
    );
  }

  @override
  Future<List<OpeningBalanceModel>> getAllOpeningBalances() async {
    final db = await _db;
    
    final results = await db.query(
      'opening_balances',
      orderBy: 'year DESC, month DESC',
    );

    return results.map((map) => OpeningBalanceModel.fromMap(map)).toList();
  }

  @override
  Future<double> calculateClosingBalance(int month, int year) async {
    final db = await _db;
    
    // Get opening balance
    final opening = await getOpeningBalance(month, year);
    final openingAmount = opening?.amount ?? 0.0;
    
    // Calculate date range for the month
    final startDate = DateTime(year, month, 1).toIso8601String();
    final endDate = DateTime(year, month + 1, 0, 23, 59, 59).toIso8601String();
    
    // Get total income
    final incomeResult = await db.rawQuery(
      'SELECT SUM(amount) as total FROM income WHERE date >= ? AND date <= ?',
      [startDate, endDate],
    );
    final totalIncome = (incomeResult.first['total'] as num?)?.toDouble() ?? 0.0;
    
    // Get total expenses
    final expenseResult = await db.rawQuery(
      'SELECT SUM(amount) as total FROM expenses WHERE date >= ? AND date <= ?',
      [startDate, endDate],
    );
    final totalExpenses = (expenseResult.first['total'] as num?)?.toDouble() ?? 0.0;
    
    // Get borrowed amount (money received)
    final borrowedResult = await db.rawQuery(
      '''SELECT SUM(original_amount) as total FROM borrow_lend 
         WHERE type = 'borrowed' AND date >= ? AND date <= ?''',
      [startDate, endDate],
    );
    final totalBorrowed = (borrowedResult.first['total'] as num?)?.toDouble() ?? 0.0;
    
    // Get lent amount (money given)
    final lentResult = await db.rawQuery(
      '''SELECT SUM(original_amount) as total FROM borrow_lend 
         WHERE type = 'lent' AND date >= ? AND date <= ?''',
      [startDate, endDate],
    );
    final totalLent = (lentResult.first['total'] as num?)?.toDouble() ?? 0.0;
    
    // Calculate closing balance
    final closingBalance = openingAmount + totalIncome - totalExpenses + totalBorrowed - totalLent;
    
    return closingBalance;
  }
  
  /// Helper: Generate a new UUID
  String generateId() => _uuid.v4();
}
