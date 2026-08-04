import 'dart:convert';

class Product {
  String id;
  String name;
  double sellPrice;
  double costPrice;
  int stock;

  Product({
    required this.id,
    required this.name,
    required this.sellPrice,
    required this.costPrice,
    required this.stock,
  });

  // Getter & Setter Tambahan untuk Kompatibilitas dengan Kode Lain
  double get sellingPrice => sellPrice;
  set sellingPrice(double val) => sellPrice = val;

  double get modalPrice => costPrice;
  set modalPrice(double val) => costPrice = val;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'sellPrice': sellPrice,
      'costPrice': costPrice,
      'stock': stock,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      sellPrice: (map['sellPrice'] ?? map['sellingPrice'] ?? 0).toDouble(),
      costPrice: (map['costPrice'] ?? map['modalPrice'] ?? 0).toDouble(),
      stock: map['stock'] ?? 0,
    );
  }

  String toJson() => json.encode(toMap());
  factory Product.fromJson(String source) => Product.fromMap(json.decode(source));
}

class StoreInfo {
  String name;
  String address;
  String phone;
  String footer;

  StoreInfo({
    required this.name,
    required this.address,
    required this.phone,
    required this.footer,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'address': address,
      'phone': phone,
      'footer': footer,
    };
  }

  factory StoreInfo.fromMap(Map<String, dynamic> map) {
    return StoreInfo(
      name: map['name'] ?? '',
      address: map['address'] ?? '',
      phone: map['phone'] ?? '',
      footer: map['footer'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());
  factory StoreInfo.fromJson(String source) => StoreInfo.fromMap(json.decode(source));
}

class CartItem {
  Product product;
  int quantity;

  CartItem({
    required this.product,
    required this.quantity,
  });

  double get totalPrice => product.sellPrice * quantity;
  double get totalCost => product.costPrice * quantity;

  Map<String, dynamic> toMap() {
    return {
      'product': product.toMap(),
      'quantity': quantity,
    };
  }

  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      product: Product.fromMap(map['product']),
      quantity: map['quantity'] ?? 1,
    );
  }
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

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'address': address,
    };
  }

  factory CustomerInfo.fromMap(Map<String, dynamic> map) {
    return CustomerInfo(
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      address: map['address'] ?? '',
    );
  }
}

class SalesTransaction {
  String id;
  DateTime dateTime;
  CustomerInfo customer;
  List<CartItem> items;
  double discount;
  double cashPaid;
  bool isPaid;

  SalesTransaction({
    required this.id,
    required this.dateTime,
    required this.customer,
    required this.items,
    this.discount = 0.0,
    this.cashPaid = 0.0,
    this.isPaid = true,
  });

  double get subtotal => items.fold(0, (sum, item) => sum + item.totalPrice);
  double get totalCost => items.fold(0, (sum, item) => sum + item.totalCost);
  double get grandTotal {
    final total = subtotal - discount;
    return total < 0 ? 0 : total;
  }
  double get change => cashPaid >= grandTotal ? cashPaid - grandTotal : 0;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'dateTime': dateTime.toIso8601String(),
      'customer': customer.toMap(),
      'items': items.map((x) => x.toMap()).toList(),
      'discount': discount,
      'cashPaid': cashPaid,
      'isPaid': isPaid,
    };
  }

  factory SalesTransaction.fromMap(Map<String, dynamic> map) {
    return SalesTransaction(
      id: map['id'] ?? '',
      dateTime: DateTime.tryParse(map['dateTime'] ?? '') ?? DateTime.now(),
      customer: CustomerInfo.fromMap(map['customer'] ?? {}),
      items: List<CartItem>.from((map['items'] ?? []).map((x) => CartItem.fromMap(x))),
      discount: (map['discount'] ?? 0).toDouble(),
      cashPaid: (map['cashPaid'] ?? 0).toDouble(),
      isPaid: map['isPaid'] ?? true,
    );
  }
}

class CashEntry {
  String id;
  DateTime date;
  String description;
  double amount;

  CashEntry({
    required this.id,
    required this.date,
    required this.description,
    required this.amount,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'description': description,
      'amount': amount,
    };
  }

  factory CashEntry.fromMap(Map<String, dynamic> map) {
    return CashEntry(
      id: map['id'] ?? '',
      date: DateTime.tryParse(map['date'] ?? '') ?? DateTime.now(),
      description: map['description'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
    );
  }
}
