import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/transaction_model.dart';

class TransactionRepository {
  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'kasir_pintar.db');

    return await openDatabase(
      path,
      version: 2, // Naikkan versi ke 2 untuk memicu update tabel
      onCreate: (db, version) async {
        await _createTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // Buat tabel expenses jika user melakukan upgrade dari v1
          await db.execute('''
            CREATE TABLE IF NOT EXISTS expenses (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              title TEXT NOT NULL,
              amount REAL NOT NULL,
              expense_date TEXT NOT NULL
            )
          ''');
        }
      },
    );
  }

  Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        buy_price REAL DEFAULT 0,
        sell_price REAL DEFAULT 0,
        stock INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customer_id INTEGER,
        payment_status TEXT NOT NULL,
        subtotal REAL NOT NULL,
        total_amount REAL NOT NULL,
        transaction_date TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS transaction_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        transaction_id TEXT NOT NULL,
        product_id INTEGER NOT NULL,
        product_name TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        buy_price REAL NOT NULL,
        sell_price REAL NOT NULL,
        subtotal REAL NOT NULL
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
  }

  // --- 1. MEMBUAT TRANSAKSI BARU ---
  Future<int> createTransaction(TransactionModel transaction) async {
    final db = await database;
    int generatedId = 0;

    await db.transaction((txn) async {
      generatedId = await txn.insert(
        'transactions',
        transaction.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      final String actualTrxId = transaction.id?.toString() ?? generatedId.toString();

      await txn.delete(
        'transaction_items',
        where: 'transaction_id = ?',
        whereArgs: [actualTrxId],
      );

      for (var item in transaction.items) {
        var itemMap = item.toMap();
        itemMap['transaction_id'] = actualTrxId;
        await txn.insert('transaction_items', itemMap);

        await txn.rawUpdate(
          'UPDATE products SET stock = stock - ? WHERE id = ?',
          [item.quantity, item.productId],
        );
      }
    });

    return generatedId;
  }

  // --- 2. MEMPERBARUI (EDIT) TRANSAKSI ---
  Future<void> updateTransaction(TransactionModel transaction) async {
    final db = await database;
    final String trxId = transaction.id.toString();

    await db.transaction((txn) async {
      final List<Map<String, dynamic>> oldItemsMap = await txn.query(
        'transaction_items',
        where: 'transaction_id = ?',
        whereArgs: [trxId],
      );

      for (var oldMap in oldItemsMap) {
        final int oldProductId = oldMap['product_id'];
        final int oldQuantity = oldMap['quantity'];

        await txn.rawUpdate(
          'UPDATE products SET stock = stock + ? WHERE id = ?',
          [oldQuantity, oldProductId],
        );
      }

      await txn.update(
        'transactions',
        transaction.toMap(),
        where: 'id = ?',
        whereArgs: [trxId],
      );

      await txn.delete(
        'transaction_items',
        where: 'transaction_id = ?',
        whereArgs: [trxId],
      );

      for (var item in transaction.items) {
        var itemMap = item.toMap();
        itemMap['transaction_id'] = trxId;
        await txn.insert('transaction_items', itemMap);

        await txn.rawUpdate(
          'UPDATE products SET stock = stock - ? WHERE id = ?',
          [item.quantity, item.productId],
        );
      }
    });
  }

  // --- 3. MENGAMBIL DAFTAR TRANSAKSI ---
  Future<List<TransactionModel>> getTransactions() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'transactions',
        orderBy: 'transaction_date DESC',
      );

      List<TransactionModel> transactions = [];

      for (var map in maps) {
        final List<Map<String, dynamic>> itemMaps = await db.query(
          'transaction_items',
          where: 'transaction_id = ?',
          whereArgs: [map['id'].toString()],
        );

        List<TransactionItemModel> items =
            itemMaps.map((i) => TransactionItemModel.fromMap(i)).toList();

        transactions.add(TransactionModel.fromMap(map, items: items));
      }

      return transactions;
    } catch (e) {
      return [];
    }
  }

  // --- 4. MENGHAPUS TRANSAKSI ---
  Future<void> deleteTransaction(dynamic id) async {
    final db = await database;

    await db.transaction((txn) async {
      final List<Map<String, dynamic>> oldItemsMap = await txn.query(
        'transaction_items',
        where: 'transaction_id = ?',
        whereArgs: [id.toString()],
      );

      for (var oldMap in oldItemsMap) {
        final int oldProductId = oldMap['product_id'];
        final int oldQuantity = oldMap['quantity'];

        await txn.rawUpdate(
          'UPDATE products SET stock = stock + ? WHERE id = ?',
          [oldQuantity, oldProductId],
        );
      }

      await txn.delete(
        'transaction_items',
        where: 'transaction_id = ?',
        whereArgs: [id.toString()],
      );
      await txn.delete(
        'transactions',
        where: 'id = ?',
        whereArgs: [id.toString()],
      );
    });
  }

  // --- 5. MANAJEMEN PENGELUARAN (EXPENSES) ---
  Future<int> createExpense(String title, double amount) async {
    final db = await database;
    return await db.insert('expenses', {
      'title': title,
      'amount': amount,
      'expense_date': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getExpenses() async {
    try {
      final db = await database;
      return await db.query('expenses', orderBy: 'expense_date DESC');
    } catch (e) {
      return [];
    }
  }

  Future<void> deleteExpense(int id) async {
    final db = await database;
    await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }
}
