import 'package:sqflite/sqflite.dart';
import 'package:expense_tracker/domain/repositories/income_repository.dart';
import 'package:expense_tracker/data/models/income_model.dart';
import 'package:expense_tracker/data/datasources/local_database.dart';

/// SQLite implementation of IncomeRepository
class IncomeRepositoryImpl implements IncomeRepository {
  final LocalDatabase _localDatabase;
  Database? _cachedDb;

  IncomeRepositoryImpl(this._localDatabase);

  Future<Database> get _db async {
    _cachedDb ??= await _localDatabase.database;
    return _cachedDb!;
  }

  @override
  Future<List<IncomeModel>> getAllIncome({
    DateTime? startDate,
    DateTime? endDate,
    String? category,
    int? limit,
    int? offset,
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

    final results = await db.query(
      'income',
      where: whereClause.isEmpty ? null : whereClause,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'date DESC, created_at DESC',
      limit: limit,
      offset: offset,
    );

    return results.map((map) => IncomeModel.fromMap(map)).toList();
  }

  @override
  Future<IncomeModel?> getIncomeById(String id) async {
    final db = await _db;

    final results = await db.query(
      'income',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (results.isEmpty) return null;
    return IncomeModel.fromMap(results.first);
  }

  @override
  Future<double> getTotalIncome({
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
      'SELECT COALESCE(SUM(amount), 0.0) as total FROM income'
      '${whereClause.isEmpty ? '' : ' WHERE $whereClause'}',
      whereArgs.isEmpty ? null : whereArgs,
    );

    return result.first['total'] as double;
  }

  @override
  Future<void> addIncome(IncomeModel income) async {
    final validationError = income.validate();
    if (validationError != null) {
      throw ArgumentError(validationError);
    }

    final db = await _db;
    await db.insert(
      'income',
      income.toMap(),
      conflictAlgorithm: ConflictAlgorithm.fail,
    );
  }

  @override
  Future<void> updateIncome(IncomeModel income) async {
    final validationError = income.validate();
    if (validationError != null) {
      throw ArgumentError(validationError);
    }

    final db = await _db;

    final updatedIncome = income.copyWith(updatedAt: DateTime.now());

    final count = await db.update(
      'income',
      updatedIncome.toMap(),
      where: 'id = ?',
      whereArgs: [income.id],
    );

    if (count == 0) {
      throw StateError('Income with id ${income.id} not found');
    }
  }

  @override
  Future<void> deleteIncome(String id) async {
    final db = await _db;

    final count = await db.delete('income', where: 'id = ?', whereArgs: [id]);

    if (count == 0) {
      throw StateError('Income with id $id not found');
    }
  }

  @override
  Future<void> deleteAllIncome() async {
    final db = await _db;
    await db.delete('income');
  }

  @override
  Future<List<IncomeModel>> searchIncome(String query) async {
    final db = await _db;

    final results = await db.query(
      'income',
      where: 'description LIKE ? OR source LIKE ? OR category LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
      orderBy: 'date DESC',
    );

    return results.map((map) => IncomeModel.fromMap(map)).toList();
  }

  @override
  Future<Map<String, double>> getIncomeBySource({
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
      'SELECT source, SUM(amount) as total '
      'FROM income'
      '${whereClause.isEmpty ? '' : ' WHERE $whereClause'}'
      ' GROUP BY source',
      whereArgs.isEmpty ? null : whereArgs,
    );

    return Map.fromEntries(
      results.map(
        (row) => MapEntry(row['source'] as String, row['total'] as double),
      ),
    );
  }
}
