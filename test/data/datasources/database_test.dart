import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:expense_tracker/data/datasources/local_database.dart';
import 'package:expense_tracker/data/models/expense_model.dart';
import 'package:expense_tracker/data/models/income_model.dart';
import 'package:expense_tracker/data/models/borrow_lend_model.dart';
import 'package:expense_tracker/data/models/repayment_model.dart';

void main() {
  // Initialize FFI for desktop testing
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Database Tests', () {
    late Database db;

    setUp(() async {
      // Get fresh database for each test
      db = await LocalDatabase.instance.database;
    });

    tearDown(() async {
      // Clean up after each test
      await LocalDatabase.instance.deleteDatabase();
    });

    test('Database creates all tables', () async {
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table'"
      );
      
      final tableNames = tables.map((t) => t['name'] as String).toList();
      
      expect(tableNames, contains('expenses'));
      expect(tableNames, contains('income'));
      expect(tableNames, contains('borrow_lend'));
      expect(tableNames, contains('repayments'));
    });

    test('Can insert and read an expense', () async {
      final expense = ExpenseModel.create(
        amount: 500.0,
        category: 'Food',
        description: 'Lunch at restaurant',
        date: DateTime.now(),
      );

      await db.insert('expenses', expense.toMap());

      final results = await db.query('expenses');
      expect(results.length, 1);
      
      final retrieved = ExpenseModel.fromMap(results.first);
      expect(retrieved.id, expense.id);
      expect(retrieved.amount, 500.0);
      expect(retrieved.category, 'Food');
    });

    test('Can insert and read income', () async {
      final income = IncomeModel.create(
        amount: 2000.0,
        source: 'January Salary',
        category: 'Salary',
        description: 'Monthly salary payment',
        date: DateTime.now(),
      );

      await db.insert('income', income.toMap());

      final results = await db.query('income');
      expect(results.length, 1);
      
      final retrieved = IncomeModel.fromMap(results.first);
      expect(retrieved.amount, 2000.0);
      expect(retrieved.source, 'January Salary');
    });

    test('Foreign key cascade deletes repayments when loan is deleted', () async {
      // Create a loan
      final loan = BorrowLendModel.create(
        type: TransactionType.lent,
        personName: 'John',
        amount: 1000.0,
        date: DateTime.now(),
      );
      await db.insert('borrow_lend', loan.toMap());

      // Create a repayment
      final repayment = RepaymentModel.create(
        borrowLendId: loan.id,
        amount: 200.0,
        date: DateTime.now(),
      );
      await db.insert('repayments', repayment.toMap());

      // Verify both exist
      expect((await db.query('borrow_lend')).length, 1);
      expect((await db.query('repayments')).length, 1);

      // Delete the loan
      await db.delete('borrow_lend', where: 'id = ?', whereArgs: [loan.id]);

      // Repayment should be auto-deleted (CASCADE)
      expect((await db.query('borrow_lend')).length, 0);
      expect((await db.query('repayments')).length, 0);
    });

    test('CHECK constraint prevents negative amounts', () async {
      final invalidExpense = ExpenseModel.create(
        amount: -100.0,  // Invalid!
        description: 'Invalid expense',
        date: DateTime.now(),
      );

      expect(
        () async => await db.insert('expenses', invalidExpense.toMap()),
        throwsA(isA<DatabaseException>()),
      );
    });

    test('Database stats returns correct counts', () async {
      // Insert test data
      await db.insert('expenses', ExpenseModel.create(
        amount: 100, description: 'Test', date: DateTime.now()
      ).toMap());
      
      await db.insert('income', IncomeModel.create(
        amount: 200, source: 'Test', description: 'Test', date: DateTime.now()
      ).toMap());

      final stats = await LocalDatabase.instance.getStats();
      
      expect(stats['expenses'], 1);
      expect(stats['income'], 1);
      expect(stats['borrow_lend'], 0);
      expect(stats['repayments'], 0);
    });
  });
}