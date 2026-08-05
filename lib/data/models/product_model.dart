class ProductModel {
  final int? id;
  final String name;
  final double buyPrice;
  final double sellPrice;
  final int stock;

  ProductModel({
    this.id,
    required this.name,
    required this.buyPrice,
    required this.sellPrice,
    required this.stock,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'buy_price': buyPrice,
      'sell_price': sellPrice,
      'stock': stock,
    };
  }

  factory ProductModel.fromMap(Map<String, dynamic> map) {
    return ProductModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      buyPrice: (map['buy_price'] as num).toDouble(),
      sellPrice: (map['sell_price'] as num).toDouble(),
      stock: map['stock'] as int,
    );
  }
}
