import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('kasir_pintar.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // 1. Tabel Produk
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        buy_price REAL NOT NULL,
        sell_price REAL NOT NULL,
        stock INTEGER DEFAULT 0,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // 2. Tabel Pelanggan
    await db.execute('''
      CREATE TABLE customers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // 3. Tabel Transaksi (Header)
    await db.execute('''
      CREATE TABLE transactions (
        id TEXT PRIMARY KEY,
        customer_id INTEGER,
        payment_status TEXT NOT NULL,
        subtotal REAL NOT NULL,
        discount_type TEXT,
        discount_value REAL DEFAULT 0,
        total_amount REAL NOT NULL,
        transaction_date DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (customer_id) REFERENCES customers (id)
      )
    ''');

    // 4. Tabel Detail Item Transaksi
    await db.execute('''
      CREATE TABLE transaction_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        transaction_id TEXT NOT NULL,
        product_id INTEGER NOT NULL,
        product_name TEXT NOT NULL,
        buy_price REAL NOT NULL,
        sell_price REAL NOT NULL,
        quantity INTEGER NOT NULL,
        subtotal REAL NOT NULL,
        FOREIGN KEY (transaction_id) REFERENCES transactions (id) ON DELETE CASCADE,
        FOREIGN KEY (product_id) REFERENCES products (id)
      )
    ''');
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
