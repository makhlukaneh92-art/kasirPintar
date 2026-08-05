class TransactionItemModel {
  final int? id;
  final String transactionId;
  final int productId;
  final String productName;
  final double buyPrice;
  final double sellPrice;
  final int quantity;
  final double subtotal;

  TransactionItemModel({
    this.id,
    required this.transactionId,
    required this.productId,
    required this.productName,
    required this.buyPrice,
    required this.sellPrice,
    required this.quantity,
    required this.subtotal,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'transaction_id': transactionId,
      'product_id': productId,
      'product_name': productName,
      'buy_price': buyPrice,
      'sell_price': sellPrice,
      'quantity': quantity,
      'subtotal': subtotal,
    };
  }

  factory TransactionItemModel.fromMap(Map<String, dynamic> map) {
    return TransactionItemModel(
      id: map['id'] as int?,
      transactionId: map['transaction_id'] as String,
      productId: map['product_id'] as int,
      productName: map['product_name'] as String,
      buyPrice: (map['buy_price'] as num).toDouble(),
      sellPrice: (map['sell_price'] as num).toDouble(),
      quantity: map['quantity'] as int,
      subtotal: (map['subtotal'] as num).toDouble(),
    );
  }
}

class TransactionModel {
  final String id;
  final int? customerId;
  final String? customerName;
  final String paymentStatus; // 'LUNAS', 'KREDIT', 'BELUM_LUNAS'
  final double subtotal;
  final String? discountType; // 'NOMINAL', 'PERCENT'
  final double discountValue;
  final double totalAmount;
  final String transactionDate;
  final List<TransactionItemModel> items;

  TransactionModel({
    required this.id,
    this.customerId,
    this.customerName,
    required this.paymentStatus,
    required this.subtotal,
    this.discountType,
    this.discountValue = 0,
    required this.totalAmount,
    required this.transactionDate,
    required this.items,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customer_id': customerId,
      'payment_status': paymentStatus,
      'subtotal': subtotal,
      'discount_type': discountType,
      'discount_value': discountValue,
      'total_amount': totalAmount,
      'transaction_date': transactionDate,
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map, {List<TransactionItemModel> items = const [], String? customerName}) {
    return TransactionModel(
      id: map['id'] as String,
      customerId: map['customer_id'] as int?,
      customerName: customerName,
      paymentStatus: map['payment_status'] as String,
      subtotal: (map['subtotal'] as num).toDouble(),
      discountType: map['discount_type'] as String?,
      discountValue: (map['discount_value'] as num?)?.toDouble() ?? 0,
      totalAmount: (map['total_amount'] as num).toDouble(),
      transactionDate: map['transaction_date'] as String,
      items: items,
    );
  }
}
