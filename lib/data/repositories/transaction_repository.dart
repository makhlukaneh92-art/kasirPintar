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
    int generatedId = 0;

    // Gunakan db.transaction agar operasi simpan & potong stok bersifat atomik (aman)
    await db.transaction((txn) async {
      // 1. Simpan header transaksi utama
      generatedId = await txn.insert(
        'transactions',
        transaction.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      final String actualTrxId = transaction.id ?? generatedId.toString();

      // 2. Hapus item lama jika ini merupakan update transaksi
      await txn.delete(
        'transaction_items',
        where: 'transaction_id = ?',
        whereArgs: [actualTrxId],
      );

      // 3. Simpan item transaksi & potong stok produk secara otomatis
      for (var item in transaction.items) {
        var itemMap = item.toMap();
        itemMap['transaction_id'] = actualTrxId;
        await txn.insert('transaction_items', itemMap);

        // Potong stok produk di database
        await txn.rawUpdate(
          'UPDATE products SET stock = stock - ? WHERE id = ?',
          [item.quantity, item.productId],
        );
      }
    });

    return generatedId;
  }

  Future<List<TransactionModel>> getTransactions() async {
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
        whereArgs: [map['id']],
      );

      List<TransactionItemModel> items =
          itemMaps.map((i) => TransactionItemModel.fromMap(i)).toList();

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
