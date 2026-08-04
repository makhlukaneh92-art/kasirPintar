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
  double costPrice; // Harga Modal
  double sellPrice; // Harga Jual
  int stock;

  Product({
    required this.id,
    required this.name,
    required this.costPrice,
    required this.sellPrice,
    required this.stock,
  });
}

class CartItem {
  final Product product;
  int quantity;

  CartItem({
    required this.product,
    this.quantity = 1,
  });

  double get totalPrice => product.sellPrice * quantity;
  double get totalCost => product.costPrice * quantity;
}

class CustomerInfo {
  String name;
  String phone;
  String address;

  CustomerInfo({
    this.name = '',
    this.phone = '',
    this.address = '',
  });
}

class SalesTransaction {
  final String id;
  final DateTime dateTime; // Tanggal & Jam Transaksi
  final CustomerInfo customer;
  final List<CartItem> items;
  final double discount; // Diskon (Nominal)
  final double cashPaid; // Uang Dibayar
  final bool isPaid; // Status: true = LUNAS, false = BELUM LUNAS (Kasbon)

  SalesTransaction({
    required this.id,
    required this.dateTime,
    required this.customer,
    required this.items,
    this.discount = 0.0,
    required this.cashPaid,
    this.isPaid = true,
  });

  // Total Kotor Sebelum Diskon
  double get subtotal => items.fold(0, (sum, item) => sum + item.totalPrice);

  // Total Modal (HPP)
  double get totalCost => items.fold(0, (sum, item) => sum + item.totalCost);

  // Total Akhir Setelah Diskon
  double get grandTotal => (subtotal - discount) < 0 ? 0 : (subtotal - discount);

  // Kembalian
  double get change => cashPaid >= grandTotal ? cashPaid - grandTotal : 0;
}

class CashEntry {
  final String id;
  final DateTime date;
  final String description;
  final double amount; // Positif (Pemasukan) atau Negatif (Pengeluaran)

  CashEntry({
    required this.id,
    required this.date,
    required this.description,
    required this.amount,
  });
}
