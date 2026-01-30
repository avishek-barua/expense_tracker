import 'package:sqflite/sqflite.dart';
import 'package:expense_tracker/domain/repositories/borrow_lend_repository.dart';
import 'package:expense_tracker/data/models/borrow_lend_model.dart';
import 'package:expense_tracker/data/models/repayment_model.dart';
import 'package:expense_tracker/data/datasources/local_database.dart';

/// SQLite implementation of BorrowLendRepository
class BorrowLendRepositoryImpl implements BorrowLendRepository {
  final LocalDatabase _localDatabase;
  Database? _cachedDb;

  BorrowLendRepositoryImpl(this._localDatabase);

  Future<Database> get _db async {
    _cachedDb ??= await _localDatabase.database;
    return _cachedDb!;
  }

  @override
  Future<List<BorrowLendModel>> getAllTransactions({
    TransactionType? type,
    TransactionStatus? status,
    String? personName,
  }) async {
    final db = await _db;

    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (type != null) {
      whereClause += 'type = ?';
      whereArgs.add(type.value);
    }

    if (status != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'status = ?';
      whereArgs.add(status.value);
    }

    if (personName != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'person_name LIKE ?';
      whereArgs.add('%$personName%');
    }

    final results = await db.query(
      'borrow_lend',
      where: whereClause.isEmpty ? null : whereClause,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'date DESC, created_at DESC',
    );

    return results.map((map) => BorrowLendModel.fromMap(map)).toList();
  }

  @override
  Future<BorrowLendModel?> getTransactionById(String id) async {
    final db = await _db;

    final results = await db.query(
      'borrow_lend',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (results.isEmpty) return null;
    return BorrowLendModel.fromMap(results.first);
  }

  @override
  Future<void> addTransaction(BorrowLendModel transaction) async {
    final validationError = transaction.validate();
    if (validationError != null) {
      throw ArgumentError(validationError);
    }

    final db = await _db;
    await db.insert(
      'borrow_lend',
      transaction.toMap(),
      conflictAlgorithm: ConflictAlgorithm.fail,
    );
  }

  @override
  Future<void> updateTransaction(BorrowLendModel transaction) async {
    final validationError = transaction.validate();
    if (validationError != null) {
      throw ArgumentError(validationError);
    }

    final db = await _db;

    final updatedTransaction = transaction.copyWith(updatedAt: DateTime.now());

    final count = await db.update(
      'borrow_lend',
      updatedTransaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );

    if (count == 0) {
      throw StateError('Transaction with id ${transaction.id} not found');
    }
  }

  @override
  Future<void> deleteTransaction(String id) async {
    final db = await _db;

    // Foreign key cascade will auto-delete repayments
    final count = await db.delete(
      'borrow_lend',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (count == 0) {
      throw StateError('Transaction with id $id not found');
    }
  }

  @override
  Future<List<RepaymentModel>> getRepayments(String borrowLendId) async {
    final db = await _db;

    final results = await db.query(
      'repayments',
      where: 'borrow_lend_id = ?',
      whereArgs: [borrowLendId],
      orderBy: 'date DESC',
    );

    return results.map((map) => RepaymentModel.fromMap(map)).toList();
  }

  @override
  Future<BorrowLendModel> addRepayment(RepaymentModel repayment) async {
    final validationError = repayment.validate();
    if (validationError != null) {
      throw ArgumentError(validationError);
    }

    final db = await _db;

    // Get the parent transaction
    final transaction = await getTransactionById(repayment.borrowLendId);
    if (transaction == null) {
      throw StateError(
        'Transaction with id ${repayment.borrowLendId} not found',
      );
    }

    // Validate repayment amount
    if (repayment.amount > transaction.remainingAmount + 0.01) {
      throw ArgumentError(
        'Repayment amount (${repayment.amount}) exceeds remaining balance (${transaction.remainingAmount})',
      );
    }

    // Use transaction to ensure atomicity
    await db.transaction((txn) async {
      // Insert repayment
      await txn.insert(
        'repayments',
        repayment.toMap(),
        conflictAlgorithm: ConflictAlgorithm.fail,
      );

      // Update parent transaction
      final updatedTransaction = transaction.applyRepayment(repayment.amount);
      await txn.update(
        'borrow_lend',
        updatedTransaction.toMap(),
        where: 'id = ?',
        whereArgs: [transaction.id],
      );
    });

    // Return updated transaction
    return (await getTransactionById(transaction.id))!;
  }

  @override
  Future<void> deleteRepayment(String repaymentId) async {
    final db = await _db;

    // Get the repayment
    final repaymentResults = await db.query(
      'repayments',
      where: 'id = ?',
      whereArgs: [repaymentId],
      limit: 1,
    );

    if (repaymentResults.isEmpty) {
      throw StateError('Repayment with id $repaymentId not found');
    }

    final repayment = RepaymentModel.fromMap(repaymentResults.first);

    // Get parent transaction
    final transaction = await getTransactionById(repayment.borrowLendId);
    if (transaction == null) {
      throw StateError('Parent transaction not found');
    }

    // Use transaction to ensure atomicity
    await db.transaction((txn) async {
      // Delete repayment
      await txn.delete('repayments', where: 'id = ?', whereArgs: [repaymentId]);

      // Recalculate remaining amount from scratch
      final allRepayments = await getRepayments(transaction.id);
      final totalRepaid = allRepayments
          .where((r) => r.id != repaymentId) // Exclude deleted one
          .fold<double>(0.0, (sum, r) => sum + r.amount);

      final newRemaining = transaction.originalAmount - totalRepaid;
      final newStatus = newRemaining <= 0.01
          ? TransactionStatus.settled
          : TransactionStatus.active;

      // Update parent transaction
      final updatedTransaction = transaction.copyWith(
        remainingAmount: newRemaining,
        status: newStatus,
        updatedAt: DateTime.now(),
      );

      await txn.update(
        'borrow_lend',
        updatedTransaction.toMap(),
        where: 'id = ?',
        whereArgs: [transaction.id],
      );
    });
  }

  @override
  Future<double> getTotalBorrowed({bool activeOnly = true}) async {
    final db = await _db;

    final whereClause = activeOnly
        ? "type = 'borrowed' AND status = 'active'"
        : "type = 'borrowed'";

    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(remaining_amount), 0.0) as total FROM borrow_lend WHERE $whereClause',
    );

    return result.first['total'] as double;
  }

  @override
  Future<double> getTotalLent({bool activeOnly = true}) async {
    final db = await _db;

    final whereClause = activeOnly
        ? "type = 'lent' AND status = 'active'"
        : "type = 'lent'";

    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(remaining_amount), 0.0) as total FROM borrow_lend WHERE $whereClause',
    );

    return result.first['total'] as double;
  }

  @override
  Future<double> getNetBalance({bool activeOnly = true}) async {
    final lent = await getTotalLent(activeOnly: activeOnly);
    final borrowed = await getTotalBorrowed(activeOnly: activeOnly);
    return lent - borrowed;
  }

  @override
  Future<List<BorrowLendModel>> searchByPerson(String query) async {
    final db = await _db;

    final results = await db.query(
      'borrow_lend',
      where: 'person_name LIKE ?',
      whereArgs: ['%$query%'],
      orderBy: 'date DESC',
    );

    return results.map((map) => BorrowLendModel.fromMap(map)).toList();
  }

  @override
  Future<bool> canAddRepayment(String borrowLendId, double amount) async {
    final transaction = await getTransactionById(borrowLendId);
    if (transaction == null) return false;
    return amount <=
        transaction.remainingAmount + 0.01; // Epsilon for float comparison
  }
}
