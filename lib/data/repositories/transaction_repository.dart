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
    return await openDatabase(path, version: 1);
  }

  Future<int> createTransaction(TransactionModel transaction) async {
    final db = await database;
    
    // Simpan transaksi utama
    int id = await db.insert('transactions', transaction.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);

    // Hapus item lama jika ini proses update
    await db.delete(
      'transaction_items',
      where: 'transaction_id = ?',
      whereArgs: [transaction.id ?? id],
    );

    // Simpan item transaksi
    for (var item in transaction.items) {
      var itemMap = item.toMap();
      itemMap['transaction_id'] = transaction.id ?? id;
      await db.insert('transaction_items', itemMap);
    }

    return id;
  }

  Future<List<TransactionModel>> getTransactions() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('transactions', orderBy: 'transaction_date DESC');

    List<TransactionModel> transactions = [];

    for (var map in maps) {
      final List<Map<String, dynamic>> itemMaps = await db.query(
        'transaction_items',
        where: 'transaction_id = ?',
        whereArgs: [map['id']],
      );

      List<TransactionItemModel> items = itemMaps.map((i) => TransactionItemModel.fromMap(i)).toList();

      transactions.add(TransactionModel.fromMap(map, items: items));
    }

    return transactions;
  }

  Future<void> deleteTransaction(dynamic id) async {
    final db = await database;
    await db.delete(
      'transaction_items',
      where: 'transaction_id = ?',
      whereArgs: [id],
    );
    await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
