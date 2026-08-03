import 'package:flutter/material.dart';

void main() {
  runApp(const PosApp());
}

// ==================== HELPER FORMAT RUPIAH ====================
String formatRupiah(num amount) {
  return 'Rp ${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
}

// ==================== MODEL DATA ====================
class Product {
  final String id;
  final String name;
  final double price;
  int stock;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.stock,
  });
}

class CartItem {
  final Product product;
  int quantity;

  CartItem({required this.product, required this.quantity});

  double get subtotal => product.price * quantity;
}

class TransactionModel {
  final String id;
  final DateTime date;
  String customerName;
  String customerPhone;
  String customerCity;
  List<CartItem> items;
  double totalPrice;
  double paidAmount;
  double changeAmount;
  String notes;

  TransactionModel({
    required this.id,
    required this.date,
    required this.customerName,
    this.customerPhone = '',
    this.customerCity = '',
    required this.items,
    required this.totalPrice,
    required this.paidAmount,
    required this.changeAmount,
    this.notes = '',
  });
}

// ==================== MAIN APP ====================
class PosApp extends StatelessWidget {
  const PosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aplikasi Kasir POS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.teal,
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
        useMaterial3: false,
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Data Contoh Produk
  List<Product> products = [
    Product(id: 'P1', name: 'Roti Bakar', price: 12000, stock: 30),
    Product(id: 'P2', name: 'baso cimanggis', price: 12000, stock: 200),
    Product(id: 'P3', name: 'Es Teh Manis', price: 5000, stock: 100),
  ];

  // Data Keranjang & Transaksi
  List<CartItem> cart = [];
  List<TransactionModel> transactions = [];

  // Controller Kasir
  final TextEditingController _searchProductController = TextEditingController();
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _customerPhoneController = TextEditingController();
  final TextEditingController _customerCityController = TextEditingController();
  final TextEditingController _paidAmountController = TextEditingController();

  double paidAmount = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  // --- LOGIKA KASIR ---
  void _addToCart(Product product) {
    setState(() {
      int index = cart.indexWhere((item) => item.product.id == product.id);
      if (index != -1) {
        if (cart[index].quantity < product.stock) {
          cart[index].quantity++;
        } else {
          _showSnackBar('Stok produk terbatas!');
        }
      } else {
        if (product.stock > 0) {
          cart.add(CartItem(product: product, quantity: 1));
        } else {
          _showSnackBar('Stok produk habis!');
        }
      }
    });
  }

  void _updateCartQty(CartItem item, int newQty) {
    setState(() {
      if (newQty <= 0) {
        cart.removeWhere((i) => i.product.id == item.product.id);
      } else if (newQty <= item.product.stock) {
        item.quantity = newQty;
      } else {
        _showSnackBar('Jumlah melebihi stok yang tersedia (${item.product.stock} pcs)!');
      }
    });
  }

  double get cartTotal => cart.fold(0, (sum, item) => sum + item.subtotal);
  double get changeAmount => (paidAmount >= cartTotal) ? (paidAmount - cartTotal) : 0;

  void _showSnackBar(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  // Dialog Keyboard Input Angka Langsung
  void _showQuantityDialog(int currentQty, Function(int) onSave) {
    TextEditingController qtyController = TextEditingController(text: currentQty.toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Masukkan Jumlah'),
        content: TextField(
          controller: qtyController,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Jumlah (pcs)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
            onPressed: () {
              int? val = int.tryParse(qtyController.text);
              if (val != null && val > 0) {
                onSave(val);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  // --- PROSES KONFIRMASI TRANSAKSI ---
  void _processTransaction() {
    if (cart.isEmpty) {
      _showSnackBar('Keranjang belanja masih kosong!');
      return;
    }
    if (paidAmount < cartTotal) {
      _showSnackBar('Uang pembayaran masih kurang!');
      return;
    }

    // Buat Transaksi Baru
    String txId = 'TX${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    TransactionModel newTx = TransactionModel(
      id: txId,
      date: DateTime.now(),
      customerName: _customerNameController.text.isEmpty ? 'Umum' : _customerNameController.text,
      customerPhone: _customerPhoneController.text,
      customerCity: _customerCityController.text,
      items: cart.map((i) => CartItem(product: i.product, quantity: i.quantity)).toList(),
      totalPrice: cartTotal,
      paidAmount: paidAmount,
      changeAmount: changeAmount,
    );

    // Potong Stok Produk
    for (var item in cart) {
      item.product.stock -= item.quantity;
    }

    setState(() {
      transactions.insert(0, newTx);
    });

    // Tampilkan Dialog Receipt Preview
    _showReceiptPreview(newTx);
  }

  // Dialog Receipt Preview
  void _showReceiptPreview(TransactionModel tx) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.all(16),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Center(
                      child: Text(
                        'STRUK PEMBAYARAN',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                    const Divider(thickness: 1),
                    Text('No. Transaksi : ${tx.id}'),
                    Text('Tanggal       : ${tx.date.toString().substring(0, 16)}'),
                    Text('Pelanggan     : ${tx.customerName}'),
                    const Divider(thickness: 1),
                    ...tx.items.map((item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${item.product.name} x${item.quantity}'),
                          Text(formatRupiah(item.subtotal)),
                        ],
                      ),
                    )),
                    const Divider(thickness: 1),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total:', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(formatRupiah(tx.totalPrice), style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Bayar:'),
                        Text(formatRupiah(tx.paidAmount)),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Kembali:'),
                        Text(formatRupiah(tx.changeAmount)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          OutlinedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _clearCartForm();
            },
            child: const Text('Selesai (Tanpa Cetak)'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
            icon: const Icon(Icons.print, color: Colors.white),
            label: const Text('Cetak Struk', style: TextStyle(color: Colors.white)),
            onPressed: () {
              Navigator.pop(ctx);
              _clearCartForm();
              _showSnackBar('Menghubungkan ke printer & mencetak struk...');
            },
          ),
        ],
      ),
    );
  }

  void _clearCartForm() {
    setState(() {
      cart.clear();
      _customerNameController.clear();
      _customerPhoneController.clear();
      _customerCityController.clear();
      _paidAmountController.clear();
      paidAmount = 0;
    });
  }

  // --- LOGIKA EDIT STRUK & PENYESUAIAN STOK OTOMATIS ---
  void _showEditReceiptDialog(TransactionModel tx) {
    TextEditingController editCustomerName = TextEditingController(text: tx.customerName);
    TextEditingController editNotes = TextEditingController(text: tx.notes);
    List<CartItem> editedItems = tx.items.map((i) => CartItem(product: i.product, quantity: i.quantity)).toList();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            double newTotal = editedItems.fold(0, (sum, i) => sum + i.subtotal);

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text('Edit Struk: ${tx.id}'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: editCustomerName,
                      decoration: const InputDecoration(labelText: 'Nama Pelanggan'),
                    ),
                    const SizedBox(height: 12),
                    const Text('Ubah Jumlah Item:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ...editedItems.map((item) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(child: Text(item.product.name)),
                            IconButton(
                              icon: const Icon(Icons.remove_circle, color: Colors.red),
                              onPressed: () {
                                if (item.quantity > 1) {
                                  setModalState(() => item.quantity--);
                                }
                              },
                            ),
                            InkWell(
                              onTap: () {
                                _showQuantityDialog(item.quantity, (newQty) {
                                  setModalState(() => item.quantity = newQty);
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_circle, color: Colors.green),
                              onPressed: () {
                                setModalState(() => item.quantity++);
                              },
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 12),
                    TextField(
                      controller: editNotes,
                      decoration: const InputDecoration(labelText: 'Catatan Khusus Struk'),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Baru:', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(formatRupiah(newTotal), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
                      ],
                    )
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Batal', style: TextStyle(color: Colors.purple)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                  onPressed: () {
                    // VALIDASI DAN PENYESUAIAN STOK OTOMATIS
                    for (var editedItem in editedItems) {
                      CartItem oldItem = tx.items.firstWhere(
                        (i) => i.product.id == editedItem.product.id,
                        orElse: () => CartItem(product: editedItem.product, quantity: 0),
                      );
                      int diff = editedItem.quantity - oldItem.quantity; // Selisih jumlah

                      if (diff > 0 && diff > editedItem.product.stock) {
                        _showSnackBar('Stok ${editedItem.product.name} tidak mencukupi untuk penambahan!');
                        return;
                      }
                    }

                    // Terapkan Penyesuaian Stok
                    for (var editedItem in editedItems) {
                      CartItem oldItem = tx.items.firstWhere(
                        (i) => i.product.id == editedItem.product.id,
                        orElse: () => CartItem(product: editedItem.product, quantity: 0),
                      );
                      int diff = editedItem.quantity - oldItem.quantity;
                      editedItem.product.stock -= diff; // Jika diff positif stok berkurang, jika negatif stok bertambah
                    }

                    // Simpan Perubahan Struk
                    setState(() {
                      tx.customerName = editCustomerName.text;
                      tx.notes = editNotes.text;
                      tx.items = editedItems;
                      tx.totalPrice = newTotal;
                      tx.changeAmount = (tx.paidAmount >= newTotal) ? (tx.paidAmount - newTotal) : 0;
                    });

                    Navigator.pop(ctx);
                    _showSnackBar('Struk & stok otomatis berhasil diperbarui!');
                  },
                  child: const Text('Simpan Struk'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // BUILDER UTAMA
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaksi Penjualan (Kasir)'),
        backgroundColor: Colors.teal,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.shopping_cart), text: 'Kasir'),
            Tab(icon: Icon(Icons.receipt_long), text: 'Laporan & Edit Struk'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCashierTab(),
          _buildReportTab(),
        ],
      ),
    );
  }

  // --- TAB 1: KASIR ---
  Widget _buildCashierTab() {
    List<Product> filteredProducts = products
        .where((p) => p.name.toLowerCase().contains(_searchProductController.text.toLowerCase()))
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Product
          TextField(
            controller: _searchProductController,
            onChanged: (v) => setState(() {}),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: 'Cari produk kasir...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
          ),
          const SizedBox(height: 12),

          // Daftar Produk (Horizontal List)
          SizedBox(
            height: 110,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: filteredProducts.length,
              itemBuilder: (ctx, idx) {
                final p = filteredProducts[idx];
                return Container(
                  width: 140,
                  margin: const EdgeInsets.only(right: 8),
                  child: Card(
                    color: Colors.teal.shade50,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: const BorderSide(color: Colors.teal, width: 0.5),
                    ),
                    child: InkWell(
                      onTap: () => _addToCart(p),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                            Text(formatRupiah(p.price), style: const TextStyle(color: Colors.teal, fontSize: 12)),
                            const SizedBox(height: 4),
                            Text('Stok: ${p.stock}', style: TextStyle(color: Colors.grey.shade700, fontSize: 11)),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 16),
          const Center(child: Text('Keranjang Belanja', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
          const SizedBox(height: 8),

          // Cart Items List
          ...cart.map((item) => Card(
            margin: const EdgeInsets.symmetric(vertical: 4),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text('${formatRupiah(item.product.price)} / pcs', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, color: Colors.orange),
                    onPressed: () => _updateCartQty(item, item.quantity - 1),
                  ),
                  // Angka Qty Clickable
                  InkWell(
                    onTap: () {
                      _showQuantityDialog(item.quantity, (newQty) {
                        _updateCartQty(item, newQty);
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      child: Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, color: Colors.teal),
                    onPressed: () => _updateCartQty(item, item.quantity + 1),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => _updateCartQty(item, 0),
                  ),
                ],
              ),
            ),
          )),

          const SizedBox(height: 16),
          // Form Rincian Transaksi
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Pembayaran:', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(formatRupiah(cartTotal), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.teal)),
                    ],
                  ),
                  const Divider(),
                  TextField(
                    controller: _customerNameController,
                    decoration: const InputDecoration(labelText: 'Nama Pelanggan (Opsional)', prefixIcon: Icon(Icons.person)),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _customerPhoneController,
                          decoration: const InputDecoration(labelText: 'No. Telp'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _customerCityController,
                          decoration: const InputDecoration(labelText: 'Kota'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _paidAmountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Nominal Uang Dibayar (Rp)', prefixIcon: Icon(Icons.money)),
                    onChanged: (v) {
                      setState(() {
                        paidAmount = double.tryParse(v) ?? 0;
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  // Quick Cash Buttons
                  Wrap(
                    spacing: 8,
                    children: [
                      ActionChip(label: const Text('Uang Pas'), onPressed: () => setState(() { paidAmount = cartTotal; _paidAmountController.text = cartTotal.toStringAsFixed(0); })),
                      ActionChip(label: const Text('20rb'), onPressed: () => setState(() { paidAmount = 20000; _paidAmountController.text = '20000'; })),
                      ActionChip(label: const Text('50rb'), onPressed: () => setState(() { paidAmount = 50000; _paidAmountController.text = '50000'; })),
                      ActionChip(label: const Text('100rb'), onPressed: () => setState(() { paidAmount = 100000; _paidAmountController.text = '100000'; })),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(6)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Kembalian:', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                        Text(formatRupiah(changeAmount), style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      onPressed: _processTransaction,
                      child: const Text('KONFIRMASI TRANSAKSI', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  // --- TAB 2: LAPORAN & EDIT STRUK ---
  String _searchReportQuery = '';
  bool _filterTodayOnly = false;

  Widget _buildReportTab() {
    double totalOmzet = transactions.fold(0, (sum, tx) => sum + tx.totalPrice);

    List<TransactionModel> filteredTx = transactions.where((tx) {
      bool matchesSearch = tx.customerName.toLowerCase().contains(_searchReportQuery.toLowerCase()) ||
          tx.id.toLowerCase().contains(_searchReportQuery.toLowerCase());
      if (_filterTodayOnly) {
        DateTime now = DateTime.now();
        bool isToday = tx.date.year == now.year && tx.date.month == now.month && tx.date.day == now.day;
        return matchesSearch && isToday;
      }
      return matchesSearch;
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: [
          // Total Omzet Card
          Card(
            color: Colors.teal.shade50,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total Omzet Penjualan', style: TextStyle(color: Colors.grey)),
                      Text(formatRupiah(totalOmzet), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal)),
                    ],
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                    icon: const Icon(Icons.download, size: 18),
                    label: const Text('Ekspor'),
                    onPressed: () {
                      _showExportDialog(totalOmzet, filteredTx);
                    },
                  )
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Search & Filter Bar
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Cari Struk / Pelanggan...',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(vertical: 0),
                  ),
                  onChanged: (v) => setState(() => _searchReportQuery = v),
                ),
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('Hari Ini'),
                selected: _filterTodayOnly,
                onSelected: (val) => setState(() => _filterTodayOnly = val),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Daftar Riwayat Transaksi
          Expanded(
            child: filteredTx.isEmpty
                ? const Center(child: Text('Belum ada data transaksi'))
                : ListView.builder(
                    itemCount: filteredTx.length,
                    itemBuilder: (ctx, idx) {
                      final tx = filteredTx[idx];
                      return Card(
                        child: ListTile(
                          title: Text('${tx.id} - ${tx.customerName}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('${tx.date.toString().substring(0, 16)}\nItems: ${tx.items.length} jenis'),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(formatRupiah(tx.totalPrice), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
                              InkWell(
                                onTap: () => _showEditReceiptDialog(tx),
                                child: const Padding(
                                  padding: EdgeInsets.only(top: 4.0),
                                  child: Text('Edit Struk', style: TextStyle(color: Colors.purple, fontSize: 12, fontWeight: FontWeight.bold)),
                                ),
                              )
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // Dialog Ekspor Laporan
  void _showExportDialog(double totalOmzet, List<TransactionModel> txList) {
    String reportText = "=== LAPORAN PENJUALAN POS ===\n";
    reportText += "Total Omzet : ${formatRupiah(totalOmzet)}\n";
    reportText += "Jumlah Tx   : ${txList.length} transaksi\n";
    reportText += "------------------------------\n";
    for (var tx in txList) {
      reportText += "${tx.id} | ${tx.customerName} | ${formatRupiah(tx.totalPrice)}\n";
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ringkasan Laporan'),
        content: SingleChildScrollView(
          child: SelectableText(reportText, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tutup')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
            onPressed: () {
              Navigator.pop(ctx);
              _showSnackBar('Laporan disalin ke clipboard / siap bagikan!');
            },
            child: const Text('Salin / Bagikan'),
          ),
        ],
      ),
    );
  }
}

