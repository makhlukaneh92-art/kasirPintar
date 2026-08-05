import 'package:flutter/material.dart';
import '../../data/models/product_model.dart';
import '../../data/models/customer_model.dart';
import '../../data/models/transaction_model.dart';
import '../../data/repositories/product_repository.dart';
import '../../data/repositories/customer_repository.dart';
import '../../data/repositories/transaction_repository.dart';

class CashierScreen extends StatefulWidget {
  const CashierScreen({super.key});

  @override
  State<CashierScreen> createState() => _CashierScreenState();
}

class _CashierScreenState extends State<CashierScreen> {
  final ProductRepository _productRepo = ProductRepository();
  final CustomerRepository _customerRepo = CustomerRepository();
  final TransactionRepository _transactionRepo = TransactionRepository();

  List<ProductModel> _products = [];
  List<CustomerModel> _customers = [];
  
  final Map<int, int> _cart = {}; // productId -> quantity
  CustomerModel? _selectedCustomer;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    final products = await _productRepo.getProducts();
    final customers = await _customerRepo.getCustomers();
    setState(() {
      _products = products;
      _customers = customers;
      _isLoading = false;
    });
  }

  void _addToCart(ProductModel product) {
    if (product.id == null || product.stock <= 0) return;
    setState(() {
      int currentQty = _cart[product.id!] ?? 0;
      if (currentQty < product.stock) {
        _cart[product.id!] = currentQty + 1;
      }
    });
  }

  void _removeFromCart(int productId) {
    setState(() {
      if (_cart.containsKey(productId)) {
        if (_cart[productId]! > 1) {
          _cart[productId] = _cart[productId]! - 1;
        } else {
          _cart.remove(productId);
        }
      }
    });
  }

  double get _totalAmount {
    double total = 0;
    _cart.forEach((productId, qty) {
      final product = _products.firstWhere((p) => p.id == productId);
      total += product.sellPrice * qty;
    });
    return total;
  }

  Future<void> _checkout() async {
    if (_cart.isEmpty) return;

    final transactionId = 'TRX-${DateTime.now().millisecondsSinceEpoch}';
    List<TransactionItemModel> items = [];

    _cart.forEach((productId, qty) {
      final product = _products.firstWhere((p) => p.id == productId);
      items.add(TransactionItemModel(
        transactionId: transactionId,
        productId: product.id!,
        productName: product.name,
        buyPrice: product.buyPrice,
        sellPrice: product.sellPrice,
        quantity: qty,
        subtotal: product.sellPrice * qty,
      ));
    });

    final transaction = TransactionModel(
      id: transactionId,
      customerId: _selectedCustomer?.id,
      paymentStatus: 'LUNAS',
      subtotal: _totalAmount,
      totalAmount: _totalAmount,
      transactionDate: DateTime.now().toIso8601String(),
      items: items,
    );

    await _transactionRepo.createTransaction(transaction);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaksi Berhasil Disimpan!')),
      );
      setState(() => _cart.clear());
      _loadInitialData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaksi Penjualan'),
        backgroundColor: const Color(0xFF00796B),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Pilih Pelanggan
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: DropdownButtonFormField<CustomerModel>(
                    decoration: const InputDecoration(
                      labelText: 'Pilih Pelanggan (Opsional)',
                      border: OutlineInputBorder(),
                    ),
                    value: _selectedCustomer,
                    items: _customers.map((c) {
                      return DropdownMenuItem(value: c, child: Text(c.name));
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedCustomer = val),
                  ),
                ),

                // List Produk
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(8),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 1.2,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: _products.length,
                    itemBuilder: (context, index) {
                      final product = _products[index];
                      final qtyInCart = _cart[product.id] ?? 0;

                      return Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                              Text('Rp ${product.sellPrice.toStringAsFixed(0)}'),
                              Text('Stok: ${product.stock}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                              const Spacer(),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  if (qtyInCart > 0)
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle, color: Colors.red),
                                      onPressed: () => _removeFromCart(product.id!),
                                    ),
                                  if (qtyInCart > 0) Text('$qtyInCart'),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle, color: Color(0xFF00796B)),
                                    onPressed: () => _addToCart(product),
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Panel Total & Bayar
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Total Pembayaran', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          Text(
                            'Rp ${_totalAmount.toStringAsFixed(0)}',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF00796B)),
                          ),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: _cart.isNotEmpty ? _checkout : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00796B),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('PROSES BAYAR'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
