import '../../core/database/database_helper.dart';
import '../models/transaction_model.dart';

class TransactionRepository {
  final dbHelper = DatabaseHelper.instance;

  // Simpan Transaksi Penjualan & Kurangi Stok Otomatis
  Future<void> createTransaction(TransactionModel transaction) async {
    final db = await dbHelper.database;

    await db.transaction((txn) async {
      // 1. Insert Header Transaksi
      await txn.insert('transactions', transaction.toMap());

      // 2. Insert Detail Item & Update Stok Produk
      for (var item in transaction.items) {
        await txn.insert('transaction_items', item.toMap());

        // Kurangi stok produk
        await txn.rawUpdate(
          'UPDATE products SET stock = stock - ? WHERE id = ?',
          [item.quantity, item.productId],
        );
      }
    });
  }

  // Ambil Riwayat Transaksi
  Future<List<TransactionModel>> getTransactions() async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT t.*, c.name as customer_name 
      FROM transactions t
      LEFT JOIN customers c ON t.customer_id = c.id
      ORDER BY t.transaction_date DESC
    ''');

    List<TransactionModel> result = [];
    for (var map in maps) {
      final items = await _getTransactionItems(map['id'] as String);
      result.add(TransactionModel.fromMap(
        map,
        items: items,
        customerName: map['customer_name'] as String?,
      ));
    }
    return result;
  }

  Future<List<TransactionItemModel>> _getTransactionItems(String transactionId) async {
    final db = await dbHelper.database;
    final maps = await db.query(
      'transaction_items',
      where: 'transaction_id = ?',
      whereArgs: [transactionId],
    );
    return maps.map((map) => TransactionItemModel.fromMap(map)).toList();
      Future<void> deleteTransaction(dynamic id) async {
    final db = await DatabaseHelper.instance.database;
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
