import 'package:sqflite/sqflite.dart';
import 'package:expense_tracker/domain/repositories/expense_repository.dart';
import 'package:expense_tracker/data/models/expense_model.dart';
import 'package:expense_tracker/data/datasources/local_database.dart';

/// SQLite implementation of ExpenseRepository
class ExpenseRepositoryImpl implements ExpenseRepository {
  final LocalDatabase _localDatabase;
  Database? _cachedDb;

  ExpenseRepositoryImpl(this._localDatabase);

  Future<Database> get _db async {
    _cachedDb ??= await _localDatabase.database;
    return _cachedDb!;
  }

  @override
  Future<List<ExpenseModel>> getAllExpenses({
    DateTime? startDate,
    DateTime? endDate,
    String? category,
    int? limit,
    int? offset,
  }) async {
    final db = await _db;
    
    String whereClause = '';
    List<dynamic> whereArgs = [];

    // Build WHERE clause dynamically
    if (startDate != null) {
      whereClause += 'date >= ?';
      whereArgs.add(startDate.toIso8601String());
    }
    
    if (endDate != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'date <= ?';
      whereArgs.add(endDate.toIso8601String());
    }
    
    if (category != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'category = ?';
      whereArgs.add(category);
    }

    final results = await db.query(
      'expenses',
      where: whereClause.isEmpty ? null : whereClause,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'date DESC, created_at DESC',
      limit: limit,
      offset: offset,
    );

    return results.map((map) => ExpenseModel.fromMap(map)).toList();
  }

  @override
  Future<ExpenseModel?> getExpenseById(String id) async {
    final db = await _db;
    
    final results = await db.query(
      'expenses',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (results.isEmpty) return null;
    return ExpenseModel.fromMap(results.first);
  }

  @override
  Future<double> getTotalExpenses({
    DateTime? startDate,
    DateTime? endDate,
    String? category,
  }) async {
    final db = await _db;
    
    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (startDate != null) {
      whereClause += 'date >= ?';
      whereArgs.add(startDate.toIso8601String());
    }
    
    if (endDate != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'date <= ?';
      whereArgs.add(endDate.toIso8601String());
    }
    
    if (category != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'category = ?';
      whereArgs.add(category);
    }

    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(amount), 0.0) as total FROM expenses'
      '${whereClause.isEmpty ? '' : ' WHERE $whereClause'}',
      whereArgs.isEmpty ? null : whereArgs,
    );

    return result.first['total'] as double;
  }

  @override
  Future<void> addExpense(ExpenseModel expense) async {
    // Validate before saving
    final validationError = expense.validate();
    if (validationError != null) {
      throw ArgumentError(validationError);
    }

    final db = await _db;
    await db.insert(
      'expenses',
      expense.toMap(),
      conflictAlgorithm: ConflictAlgorithm.fail,
    );
  }

  @override
  Future<void> updateExpense(ExpenseModel expense) async {
    final validationError = expense.validate();
    if (validationError != null) {
      throw ArgumentError(validationError);
    }

    final db = await _db;
    
    final updatedExpense = expense.copyWith(
      updatedAt: DateTime.now(),
    );

    final count = await db.update(
      'expenses',
      updatedExpense.toMap(),
      where: 'id = ?',
      whereArgs: [expense.id],
    );

    if (count == 0) {
      throw StateError('Expense with id ${expense.id} not found');
    }
  }

  @override
  Future<void> deleteExpense(String id) async {
    final db = await _db;
    
    final count = await db.delete(
      'expenses',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (count == 0) {
      throw StateError('Expense with id $id not found');
    }
  }

  @override
  Future<void> deleteAllExpenses() async {
    final db = await _db;
    await db.delete('expenses');
  }

  @override
  Future<List<ExpenseModel>> searchExpenses(String query) async {
    final db = await _db;
    
    final results = await db.query(
      'expenses',
      where: 'description LIKE ? OR category LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'date DESC',
    );

    return results.map((map) => ExpenseModel.fromMap(map)).toList();
  }

  @override
  Future<Map<String, double>> getExpensesByCategory({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await _db;
    
    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (startDate != null) {
      whereClause += 'date >= ?';
      whereArgs.add(startDate.toIso8601String());
    }
    
    if (endDate != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'date <= ?';
      whereArgs.add(endDate.toIso8601String());
    }

    final results = await db.rawQuery(
      'SELECT COALESCE(category, "Uncategorized") as category, SUM(amount) as total '
      'FROM expenses'
      '${whereClause.isEmpty ? '' : ' WHERE $whereClause'}'
      ' GROUP BY category',
      whereArgs.isEmpty ? null : whereArgs,
    );

    return Map.fromEntries(
      results.map((row) => MapEntry(
        row['category'] as String,
        row['total'] as double,
      )),
    );
  }
}
