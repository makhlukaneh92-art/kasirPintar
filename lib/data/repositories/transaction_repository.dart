import 'package:sqflite/sqflite.dart';
import '../models/transaction_model.dart';
import '../../core/database/database_helper.dart';

class TransactionRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Insert Transaksi Baru beserta Items & Potong Stok
  Future<void> createTransaction(TransactionModel transaction) async {
    final db = await _dbHelper.database;

    await db.transaction((txn) async {
      // 1. Insert header transaksi
      await txn.insert(
        'transactions',
        transaction.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // 2. Insert detail barang & kurangi stok
      for (var item in transaction.items) {
        await txn.insert(
          'transaction_items',
          item.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        // Potong stok produk
        await txn.rawUpdate(
          'UPDATE products SET stock = stock - ? WHERE id = ?',
          [item.quantity, item.productId],
        );
      }
    });
  }

  // Update Transaksi / Edit Struk (Misal Mengubah Pelanggan / Status Bayar / Diskon / Total)
  Future<void> updateTransaction(TransactionModel transaction) async {
    final db = await _dbHelper.database;
    await db.update(
      'transactions',
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  // Hapus Transaksi & Kembalikan Stok
  Future<void> deleteTransaction(String transactionId) async {
    final db = await _dbHelper.database;

    await db.transaction((txn) async {
      // Ambil barang-barang dalam transaksi untuk mengembalikan stok
      final itemsMap = await txn.query(
        'transaction_items',
        where: 'transaction_id = ?',
        whereArgs: [transactionId],
      );

      for (var map in itemsMap) {
        final productId = map['product_id'] as int;
        final qty = map['quantity'] as int;

        // Kembalikan stok
        await txn.rawUpdate(
          'UPDATE products SET stock = stock + ? WHERE id = ?',
          [qty, productId],
        );
      }

      // Hapus item dan header
      await txn.delete('transaction_items', where: 'transaction_id = ?', whereArgs: [transactionId]);
      await txn.delete('transactions', where: 'id = ?', whereArgs: [transactionId]);
    });
  }

  // Ambil Semua Transaksi Lengkap
  Future<List<TransactionModel>> getAllTransactions() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT t.*, c.name as customer_name, c.phone as customer_phone
      FROM transactions t
      LEFT JOIN customers c ON t.customer_id = c.id
      ORDER BY t.transaction_date DESC
    ''');

    List<TransactionModel> transactions = [];
    for (var map in maps) {
      final itemsMap = await db.query(
        'transaction_items',
        where: 'transaction_id = ?',
        whereArgs: [map['id']],
      );

      final items = itemsMap.map((i) => TransactionItemModel.fromMap(i)).toList();
      transactions.add(TransactionModel.fromMap(map, items: items));
    }

    return transactions;
  }
}
