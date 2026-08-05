import '../../core/database/database_helper.dart';
import '../models/customer_model.dart';

class CustomerRepository {
  final dbHelper = DatabaseHelper.instance;

  // 1. Tambah Pelanggan
  Future<int> insertCustomer(CustomerModel customer) async {
    final db = await dbHelper.database;
    return await db.insert('customers', customer.toMap());
  }

  // 2. Ambil Semua Pelanggan atau Cari Berdasarkan Nama/Telepon
  Future<List<CustomerModel>> getCustomers({String? searchQuery}) async {
    final db = await dbHelper.database;
    List<Map<String, dynamic>> maps;

    if (searchQuery != null && searchQuery.isNotEmpty) {
      maps = await db.query(
        'customers',
        where: 'name LIKE ? OR phone LIKE ?',
        whereArgs: ['%$searchQuery%', '%$searchQuery%'],
        orderBy: 'name ASC',
      );
    } else {
      maps = await db.query('customers', orderBy: 'name ASC');
    }

    return maps.map((map) => CustomerModel.fromMap(map)).toList();
  }

  // 3. Update Pelanggan
  Future<int> updateCustomer(CustomerModel customer) async {
    final db = await dbHelper.database;
    return await db.update(
      'customers',
      customer.toMap(),
      where: 'id = ?',
      whereArgs: [customer.id],
    );
  }

  // 4. Hapus Pelanggan
  Future<int> deleteCustomer(int id) async {
    final db = await dbHelper.database;
    return await db.delete(
      'customers',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
