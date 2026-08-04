import 'dart:io';

class StoreInfo {
  String name;
  String address;
  String phone;
  String footer;
  File? logoFile;

  StoreInfo({
    required this.name,
    required this.address,
    required this.phone,
    required this.footer,
    this.logoFile,
  });
}

class Product {
  String id;
  String name;
  double sellingPrice;
  double modalPrice;
  int stock;

  Product({
    required this.id,
    required this.name,
    required this.sellingPrice,
    required this.modalPrice,
    required this.stock,
  });
}

class CartItem {
  final Product product;
  int quantity;

  CartItem({required this.product, required this.quantity});

  double get subtotal => product.sellingPrice * quantity;
  double get totalModal => product.modalPrice * quantity;

  CartItem copy() => CartItem(product: product, quantity: quantity);
}

class SalesTransaction {
  String id;
  DateTime date;
  List<CartItem> items;
  double totalAmount;
  double totalModal;
  String? customerName;
  String? customerPhone;
  String? customerAddress;

  SalesTransaction({
    required this.id,
    required this.date,
    required this.items,
    required this.totalAmount,
    required this.totalModal,
    this.customerName,
    this.customerPhone,
    this.customerAddress,
  });
}

class CashEntry {
  String id;
  String title;
  double amount;
  bool isIncome;
  DateTime date;

  CashEntry({
    required this.id,
    required this.title,
    required this.amount,
    required this.isIncome,
    required this.date,
  });
}
