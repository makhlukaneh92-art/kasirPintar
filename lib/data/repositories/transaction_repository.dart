import '../models/transaction_model.dart';
// Mencoba mengimpor DatabaseHelper dari lokasi-lokasi yang umum di project Anda
import '../helpers/database_helper.dart';

class TransactionRepository {
  Future<dynamic> _getDb() async {
    return await DatabaseHelper.instance.database;
  }

  Future<int> createTransaction(TransactionModel transaction) async {
    final db = await _getDb();
    
    // Simpan transaksi utama
    int id = await db.insert('transactions', transaction.toMap());

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
    final db = await _getDb();
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
    final db = await _getDb();
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
