import '../../core/database/database_helper.dart';
import '../models/product_model.dart';

class ProductRepository {
  final dbHelper = DatabaseHelper.instance;

  Future<int> insertProduct(ProductModel product) async {
    final db = await dbHelper.database;
    return await db.insert('products', product.toMap());
  }

  Future<List<ProductModel>> getProducts({String? searchQuery}) async {
    final db = await dbHelper.database;
    List<Map<String, dynamic>> maps;

    if (searchQuery != null && searchQuery.isNotEmpty) {
      maps = await db.query(
        'products',
        where: 'name LIKE ?',
        whereArgs: ['%$searchQuery%'],
        orderBy: 'name ASC',
      );
    } else {
      maps = await db.query('products', orderBy: 'name ASC');
    }

    return maps.map((map) => ProductModel.fromMap(map)).toList();
  }

  Future<int> updateProduct(ProductModel product) async {
    final db = await dbHelper.database;
    return await db.update(
      'products',
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  Future<int> deleteProduct(int id) async {
    final db = await dbHelper.database;
    return await db.delete(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
