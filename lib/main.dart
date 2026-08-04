import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';

void main() {
  runApp(const KasirPintarApp());
}

// ==========================================
// MODEL DATA UTAMA
// ==========================================
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
}

class SalesTransaction {
  final String id;
  final DateTime date;
  final List<CartItem> items;
  final double totalAmount;
  final double totalModal;

  SalesTransaction({
    required this.id,
    required this.date,
    required this.items,
    required this.totalAmount,
    required this.totalModal,
  });
}

// ==========================================
// APLIKASI UTAMA
// ==========================================
class KasirPintarApp extends StatefulWidget {
  const KasirPintarApp({Key? key}) : super(key: key);

  @override
  State<KasirPintarApp> createState() => _KasirPintarAppState();
}

class _KasirPintarAppState extends State<KasirPintarApp> {
  StoreInfo storeInfo = StoreInfo(
    name: 'TOKO KASIR PINTAR',
    address: 'Jl. Merdeka No. 123, Jakarta',
    phone: '081234567890',
    footer: 'Terima kasih atas kunjungan Anda!',
  );

  List<Product> products = [
    Product(id: '1', name: 'Kopi Susu', sellingPrice: 15000, modalPrice: 9000, stock: 50),
    Product(id: '2', name: 'Roti Bakar', sellingPrice: 12000, modalPrice: 7000, stock: 30),
  ];

  List<SalesTransaction> transactions = [];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Toko Kasir Pintar',
      theme: ThemeData(
        primaryColor: const Color(0xFF00897B),
        scaffoldBackgroundColor: Colors.white,
      ),
      home: MainHomeScreen(
        storeInfo: storeInfo,
        products: products,
        transactions: transactions,
        onUpdateStore: (updated) => setState(() => storeInfo = updated),
        onUpdateProducts: (updated) => setState(() => products = updated),
        onAddTransaction: (trx) => setState(() => transactions.add(trx)),
      ),
    );
  }
}

// ==========================================
// 1. HALAMAN UTAMA (DENGAN BLUETOOTH PRINTER & IMAGE PICKER)
// ==========================================
class MainHomeScreen extends StatefulWidget {
  final StoreInfo storeInfo;
  final List<Product> products;
  final List<SalesTransaction> transactions;
  final Function(StoreInfo) onUpdateStore;
  final Function(List<Product>) onUpdateProducts;
  final Function(SalesTransaction) onAddTransaction;

  const MainHomeScreen({
    Key? key,
    required this.storeInfo,
    required this.products,
    required this.transactions,
    required this.onUpdateStore,
    required this.onUpdateProducts,
    required this.onAddTransaction,
  }) : super(key: key);

  @override
  State<MainHomeScreen> createState() => _MainHomeScreenState();
}

class _MainHomeScreenState extends State<MainHomeScreen> {
  BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;
  List<BluetoothDevice> _devices = [];
  BluetoothDevice? _selectedDevice;
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _initBluetooth();
  }

  void _initBluetooth() async {
    try {
      bool? isConnected = await bluetooth.isConnected;
      List<BluetoothDevice> devices = await bluetooth.getBondedDevices();
      setState(() {
        _devices = devices;
        _isConnected = isConnected ?? false;
      });
    } catch (e) {
      debugPrint("Bluetooth error: $e");
    }
  }

  void _showPrinterDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Pilih Printer Bluetooth'),
        content: SizedBox(
          width: double.maxFinite,
          child: _devices.isEmpty
              ? const Text('Tidak ada perangkat Bluetooth terpasang.')
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: _devices.length,
                  itemBuilder: (context, index) {
                    final device = _devices[index];
                    return ListTile(
                      title: Text(device.name ?? 'Unknown Device'),
                      subtitle: Text(device.address ?? ''),
                      trailing: _selectedDevice?.address == device.address && _isConnected
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : null,
                      onTap: () async {
                        try {
                          await bluetooth.connect(device);
                          setState(() {
                            _selectedDevice = device;
                            _isConnected = true;
                          });
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Terhubung ke ${device.name}')),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Gagal menghubungkan printer!')),
                          );
                        }
                      },
                    );
                  },
                ),
        ),
        actions: [
          if (_isConnected)
            TextButton(
              onPressed: () async {
                await bluetooth.disconnect();
                setState(() {
                  _isConnected = false;
                  _selectedDevice = null;
                });
                Navigator.pop(ctx);
              },
              child: const Text('Putuskan', style: TextStyle(color: Colors.red)),
            ),
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tutup')),
        ],
      ),
    );
  }

  void _showStoreSettingsDialog() {
    final nameCtrl = TextEditingController(text: widget.storeInfo.name);
    final addressCtrl = TextEditingController(text: widget.storeInfo.address);
    final phoneCtrl = TextEditingController(text: widget.storeInfo.phone);
    final footerCtrl = TextEditingController(text: widget.storeInfo.footer);
    File? tempImage = widget.storeInfo.logoFile;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Pengaturan Identitas Toko', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 80,
                    width: 80,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: tempImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(tempImage!, fit: BoxFit.cover),
                          )
                        : const Icon(Icons.storefront, size: 40, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final picker = ImagePicker();
                      final picked = await picker.pickImage(source: ImageSource.gallery);
                      if (picked != null) {
                        setDialogState(() {
                          tempImage = File(picked.path);
                        });
                      }
                    },
                    icon: const Icon(Icons.image, size: 18, color: Colors.purple),
                    label: const Text('Pilih Logo Toko', style: TextStyle(color: Colors.purple)),
                    style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                  ),
                  const SizedBox(height: 12),
                  TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nama Toko / Usaha')),
                  TextField(controller: addressCtrl, decoration: const InputDecoration(labelText: 'Alamat Toko')),
                  TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Nomor Telepon / WA')),
                  TextField(controller: footerCtrl, decoration: const InputDecoration(labelText: 'Pesan Kaki Struk (Footer)')),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal', style: TextStyle(color: Colors.purple))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00897B), foregroundColor: Colors.white),
                onPressed: () {
                  widget.onUpdateStore(StoreInfo(
                    name: nameCtrl.text,
                    address: addressCtrl.text,
                    phone: phoneCtrl.text,
                    footer: footerCtrl.text,
                    logoFile: tempImage,
                  ));
                  Navigator.pop(ctx);
                },
                child: const Text('Simpan'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF00897B),
        title: Text(widget.storeInfo.name.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          IconButton(icon: const Icon(Icons.storefront, color: Colors.white), onPressed: _showStoreSettingsDialog),
          IconButton(
            icon: Icon(Icons.print, color: _isConnected ? Colors.lightGreenAccent : Colors.white),
            onPressed: _showPrinterDialog,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: _showPrinterDialog,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _isConnected ? Colors.green.shade50 : Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _isConnected ? Colors.green.shade300 : Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.print, color: _isConnected ? Colors.green : Colors.orange),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _isConnected
                            ? 'Printer Terhubung: ${_selectedDevice?.name}'
                            : 'Printer Belum Terhubung (Ketuk ikon printer di atas)',
                        style: TextStyle(
                          color: _isConnected ? Colors.green.shade800 : Colors.orange.shade900,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Menu Utama', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            _buildMenuItem(context, Icons.storefront, 'Pengaturan Identitas & Logo Toko', _showStoreSettingsDialog),
            _buildMenuItem(context, Icons.layers, 'Manajemen Produk (Jual & Modal)', () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => ProductManagementScreen(products: widget.products, onUpdateProducts: widget.onUpdateProducts)));
            }),
            _buildMenuItem(context, Icons.shopping_cart, 'Transaksi Penjualan (Kasir)', () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CashierScreen(
                    products: widget.products,
                    storeInfo: widget.storeInfo,
                    bluetooth: bluetooth,
                    isConnected: _isConnected,
                    onAddTransaction: widget.onAddTransaction,
                  ),
                ),
              );
            }),
            _buildMenuItem(context, Icons.account_balance_wallet, 'Keuangan & Laba Bersih', () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => FinanceScreen(transactions: widget.transactions)));
            }),
            _buildMenuItem(context, Icons.assignment, 'Laporan Penjualan & Edit Struk', () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => ReportScreen(transactions: widget.transactions)));
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: const Color(0xFF00897B), size: 28),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
    );
  }
}

// ==========================================
// 2. HALAMAN MANAJEMEN PRODUK
// ==========================================
class ProductManagementScreen extends StatefulWidget {
  final List<Product> products;
  final Function(List<Product>) onUpdateProducts;

  const ProductManagementScreen({Key? key, required this.products, required this.onUpdateProducts}) : super(key: key);

  @override
  State<ProductManagementScreen> createState() => _ProductManagementScreenState();
}

class _ProductManagementScreenState extends State<ProductManagementScreen> {
  String search = '';

  void _showAddEditProductDialog([Product? product]) {
    final nameCtrl = TextEditingController(text: product?.name ?? '');
    final sellCtrl = TextEditingController(text: product?.sellingPrice.toInt().toString() ?? '');
    final modalCtrl = TextEditingController(text: product?.modalPrice.toInt().toString() ?? '');
    final stockCtrl = TextEditingController(text: product?.stock.toString() ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(product == null ? 'Tambah Produk' : 'Edit Produk'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nama Produk')),
            TextField(controller: sellCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Harga Jual')),
            TextField(controller: modalCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Harga Modal')),
            TextField(controller: stockCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Stok')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00897B), foregroundColor: Colors.white),
            onPressed: () {
              if (product == null) {
                widget.products.add(Product(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: nameCtrl.text,
                  sellingPrice: double.tryParse(sellCtrl.text) ?? 0,
                  modalPrice: double.tryParse(modalCtrl.text) ?? 0,
                  stock: int.tryParse(stockCtrl.text) ?? 0,
                ));
              } else {
                product.name = nameCtrl.text;
                product.sellingPrice = double.tryParse(sellCtrl.text) ?? 0;
                product.modalPrice = double.tryParse(modalCtrl.text) ?? 0;
                product.stock = int.tryParse(stockCtrl.text) ?? 0;
              }
              widget.onUpdateProducts(widget.products);
              setState(() {});
              Navigator.pop(ctx);
            },
            child: const Text('Simpan'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.products.where((p) => p.name.toLowerCase().contains(search.toLowerCase())).toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF00897B),
        title: const Text('Manajemen Produk', style: TextStyle(color: Colors.white)),
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              onChanged: (v) => setState(() => search = v),
              decoration: InputDecoration(
                hintText: 'Cari nama produk...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF00897B)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: filtered.length,
                itemBuilder: (ctx, idx) {
                  final p = filtered[idx];
                  return Card(
                    color: Colors.grey.shade50,
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      leading: const CircleAvatar(backgroundColor: Color(0xFF00897B), child: Icon(Icons.shopping_bag, color: Colors.white)),
                      title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('Jual: Rp ${p.sellingPrice.toInt()} | Modal: Rp ${p.modalPrice.toInt()}\nStok: ${p.stock}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(icon: const Icon(Icons.edit, color: Colors.orange), onPressed: () => _showAddEditProductDialog(p)),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              setState(() {
                                widget.products.remove(p);
                                widget.onUpdateProducts(widget.products);
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF00897B),
        onPressed: () => _showAddEditProductDialog(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

// ==========================================
// 3. HALAMAN KASIR PENJUALAN (DENGAN FUNGSI CETAK PRINTER SUNGGUHAN)
// ==========================================
class CashierScreen extends StatefulWidget {
  final List<Product> products;
  final StoreInfo storeInfo;
  final BlueThermalPrinter bluetooth;
  final bool isConnected;
  final Function(SalesTransaction) onAddTransaction;

  const CashierScreen({
    Key? key,
    required this.products,
    required this.storeInfo,
    required this.bluetooth,
    required this.isConnected,
    required this.onAddTransaction,
  }) : super(key: key);

  @override
  State<CashierScreen> createState() => _CashierScreenState();
}

class _CashierScreenState extends State<CashierScreen> {
  List<CartItem> cart = [];
  String search = '';

  double get totalPayment => cart.fold(0, (sum, item) => sum + item.subtotal);
  double get totalModal => cart.fold(0, (sum, item) => sum + item.totalModal);

  void _addToCart(Product product) {
    setState(() {
      int idx = cart.indexWhere((item) => item.product.id == product.id);
      if (idx != -1) {
        if (cart[idx].quantity < product.stock) cart[idx].quantity++;
      } else {
        if (product.stock > 0) cart.add(CartItem(product: product, quantity: 1));
      }
    });
  }

  void _printReceipt(SalesTransaction trx) async {
    if (!widget.isConnected) return;

    try {
      widget.bluetooth.printCustom(widget.storeInfo.name.toUpperCase(), 2, 1);
      widget.bluetooth.printCustom(widget.storeInfo.address, 0, 1);
      widget.bluetooth.printCustom('Telp: ${widget.storeInfo.phone}', 0, 1);
      widget.bluetooth.printCustom('--------------------------------', 1, 1);

      for (var item in trx.items) {
        widget.bluetooth.printLeftRight(
          '${item.product.name} x${item.quantity}',
          'Rp ${item.subtotal.toInt()}',
          0,
        );
      }

      widget.bluetooth.printCustom('--------------------------------', 1, 1);
      widget.bluetooth.printLeftRight('TOTAL:', 'Rp ${trx.totalAmount.toInt()}', 1);
      widget.bluetooth.printCustom('--------------------------------', 1, 1);
      widget.bluetooth.printCustom(widget.storeInfo.footer, 0, 1);
      widget.bluetooth.printNewLine();
      widget.bluetooth.printNewLine();
    } catch (e) {
      debugPrint("Gagal cetak struk: $e");
    }
  }

  void _processCheckout() {
    for (var item in cart) {
      item.product.stock -= item.quantity;
    }

    final newTrx = SalesTransaction(
      id: 'TRX-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}',
      date: DateTime.now(),
      items: List.from(cart),
      totalAmount: totalPayment,
      totalModal: totalModal,
    );

    widget.onAddTransaction(newTrx);

    if (widget.isConnected) {
      _printReceipt(newTrx);
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Transaksi Berhasil!'),
        content: Text(
          'Total Pembayaran: Rp ${totalPayment.toInt()}\n' +
          (widget.isConnected ? 'Struk dicetak ke printer.' : 'Printer tidak terhubung.'),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00897B), foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => cart.clear());
            },
            child: const Text('OK'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.products.where((p) => p.name.toLowerCase().contains(search.toLowerCase())).toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF00897B),
        title: const Text('Transaksi Penjualan (Kasir)', style: TextStyle(color: Colors.white)),
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (v) => setState(() => search = v),
              decoration: InputDecoration(
                hintText: 'Cari produk kasir...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF00897B)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          SizedBox(
            height: 90,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: filtered.length,
              itemBuilder: (ctx, idx) {
                final p = filtered[idx];
                return GestureDetector(
                  onTap: () => _addToCart(p),
                  child: Container(
                    width: 130,
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: const Color(0xFFE0F2F1), borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1),
                        Text('Rp ${p.sellingPrice.toInt()}', style: const TextStyle(color: Color(0xFF00897B), fontSize: 12)),
                        Text('Stok: ${p.stock}', style: const TextStyle(color: Colors.grey, fontSize: 10)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          const Text('Keranjang Belanja', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: cart.length,
              itemBuilder: (ctx, idx) {
                final item = cart[idx];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(item.product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Rp ${item.product.sellingPrice.toInt()} / pcs'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline, color: Colors.orange),
                          onPressed: () {
                            setState(() {
                              if (item.quantity > 1) {
                                item.quantity--;
                              } else {
                                cart.removeAt(idx);
                              }
                            });
                          },
                        ),
                        Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline, color: Color(0xFF00897B)),
                          onPressed: () => _addToCart(item.product),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () => setState(() => cart.removeAt(idx)),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.grey))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Pembayaran:', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    Text('Rp ${totalPayment.toInt()}', style: const TextStyle(color: Color(0xFF00897B), fontWeight: FontWeight.bold, fontSize: 18)),
                  ],
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00897B), foregroundColor: Colors.white),
                  onPressed: cart.isEmpty ? null : _processCheckout,
                  child: const Text('Bayar & Cetak'),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}

// ==========================================
// 4. HALAMAN KEUANGAN & LABA BERSIH
// ==========================================
class FinanceScreen extends StatelessWidget {
  final List<SalesTransaction> transactions;

  const FinanceScreen({Key? key, required this.transactions}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double totalOmzet = transactions.fold(0, (sum, t) => sum + t.totalAmount);
    double totalModal = transactions.fold(0, (sum, t) => sum + t.totalModal);
    double labaBersih = totalOmzet - totalModal;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF00897B),
        title: const Text('Keuangan & Laba Bersih', style: TextStyle(color: Colors.white)),
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFFE0F2F1), borderRadius: BorderRadius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Laba Bersih Penjualan', style: TextStyle(color: Colors.grey, fontSize: 13)),
                  Text('Rp ${labaBersih.toInt()}', style: const TextStyle(color: Color(0xFF00897B), fontWeight: FontWeight.bold, fontSize: 24)),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total Omzet: Rp ${totalOmzet.toInt()}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                      Text('Total Modal: Rp ${totalModal.toInt()}', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text('Catatan Kas Lain-Lain', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const Expanded(
              child: Center(child: Text('Belum ada catatan keuangan manual', style: TextStyle(color: Colors.grey))),
            )
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF00897B),
        onPressed: () {},
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

// ==========================================
// 5. HALAMAN LAPORAN & EDIT STRUK
// ==========================================
class ReportScreen extends StatelessWidget {
  final List<SalesTransaction> transactions;

  const ReportScreen({Key? key, required this.transactions}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double totalOmzet = transactions.fold(0, (sum, t) => sum + t.totalAmount);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF00897B),
        title: const Text('Laporan & Edit Struk', style: TextStyle(color: Colors.white)),
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFFE0F2F1), borderRadius: BorderRadius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total Omzet Penjualan', style: TextStyle(color: Colors.grey, fontSize: 13)),
                  Text('Rp ${totalOmzet.toInt()}', style: const TextStyle(color: Color(0xFF00897B), fontWeight: FontWeight.bold, fontSize: 24)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text('Riwayat Transaksi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 10),
            Expanded(
              child: transactions.isEmpty
                  ? const Center(child: Text('Belum ada transaksi tercatat', style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                      itemCount: transactions.length,
                      itemBuilder: (ctx, idx) {
                        final t = transactions[idx];
                        return Card(
                          child: ListTile(
                            title: Text(t.id, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('${t.items.length} Barang | Total: Rp ${t.totalAmount.toInt()}'),
                            trailing: Text('${t.date.day}/${t.date.month}/${t.date.year}'),
                          ),
                        );
                      },
                    ),
            )
          ],
        ),
      ),
    );
  }
}

