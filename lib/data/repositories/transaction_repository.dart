import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/transaction_model.dart';

class TransactionRepository {
  static final TransactionRepository _instance = TransactionRepository._internal();
  factory TransactionRepository() => _instance;
  TransactionRepository._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'pos_database.db');
    return await openDatabase(
      path,
      version: 4,
      onCreate: (db, version) async {
        await _createTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS expenses (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              title TEXT NOT NULL,
              amount REAL NOT NULL,
              expense_date TEXT NOT NULL
            )
          ''');
        }
        if (oldVersion < 3) {
          await db.execute('ALTER TABLE transactions ADD COLUMN notes TEXT');
        }
        if (oldVersion < 4) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS other_incomes (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              title TEXT NOT NULL,
              amount REAL NOT NULL,
              income_date TEXT NOT NULL
            )
          ''');
        }
      },
    );
  }

  Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS transactions (
        id TEXT PRIMARY KEY,
        transactionDate TEXT NOT NULL,
        totalAmount REAL NOT NULL,
        paymentStatus TEXT NOT NULL,
        customerName TEXT,
        paymentMethod TEXT,
        itemsJson TEXT,
        notes TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        expense_date TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS other_incomes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        income_date TEXT NOT NULL
      )
    ''');
  }

  // --- SAFETY CHECK (Pencegah Bug "No Such Table") ---
  Future<void> _ensureTablesExist(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        expense_date TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS other_incomes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        income_date TEXT NOT NULL
      )
    ''');
  }

  // --- TRANSAKSI PENJUALAN ---
  Future<List<TransactionModel>> getTransactions() async {
    final db = await database;
    final maps = await db.query('transactions', orderBy: 'transactionDate DESC');
    return maps.map((map) => TransactionModel.fromMap(map)).toList();
  }

  // --- PENGELUARAN OPERASIONAL ---
  Future<int> createExpense(String title, double amount) async {
    final db = await database;
    await _ensureTablesExist(db);
    return await db.insert('expenses', {
      'title': title,
      'amount': amount,
      'expense_date': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getExpenses() async {
    final db = await database;
    await _ensureTablesExist(db);
    return await db.query('expenses', orderBy: 'id DESC');
  }

  Future<int> deleteExpense(int id) async {
    final db = await database;
    await _ensureTablesExist(db);
    return await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }

  // --- PEMASUKAN KAS LAINNYA ---
  Future<int> createOtherIncome(String title, double amount) async {
    final db = await database;
    await _ensureTablesExist(db);
    return await db.insert('other_incomes', {
      'title': title,
      'amount': amount,
      'income_date': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getOtherIncomes() async {
    final db = await database;
    await _ensureTablesExist(db);
    return await db.query('other_incomes', orderBy: 'id DESC');
  }

  Future<int> deleteOtherIncome(int id) async {
    final db = await database;
    await _ensureTablesExist(db);
    return await db.delete('other_incomes', where: 'id = ?', whereArgs: [id]);
  }
}
