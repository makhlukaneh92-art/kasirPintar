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

  // --- 1. MEMBUAT TRANSAKSI BARU ---
  Future<int> createTransaction(TransactionModel transaction) async {
    final db = await database;
    int generatedId = 0;

    await db.transaction((txn) async {
      // Simpan header transaksi
      generatedId = await txn.insert(
        'transactions',
        transaction.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      final String actualTrxId = transaction.id?.toString() ?? generatedId.toString();

      // Hapus item transaksi lama (jika ada)
      await txn.delete(
        'transaction_items',
        where: 'transaction_id = ?',
        whereArgs: [actualTrxId],
      );

      // Simpan item transaksi baru & potong stok produk
      for (var item in transaction.items) {
        var itemMap = item.toMap();
        itemMap['transaction_id'] = actualTrxId;
        await txn.insert('transaction_items', itemMap);

        // Potong stok produk
        await txn.rawUpdate(
          'UPDATE products SET stock = stock - ? WHERE id = ?',
          [item.quantity, item.productId],
        );
      }
    });

    return generatedId;
  }

  // --- 2. MEMPERBARUI (EDIT) TRANSAKSI SECARA AMAN ---
  Future<void> updateTransaction(TransactionModel transaction) async {
    final db = await database;
    final String trxId = transaction.id.toString();

    await db.transaction((txn) async {
      // A. Ambil item transaksi lama untuk mengembalikan stok barang ke semula
      final List<Map<String, dynamic>> oldItemsMap = await txn.query(
        'transaction_items',
        where: 'transaction_id = ?',
        whereArgs: [trxId],
      );

      for (var oldMap in oldItemsMap) {
        final int oldProductId = oldMap['product_id'];
        final int oldQuantity = oldMap['quantity'];

        // Kembalikan stok produk (ditambah kembali)
        await txn.rawUpdate(
          'UPDATE products SET stock = stock + ? WHERE id = ?',
          [oldQuantity, oldProductId],
        );
      }

      // B. Update data utama transaksi
      await txn.update(
        'transactions',
        transaction.toMap(),
        where: 'id = ?',
        whereArgs: [trxId],
      );

      // C. Hapus item transaksi lama
      await txn.delete(
        'transaction_items',
        where: 'transaction_id = ?',
        whereArgs: [trxId],
      );

      // D. Simpan item transaksi baru & potong stok produk sesuai kuantitas baru
      for (var item in transaction.items) {
        var itemMap = item.toMap();
        itemMap['transaction_id'] = trxId;
        await txn.insert('transaction_items', itemMap);

        // Potong stok produk baru
        await txn.rawUpdate(
          'UPDATE products SET stock = stock - ? WHERE id = ?',
          [item.quantity, item.productId],
        );
      }
    });
  }

  // --- 3. MENGAMBIL DAFTAR TRANSAKSI ---
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

  // --- 4. MENGHAPUS TRANSAKSI & MENGEMBALIKAN STOK ---
  Future<void> deleteTransaction(dynamic id) async {
    final db = await database;

    await db.transaction((txn) async {
      // Ambil item transaksi untuk mengembalikan stok sebelum dihapus
      final List<Map<String, dynamic>> oldItemsMap = await txn.query(
        'transaction_items',
        where: 'transaction_id = ?',
        whereArgs: [id],
      );

      for (var oldMap in oldItemsMap) {
        final int oldProductId = oldMap['product_id'];
        final int oldQuantity = oldMap['quantity'];

        // Kembalikan stok produk
        await txn.rawUpdate(
          'UPDATE products SET stock = stock + ? WHERE id = ?',
          [oldQuantity, oldProductId],
        );
      }

      // Hapus data dari tabel
      await txn.delete(
        'transaction_items',
        where: 'transaction_id = ?',
        whereArgs: [id],
      );
      await txn.delete(
        'transactions',
        where: 'id = ?',
        whereArgs: [id],
      );
    });
  }
}
