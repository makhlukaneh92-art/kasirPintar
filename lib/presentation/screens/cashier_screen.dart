import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  List<ProductModel> _allProducts = [];
  List<ProductModel> _filteredProducts = [];
  List<CustomerModel> _allCustomers = [];

  final Map<int, int> _cart = {}; // productId -> quantity
  CustomerModel? _selectedCustomer;
  bool _isLoading = true;

  final TextEditingController _searchProductController = TextEditingController();
  final TextEditingController _discountController = TextEditingController(text: '0');
  
  String _paymentStatus = 'LUNAS'; // LUNAS, KREDIT, BELUM LUNAS

  String _storeName = 'TOKO KASIR PINTAR';
  String _storeAddress = '';
  String _storePhone = '';
  String _storeFooter = '';
  String? _storeLogo;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    final products = await _productRepo.getProducts();
    final customers = await _customerRepo.getCustomers();
    
    final prefs = await SharedPreferences.getInstance();
    _storeName = prefs.getString('store_name') ?? 'TOKO KASIR PINTAR';
    _storeAddress = prefs.getString('store_address') ?? '';
    _storePhone = prefs.getString('store_phone') ?? '';
    _storeFooter = prefs.getString('store_footer') ?? 'Terima Kasih';
    _storeLogo = prefs.getString('store_logo');

    setState(() {
      _allProducts = products;
      _filteredProducts = products;
      _allCustomers = customers;
      _isLoading = false;
    });
  }

  void _filterProducts(String query) {
    setState(() {
      _filteredProducts = _allProducts
          .where((p) => p.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
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

  void _updateQuantityManual(ProductModel product, int newQty) {
    if (product.id == null) return;
    setState(() {
      if (newQty <= 0) {
        _cart.remove(product.id!);
      } else if (newQty <= product.stock) {
        _cart[product.id!] = newQty;
      } else {
        _cart[product.id!] = product.stock;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Jumlah melebihi stok yang tersedia (${product.stock})')),
        );
      }
    });
  }

  void _removeFromCart(int productId) {
    setState(() {
      _cart.remove(productId);
    });
  }

  double get _subtotalAmount {
    double total = 0;
    _cart.forEach((productId, qty) {
      final product = _allProducts.firstWhere((p) => p.id == productId);
      total += product.sellPrice * qty;
    });
    return total;
  }

  double get _discountAmount {
    return double.tryParse(_discountController.text) ?? 0;
  }

  double get _finalTotalAmount {
    double total = _subtotalAmount - _discountAmount;
    return total < 0 ? 0 : total;
  }

  String _formatRupiah(double amount) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(amount);
  }

  void _showEditCartDialog(ProductModel product) {
    final qtyController = TextEditingController(text: '${_cart[product.id!] ?? 1}');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Jumlah - ${product.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: qtyController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Jumlah Barang', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _removeFromCart(product.id!);
              Navigator.pop(context);
            },
            child: const Text('HAPUS ITEM', style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () {
              int inputQty = int.tryParse(qtyController.text) ?? 1;
              _updateQuantityManual(product, inputQty);
              Navigator.pop(context);
            },
            child: const Text('SIMPAN'),
          ),
        ],
      ),
    );
  }

  void _showReceiptPreviewDialog() {
    final now = DateTime.now();
    final dateStr = DateFormat('dd MMM yyyy, HH:mm').format(now);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        contentPadding: const EdgeInsets.all(16),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_storeLogo != null && File(_storeLogo!).existsSync())
                Image.file(File(_storeLogo!), height: 60, fit: BoxFit.contain)
              else
                const Icon(Icons.store, size: 50, color: Color(0xFF00796B)),
              const SizedBox(height: 8),

              Text(_storeName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              if (_storeAddress.isNotEmpty) Text(_storeAddress, style: const TextStyle(fontSize: 11)),
              if (_storePhone.isNotEmpty) Text('Telp: $_storePhone', style: const TextStyle(fontSize: 11)),
              const Divider(thickness: 1),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Tgl: $dateStr', style: const TextStyle(fontSize: 10)),
                  Text('Status: $_paymentStatus', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                ],
              ),
              Row(
                children: [
                  Text('Pelanggan: ${_selectedCustomer?.name ?? "Umum"}', style: const TextStyle(fontSize: 11)),
                ],
              ),
              const Divider(),

              ..._cart.entries.map((entry) {
                final product = _allProducts.firstWhere((p) => p.id == entry.key);
                final qty = entry.value;
                final itemTotal = product.sellPrice * qty;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: Row(
                    children: [
                      Expanded(child: Text(product.name, style: const TextStyle(fontSize: 12))),
                      Text('${qty}x ', style: const TextStyle(fontSize: 12)),
                      Text(_formatRupiah(itemTotal), style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                );
              }),

              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Subtotal:'),
                  Text(_formatRupiah(_subtotalAmount)),
                ],
              ),
              if (_discountAmount > 0)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Diskon:'),
                    Text('- ${_formatRupiah(_discountAmount)}', style: const TextStyle(color: Colors.red)),
                  ],
                ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('TOTAL:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  Text(_formatRupiah(_finalTotalAmount), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF00796B))),
                ],
              ),
              const Divider(),
              Text(_storeFooter, style: const TextStyle(fontSize: 10, fontStyle: FontStyle.italic)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('BATAL'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _processCheckout(shouldPrint: false);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[700], foregroundColor: Colors.white),
            child: const Text('SIMPAN (TANPA CETAK)'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _processCheckout(shouldPrint: true);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00796B), foregroundColor: Colors.white),
            child: const Text('SIMPAN & CETAK STRUK'),
          ),
        ],
      ),
    );
  }

  Future<void> _processCheckout({required bool shouldPrint}) async {
    final transactionId = 'TRX-${DateTime.now().millisecondsSinceEpoch}';
    List<TransactionItemModel> items = [];

    _cart.forEach((productId, qty) {
      final product = _allProducts.firstWhere((p) => p.id == productId);
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
      paymentStatus: _paymentStatus,
      subtotal: _subtotalAmount,
      totalAmount: _finalTotalAmount,
      transactionDate: DateTime.now().toIso8601String(),
      items: items,
    );

    await _transactionRepo.createTransaction(transaction);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(shouldPrint 
            ? 'Transaksi Berhasil Disimpan & Struk Siap Dicetak!' 
            : 'Transaksi Berhasil Disimpan!'),
          backgroundColor: Colors.green,
        ),
      );
      setState(() {
        _cart.clear();
        _discountController.text = '0';
        _selectedCustomer = null;
      });
      _loadInitialData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Kasir - $_storeName'),
        backgroundColor: const Color(0xFF00796B),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: DropdownButtonFormField<CustomerModel>(
                    decoration: const InputDecoration(
                      labelText: 'Pilih Pelanggan (Opsional)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                      isDense: true,
                    ),
                    value: _selectedCustomer,
                    items: _allCustomers.map((c) {
                      return DropdownMenuItem(value: c, child: Text('${c.name} (${c.phone})'));
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedCustomer = val),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: TextField(
                    controller: _searchProductController,
                    onChanged: _filterProducts,
                    decoration: const InputDecoration(
                      hintText: 'Cari Nama Produk...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  flex: 3,
                  child: GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0), // FIX: EdgeInsets.symmetric
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 1.4,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: _filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = _filteredProducts[index];
                      final qtyInCart = _cart[product.id] ?? 0;

                      return Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                              Text(_formatRupiah(product.sellPrice), style: const TextStyle(color: Color(0xFF00796B), fontWeight: FontWeight.bold, fontSize: 12)),
                              Text('Stok: ${product.stock}', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                              const Spacer(),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  if (qtyInCart > 0)
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle, color: Colors.red, size: 22),
                                      onPressed: () => _updateQuantityManual(product, qtyInCart - 1),
                                    ),
                                  if (qtyInCart > 0)
                                    GestureDetector(
                                      onTap: () => _showEditCartDialog(product),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(4)),
                                        child: Text('$qtyInCart', style: const TextStyle(fontWeight: FontWeight.bold)),
                                      ),
                                    ),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle, color: Color(0xFF00796B), size: 22),
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
                const Divider(thickness: 2),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _discountController,
                          keyboardType: TextInputType.number,
                          onChanged: (val) => setState(() {}),
                          decoration: const InputDecoration(
                            labelText: 'Diskon (Rp)',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _paymentStatus,
                          decoration: const InputDecoration(
                            labelText: 'Status Bayar',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          items: const [
                            DropdownMenuItem(value: 'LUNAS', child: Text('LUNAS', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))),
                            DropdownMenuItem(value: 'KREDIT', child: Text('KREDIT', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold))),
                            DropdownMenuItem(value: 'BELUM LUNAS', child: Text('BELUM LUNAS', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
                          ],
                          onChanged: (val) => setState(() => _paymentStatus = val!),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
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
                          Text('Subtotal: ${_formatRupiah(_subtotalAmount)}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                          Text(
                            _formatRupiah(_finalTotalAmount),
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF00796B)),
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        onPressed: _cart.isNotEmpty ? _showReceiptPreviewDialog : null,
                        icon: const Icon(Icons.receipt_long),
                        label: const Text('PROSES & STRUK'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00796B),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
