import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// Local SQLite database manager
/// 
/// Handles database creation, versioning, and provides access to the DB instance.
/// All tables use TEXT for IDs (UUIDs) and dates (ISO 8601 format).
class LocalDatabase {
  static const String _databaseName = 'expense_tracker.db';
  static const int _databaseVersion = 1;

  // Singleton pattern - only one database instance
  LocalDatabase._privateConstructor();
  static final LocalDatabase instance = LocalDatabase._privateConstructor();

  static Database? _database;

  /// Get database instance (creates if doesn't exist)
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Initialize database
  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onConfigure: _onConfigure,
    );
  }

  /// Enable foreign key constraints
  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  /// Create all tables
  Future<void> _onCreate(Database db, int version) async {
    // Table 1: Expenses
    await db.execute('''
      CREATE TABLE expenses (
        id TEXT PRIMARY KEY,
        amount REAL NOT NULL CHECK(amount > 0),
        category TEXT,
        description TEXT NOT NULL,
        date TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT
      )
    ''');

    // Table 2: Income
    await db.execute('''
      CREATE TABLE income (
        id TEXT PRIMARY KEY,
        amount REAL NOT NULL CHECK(amount > 0),
        source TEXT NOT NULL,
        category TEXT,
        description TEXT NOT NULL,
        date TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT
      )
    ''');

    // Table 3: Borrow/Lend transactions
    await db.execute('''
      CREATE TABLE borrow_lend (
        id TEXT PRIMARY KEY,
        type TEXT NOT NULL CHECK(type IN ('borrowed', 'lent')),
        person_name TEXT NOT NULL,
        original_amount REAL NOT NULL CHECK(original_amount > 0),
        remaining_amount REAL NOT NULL CHECK(remaining_amount >= 0),
        date TEXT NOT NULL,
        status TEXT NOT NULL CHECK(status IN ('active', 'settled')),
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT,
        CHECK(remaining_amount <= original_amount)
      )
    ''');

    // Table 4: Repayments (linked to borrow_lend)
    await db.execute('''
      CREATE TABLE repayments (
        id TEXT PRIMARY KEY,
        borrow_lend_id TEXT NOT NULL,
        amount REAL NOT NULL CHECK(amount > 0),
        date TEXT NOT NULL,
        notes TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (borrow_lend_id) 
          REFERENCES borrow_lend (id) 
          ON DELETE CASCADE
      )
    ''');

    // Indexes for common queries
    await db.execute('CREATE INDEX idx_expenses_date ON expenses(date DESC)');
    await db.execute('CREATE INDEX idx_income_date ON income(date DESC)');
    await db.execute('CREATE INDEX idx_borrow_lend_status ON borrow_lend(status)');
    await db.execute('CREATE INDEX idx_borrow_lend_person ON borrow_lend(person_name)');
    await db.execute('CREATE INDEX idx_repayments_borrow_lend ON repayments(borrow_lend_id)');
  }

  /// Close database connection
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }

  /// Delete database (useful for testing or reset)
  Future<void> deleteDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _databaseName);
    await databaseFactory.deleteDatabase(path);
    _database = null;
  }

  /// Get database statistics (for debugging)
  Future<Map<String, int>> getStats() async {
    final db = await database;
    
    final expenseCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM expenses')
    ) ?? 0;
    
    final incomeCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM income')
    ) ?? 0;
    
    final borrowLendCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM borrow_lend')
    ) ?? 0;
    
    final repaymentCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM repayments')
    ) ?? 0;

    return {
      'expenses': expenseCount,
      'income': incomeCount,
      'borrow_lend': borrowLendCount,
      'repayments': repaymentCount,
    };
  }
}