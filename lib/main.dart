import 'dart:io';
import 'package:flutter/material.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  runApp(const KasirApp());
}

class KasirApp extends StatelessWidget {
  const KasirApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Kasir Pintar',
      theme: ThemeData(
        primarySwatch: Colors.teal,
      ),
      home: const DashboardKasir(),
    );
  }
}

// Model Profil Toko dengan Logo
class StoreProfile {
  String name;
  String address;
  String phone;
  String footerNote;
  String? logoPath;

  StoreProfile({
    required this.name,
    required this.address,
    required this.phone,
    required this.footerNote,
    this.logoPath,
  });
}

// Model Produk dengan Harga Jual & Harga Modal
class Product {
  String name;
  double price; // Harga Jual
  double costPrice; // Harga Modal / Beli
  int stock;

  Product({
    required this.name,
    required this.price,
    required this.costPrice,
    required this.stock,
  });
}

// Model Item di Keranjang Belanja
class CartItem {
  Product product;
  int quantity;
  double customPrice;

  CartItem({
    required this.product,
    required this.quantity,
    double? customPrice,
  }) : customPrice = customPrice ?? product.price;

  double get subtotal => customPrice * quantity;
  double get subtotalCost => product.costPrice * quantity;
}

// Model Riwayat Transaksi Penjualan + Data Pelanggan Lengkap
class TransactionRecord {
  String id;
  String date;
  String customerName;
  String customerPhone;
  String customerCity;
  List<CartItem> items;
  double total;
  double totalCost;
  double paidAmount;
  double changeAmount;
  String note;

  TransactionRecord({
    required this.id,
    required this.date,
    required this.customerName,
    this.customerPhone = '',
    this.customerCity = '',
    required this.items,
    required this.total,
    required this.totalCost,
    required this.paidAmount,
    required this.changeAmount,
    this.note = '',
  });

  double get profit => total - totalCost;

  void recalculateTotal() {
    total = items.fold(0, (sum, item) => sum + item.subtotal);
    totalCost = items.fold(0, (sum, item) => sum + item.subtotalCost);
    changeAmount = paidAmount - total;
    if (changeAmount < 0) changeAmount = 0;
  }
}

// Model Catatan Keuangan
class CashRecord {
  final String title;
  final double amount;
  final bool isIncome;
  final String date;

  CashRecord({
    required this.title,
    required this.amount,
    required this.isIncome,
    required this.date,
  });
}

class DashboardKasir extends StatefulWidget {
  const DashboardKasir({Key? key}) : super(key: key);

  @override
  State<DashboardKasir> createState() => _DashboardKasirState();
}

class _DashboardKasirState extends State<DashboardKasir> {
  // Bluetooth Printer State
  BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;
  List<BluetoothDevice> _devices = [];
  BluetoothDevice? _selectedDevice;
  bool _isConnected = false;

  // Profil Toko Default
  StoreProfile storeProfile = StoreProfile(
    name: 'TOKO KASIR PINTAR',
    address: 'Jl. Merdeka No. 123, Jakarta',
    phone: '081234567890',
    footerNote: 'Terima kasih atas kunjungan Anda!\nBarang yang dibeli tidak dapat ditukar.',
  );

  // Daftar Produk Utama (Termasuk Harga Modal)
  List<Product> products = [
    Product(name: 'Kopi Susu', price: 15000, costPrice: 9000, stock: 50),
    Product(name: 'Roti Bakar', price: 12000, costPrice: 7000, stock: 30),
  ];

  // Daftar Riwayat Transaksi
  List<TransactionRecord> transactions = [];

  // Daftar Keuangan
  List<CashRecord> cashRecords = [];

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _initBluetooth();
  }

  void _initBluetooth() async {
    bool? isConn = await bluetooth.isConnected;
    List<BluetoothDevice> devices = [];
    try {
      devices = await bluetooth.getBondedDevices();
    } catch (e) {
      // Handle hardware / permission error
    }

    setState(() {
      _devices = devices;
      _isConnected = isConn ?? false;
    });
  }

  void _connectDevice(BluetoothDevice device) async {
    await bluetooth.connect(device);
    setState(() {
      _selectedDevice = device;
      _isConnected = true;
    });
  }

  void _disconnectDevice() async {
    await bluetooth.disconnect();
    setState(() {
      _isConnected = false;
    });
  }

  // Fungsi Cetak Struk dengan Logo
  void _printReceipt(TransactionRecord record) async {
    bool? connected = await bluetooth.isConnected;
    if (connected != true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Printer belum terhubung! Sambungkan printer via tombol di atas.')),
        );
      }
      return;
    }

    // 1. Cetak Logo Toko (Jika Ada)
    if (storeProfile.logoPath != null && File(storeProfile.logoPath!).existsSync()) {
      try {
        bluetooth.printImage(storeProfile.logoPath!);
      } catch (e) {
        // Fallback jika printer gagal memproses gambar
      }
    }

    // 2. Header Profil Toko
    bluetooth.printCustom(storeProfile.name.toUpperCase(), 2, 1);
    if (storeProfile.address.isNotEmpty) {
      bluetooth.printCustom(storeProfile.address, 1, 1);
    }
    if (storeProfile.phone.isNotEmpty) {
      bluetooth.printCustom("Telp: ${storeProfile.phone}", 1, 1);
    }
    bluetooth.printCustom("--------------------------------", 1, 1);

    // 3. Info Transaksi & Nama Pelanggan saja di Struk
    bluetooth.printLeftRight("Tgl :", record.date, 1);
    bluetooth.printLeftRight("No  :", record.id, 1);
    if (record.customerName.isNotEmpty) {
      bluetooth.printLeftRight("Pel :", record.customerName, 1);
    }
    bluetooth.printCustom("--------------------------------", 1, 1);

    // 4. Daftar Belanjaan
    for (var item in record.items) {
      bluetooth.printCustom(item.product.name, 1, 0);
      bluetooth.printLeftRight(
        "  ${item.quantity} x Rp ${item.customPrice.toStringAsFixed(0)}",
        "Rp ${item.subtotal.toStringAsFixed(0)}",
        1,
      );
    }

    bluetooth.printCustom("--------------------------------", 1, 1);

    // 5. Perhitungan Total & Pembayaran
    bluetooth.printLeftRight("TOTAL :", "Rp ${record.total.toStringAsFixed(0)}", 2);
    bluetooth.printLeftRight("BAYAR :", "Rp ${record.paidAmount.toStringAsFixed(0)}", 1);
    bluetooth.printLeftRight("KEMBALI:", "Rp ${record.changeAmount.toStringAsFixed(0)}", 1);

    if (record.note.isNotEmpty) {
      bluetooth.printCustom("Catatan: ${record.note}", 1, 0);
    }

    bluetooth.printCustom("================================", 1, 1);

    // 6. Pesan Penutup Toko
    if (storeProfile.footerNote.isNotEmpty) {
      bluetooth.printCustom(storeProfile.footerNote, 1, 1);
    }

    bluetooth.printNewLine();
    bluetooth.printNewLine();
  }

  void _showStoreProfileDialog() {
    final nameCtrl = TextEditingController(text: storeProfile.name);
    final addressCtrl = TextEditingController(text: storeProfile.address);
    final phoneCtrl = TextEditingController(text: storeProfile.phone);
    final footerCtrl = TextEditingController(text: storeProfile.footerNote);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Pengaturan Identitas Toko'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Preview & Pilih Logo Toko
                    if (storeProfile.logoPath != null && File(storeProfile.logoPath!).existsSync())
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(storeProfile.logoPath!),
                          height: 80,
                          width: 80,
                          fit: BoxFit.cover,
                        ),
                      )
                    else
                      Container(
                        height: 80,
                        width: 80,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.store, size: 40, color: Colors.grey),
                      ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.image),
                      label: Text(storeProfile.logoPath == null ? 'Pilih Logo Toko' : 'Ganti Logo'),
                      onPressed: () async {
                        final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
                        if (image != null) {
                          setDialogState(() {
                            storeProfile.logoPath = image.path;
                          });
                        }
                      },
                    ),
                    const Divider(),
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'Nama Toko / Usaha'),
                    ),
                    TextField(
                      controller: addressCtrl,
                      decoration: const InputDecoration(labelText: 'Alamat Toko'),
                    ),
                    TextField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(labelText: 'Nomor Telepon / WA'),
                    ),
                    TextField(
                      controller: footerCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Pesan Kaki Struk (Footer)',
                        hintText: 'Contoh: Terima kasih sudah berbelanja!',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                  onPressed: () {
                    setState(() {
                      storeProfile.name = nameCtrl.text;
                      storeProfile.address = addressCtrl.text;
                      storeProfile.phone = phoneCtrl.text;
                      storeProfile.footerNote = footerCtrl.text;
                    });
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Profil toko berhasil diperbarui!')),
                    );
                  },
                  child: const Text('Simpan', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showPrinterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Pengaturan Printer Bluetooth'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Status: ${_isConnected ? "Terhubung" : "Terputus"}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _isConnected ? Colors.green : Colors.red,
                            )),
                        IconButton(
                          icon: const Icon(Icons.refresh),
                          onPressed: () async {
                            List<BluetoothDevice> devs = await bluetooth.getBondedDevices();
                            setDialogState(() {
                              _devices = devs;
                            });
                          },
                        )
                      ],
                    ),
                    const Divider(),
                    _devices.isEmpty
                        ? const Text('Tidak ada perangkat Bluetooth tersambung di HP.')
                        : DropdownButton<BluetoothDevice>(
                            isExpanded: true,
                            hint: const Text('Pilih Perangkat Printer'),
                            value: _selectedDevice,
                            items: _devices.map((device) {
                              return DropdownMenuItem(
                                value: device,
                                child: Text(device.name ?? 'Perangkat Tanpa Nama'),
                              );
                            }).toList(),
                            onChanged: (device) {
                              setDialogState(() {
                                _selectedDevice = device;
                              });
                            },
                          ),
                  ],
                ),
              ),
              actions: [
                if (_isConnected)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    onPressed: () {
                      _disconnectDevice();
                      setDialogState(() {});
                      Navigator.pop(context);
                    },
                    child: const Text('Putuskan', style: TextStyle(color: Colors.white)),
                  )
                else
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                    onPressed: _selectedDevice == null
                        ? null
                        : () {
                            _connectDevice(_selectedDevice!);
                            Navigator.pop(context);
                          },
                    child: const Text('Sambungkan', style: TextStyle(color: Colors.white)),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(storeProfile.name),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.storefront),
            onPressed: _showStoreProfileDialog,
            tooltip: 'Pengaturan Toko',
          ),
          IconButton(
            icon: Icon(Icons.print, color: _isConnected ? Colors.greenAccent : Colors.white),
            onPressed: _showPrinterDialog,
            tooltip: 'Pengaturan Printer',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Banner Printer Status
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _isConnected ? Colors.green.shade50 : Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _isConnected ? Colors.green : Colors.orange),
                ),
                child: Row(
                  children: [
                    Icon(Icons.print, color: _isConnected ? Colors.green : Colors.orange),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _isConnected
                            ? 'Printer Aktif: ${_selectedDevice?.name ?? ""}'
                            : 'Printer Belum Terhubung (Ketuk ikon printer di atas)',
                        style: TextStyle(
                            color: _isConnected ? Colors.green.shade900 : Colors.orange.shade900,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              const Text('Menu Utama', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 10),

              // Menu Identitas Toko
              GestureDetector(
                onTap: _showStoreProfileDialog,
                child: _buildMenuItem(Icons.store, 'Pengaturan Identitas & Logo Toko'),
              ),

              // Menu Manajemen Produk
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProductManagementPage(
                        products: products,
                        onUpdateState: () => setState(() {}),
                      ),
                    ),
                  );
                },
                child: _buildMenuItem(Icons.layers, 'Manajemen Produk (Jual & Modal)'),
              ),

              // Menu Transaksi Penjualan
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SalesPage(
                        products: products,
                        onUpdateState: () => setState(() {}),
                        onCheckout: (newTx) {
                          setState(() {
                            transactions.add(newTx);
                            cashRecords.add(CashRecord(
                              title: 'Penjualan (${newTx.id})',
                              amount: newTx.total,
                              isIncome: true,
                              date: newTx.date,
                            ));
                          });
                          _printReceipt(newTx);
                        },
                      ),
                    ),
                  );
                },
                child: _buildMenuItem(Icons.shopping_cart, 'Transaksi Penjualan (Kasir)'),
              ),

              // Menu Keuangan & Laba Bersih
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => KeuanganPage(
                        transactions: transactions,
                        cashRecords: cashRecords,
                        onAddRecord: (newRecord) {
                          setState(() {
                            cashRecords.add(newRecord);
                          });
                        },
                      ),
                    ),
                  );
                },
                child: _buildMenuItem(Icons.account_balance_wallet, 'Keuangan & Laba Bersih'),
              ),

              // Menu Laporan Penjualan & Edit Struk
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LaporanPage(
                        transactions: transactions,
                        onPrint: _printReceipt,
                        onUpdateTransaction: () {
                          setState(() {});
                        },
                      ),
                    ),
                  );
                },
                child: _buildMenuItem(Icons.description, 'Laporan Penjualan & Edit Struk'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.teal, size: 28),
          const SizedBox(width: 16),
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// Halaman Manajemen Produk (Harga Jual & Modal)
class ProductManagementPage extends StatefulWidget {
  final List<Product> products;
  final VoidCallback onUpdateState;

  const ProductManagementPage({
    Key? key,
    required this.products,
    required this.onUpdateState,
  }) : super(key: key);

  @override
  State<ProductManagementPage> createState() => _ProductManagementPageState();
}

class _ProductManagementPageState extends State<ProductManagementPage> {
  String searchQuery = '';

  void _showAddProductDialog(BuildContext context) {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final costController = TextEditingController();
    final stockController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Tambah Produk Baru'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Nama Produk'),
                ),
                TextField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Harga Jual (Rp)'),
                ),
                TextField(
                  controller: costController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Harga Modal / Beli (Rp)'),
                ),
                TextField(
                  controller: stockController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Stok Awal'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
              onPressed: () {
                if (nameController.text.isNotEmpty && priceController.text.isNotEmpty) {
                  widget.products.add(
                    Product(
                      name: nameController.text,
                      price: double.tryParse(priceController.text) ?? 0,
                      costPrice: double.tryParse(costController.text) ?? 0,
                      stock: int.tryParse(stockController.text) ?? 0,
                    ),
                  );
                  widget.onUpdateState();
                  setState(() {});
                  Navigator.pop(context);
                }
              },
              child: const Text('Simpan', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showEditProductDialog(BuildContext context, Product product) {
    final nameController = TextEditingController(text: product.name);
    final priceController = TextEditingController(text: product.price.toStringAsFixed(0));
    final costController = TextEditingController(text: product.costPrice.toStringAsFixed(0));
    final stockController = TextEditingController(text: product.stock.toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Produk'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Nama Produk'),
                ),
                TextField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Harga Jual (Rp)'),
                ),
                TextField(
                  controller: costController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Harga Modal / Beli (Rp)'),
                ),
                TextField(
                  controller: stockController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Stok'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  product.name = nameController.text;
                  product.price = double.tryParse(priceController.text) ?? product.price;
                  product.costPrice = double.tryParse(costController.text) ?? product.costPrice;
                  product.stock = int.tryParse(stockController.text) ?? product.stock;

                  widget.onUpdateState();
                  setState(() {});
                  Navigator.pop(context);
                }
              },
              child: const Text('Simpan', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _confirmDeleteProduct(BuildContext context, Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Produk'),
        content: Text('Apakah kamu yakin ingin menghapus "${product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              widget.products.remove(product);
              widget.onUpdateState();
              setState(() {});
              Navigator.pop(context);
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Product> filteredProducts = widget.products
        .where((p) => p.name.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Produk'),
        backgroundColor: Colors.teal,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Cari nama produk...',
                prefixIcon: const Icon(Icons.search, color: Colors.teal),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
              onChanged: (val) {
                setState(() {
                  searchQuery = val;
                });
              },
            ),
          ),
          Expanded(
            child: filteredProducts.isEmpty
                ? const Center(child: Text('Produk tidak ditemukan'))
                : ListView.builder(
                    itemCount: filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = filteredProducts[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Colors.teal,
                            child: Icon(Icons.shopping_bag, color: Colors.white),
                          ),
                          title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(
                              'Jual: Rp ${product.price.toStringAsFixed(0)} | Modal: Rp ${product.costPrice.toStringAsFixed(0)}\nStok: ${product.stock}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.orange),
                                onPressed: () => _showEditProductDialog(context, product),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _confirmDeleteProduct(context, product),
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
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.teal,
        onPressed: () => _showAddProductDialog(context),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

// Halaman Transaksi Kasir dengan Pengeditan Jumlah Keranjang & Rincian Pembayaran
class SalesPage extends StatefulWidget {
  final List<Product> products;
  final VoidCallback onUpdateState;
  final Function(TransactionRecord) onCheckout;

  const SalesPage({
    Key? key,
    required this.products,
    required this.onUpdateState,
    required this.onCheckout,
  }) : super(key: key);

  @override
  State<SalesPage> createState() => _SalesPageState();
}

class _SalesPageState extends State<SalesPage> {
  final List<CartItem> cart = [];
  String searchQuery = '';

  double get totalHarga => cart.fold(0, (sum, item) => sum + item.subtotal);
  double get totalModal => cart.fold(0, (sum, item) => sum + item.subtotalCost);

  void _addToCart(Product product) {
    if (product.stock <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Stok produk habis!')),
      );
      return;
    }

    setState(() {
      var existing = cart.firstWhere(
        (item) => item.product.name == product.name,
        orElse: () => CartItem(product: Product(name: '', price: 0, costPrice: 0, stock: 0), quantity: 0),
      );

      if (existing.quantity > 0) {
        if (existing.quantity < product.stock) {
          existing.quantity++;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Stok tidak mencukupi!')),
          );
        }
      } else {
        cart.add(CartItem(product: product, quantity: 1));
      }
    });
  }

  void _incrementCartItem(CartItem item) {
    if (item.quantity < item.product.stock) {
      setState(() {
        item.quantity++;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jumlah melebihi stok yang tersedia!')),
      );
    }
  }

  void _decrementCartItem(CartItem item) {
    setState(() {
      if (item.quantity > 1) {
        item.quantity--;
      } else {
        cart.remove(item);
      }
    });
  }

  void _removeCartItem(CartItem item) {
    setState(() {
      cart.remove(item);
    });
  }

  // Pop-Up Rincian Penjualan & Pembayaran
  void _showCheckoutDialog() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final cityCtrl = TextEditingController();
    final paidCtrl = TextEditingController();
    double paidAmount = 0;
    double changeAmount = 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setBottomSheetState) {
            void calculateChange(String value) {
              paidAmount = double.tryParse(value) ?? 0;
              setBottomSheetState(() {
                changeAmount = paidAmount - totalHarga;
              });
            }

            return Padding(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Rincian Transaksi & Pembayaran',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal)),
                    const Divider(),

                    // Ringkasan Item
                    const Text('Daftar Belanja:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    Container(
                      maxHeight: 120,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: cart.length,
                        itemBuilder: (context, index) {
                          final i = cart[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('${i.product.name} x${i.quantity}'),
                                Text('Rp ${i.subtotal.toStringAsFixed(0)}'),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Pembayaran:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text('Rp ${totalHarga.toStringAsFixed(0)}',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal)),
                      ],
                    ),
                    const Divider(),

                    // Data Pelanggan
                    const Text('Data Pelanggan (Opsional)', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nama Pelanggan',
                        prefixIcon: Icon(Icons.person, color: Colors.teal),
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: phoneCtrl,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: 'No. Telp (Data)',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: cityCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Kota (Data)',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Uang Dibayar
                    TextField(
                      controller: paidCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Nominal Uang Dibayar (Rp)',
                        prefixIcon: Icon(Icons.money, color: Colors.teal),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: calculateChange,
                    ),
                    const SizedBox(height: 8),

                    // Tombol Cepat Nominal
                    Wrap(
                      spacing: 8,
                      children: [
                        ActionChip(
                          label: const Text('Uang Pas'),
                          onPressed: () {
                            paidCtrl.text = totalHarga.toStringAsFixed(0);
                            calculateChange(paidCtrl.text);
                          },
                        ),
                        ActionChip(
                          label: const Text('20rb'),
                          onPressed: () {
                            paidCtrl.text = '20000';
                            calculateChange('20000');
                          },
                        ),
                        ActionChip(
                          label: const Text('50rb'),
                          onPressed: () {
                            paidCtrl.text = '50000';
                            calculateChange('50000');
                          },
                        ),
                        ActionChip(
                          label: const Text('100rb'),
                          onPressed: () {
                            paidCtrl.text = '100000';
                            calculateChange('100000');
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Status Kembalian
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: changeAmount >= 0 ? Colors.green.shade50 : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Kembalian:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: changeAmount >= 0 ? Colors.green.shade900 : Colors.red.shade900,
                              )),
                          Text(
                            changeAmount >= 0
                                ? 'Rp ${changeAmount.toStringAsFixed(0)}'
                                : 'Uang Kurang Rp ${(-changeAmount).toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: changeAmount >= 0 ? Colors.green : Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                        onPressed: changeAmount < 0 || paidAmount == 0
                            ? null
                            : () {
                                final now = DateTime.now();
                                String formattedDate =
                                    "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} - ${now.day}/${now.month}/${now.year}";
                                String txId = "TX${now.millisecondsSinceEpoch.toString().substring(7)}";

                                List<CartItem> recordedItems = cart
                                    .map((i) => CartItem(
                                          product: i.product,
                                          quantity: i.quantity,
                                          customPrice: i.customPrice,
                                        ))
                                    .toList();

                                TransactionRecord newRecord = TransactionRecord(
                                  id: txId,
                                  date: formattedDate,
                                  customerName: nameCtrl.text,
                                  customerPhone: phoneCtrl.text,
                                  customerCity: cityCtrl.text,
                                  items: recordedItems,
                                  total: totalHarga,
                                  totalCost: totalModal,
                                  paidAmount: paidAmount,
                                  changeAmount: changeAmount,
                                );

                                setState(() {
                                  for (var item in cart) {
                                    item.product.stock -= item.quantity;
                                  }
                                  widget.onCheckout(newRecord);
                                  cart.clear();
                                });

                                widget.onUpdateState();
                                Navigator.pop(context);

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Transaksi Berhasil & Struk Dicetak!')),
                                );
                              },
                        child: const Text('KONFIRMASI & CETAK STRUK',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Product> filteredProducts = widget.products
        .where((p) => p.name.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaksi Penjualan (Kasir)'),
        backgroundColor: Colors.teal,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Cari produk kasir...',
                prefixIcon: const Icon(Icons.search, color: Colors.teal),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
              onChanged: (val) {
                setState(() {
                  searchQuery = val;
                });
              },
            ),
          ),
          SizedBox(
            height: 100,
            child: filteredProducts.isEmpty
                ? const Center(child: Text('Produk tidak ditemukan'))
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: filteredProducts.length,
                    itemBuilder: (context, index) {
                      final p = filteredProducts[index];
                      return GestureDetector(
                        onTap: () => _addToCart(p),
                        child: Container(
                          width: 130,
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.teal.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.teal.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(p.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 4),
                              Text('Rp ${p.price.toStringAsFixed(0)}',
                                  style: const TextStyle(color: Colors.teal, fontSize: 12)),
                              const SizedBox(height: 4),
                              Text('Stok: ${p.stock}',
                                  style: const TextStyle(color: Colors.grey, fontSize: 12)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          const Divider(thickness: 2),
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text('Keranjang Belanja', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          Expanded(
            child: cart.isEmpty
                ? const Center(
                    child: Text('Keranjang masih kosong', style: TextStyle(color: Colors.grey)))
                : ListView.builder(
                    itemCount: cart.length,
                    itemBuilder: (context, index) {
                      final item = cart[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.product.name,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                    Text('Rp ${item.customPrice.toStringAsFixed(0)} / pcs',
                                        style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                  ],
                                ),
                              ),
                              // Tombol Edit Jumlah Item (+ / - / Hapus)
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline, color: Colors.orange),
                                    onPressed: () => _decrementCartItem(item),
                                  ),
                                  Text('${item.quantity}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline, color: Colors.teal),
                                    onPressed: () => _incrementCartItem(item),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _removeCartItem(item),
                                  ),
                                ],
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
            color: Colors.grey.shade100,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Pembayaran:', style: TextStyle(color: Colors.grey)),
                    Text('Rp ${totalHarga.toStringAsFixed(0)}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18, color: Colors.teal)),
                  ],
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  onPressed: cart.isEmpty ? null : _showCheckoutDialog,
                  child: const Text('Bayar & Cetak', style: TextStyle(fontSize: 16, color: Colors.white)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Halaman Keuangan & Laporan Laba Bersih
class KeuanganPage extends StatefulWidget {
  final List<TransactionRecord> transactions;
  final List<CashRecord> cashRecords;
  final Function(CashRecord) onAddRecord;

  const KeuanganPage({
    Key? key,
    required this.transactions,
    required this.cashRecords,
    required this.onAddRecord,
  }) : super(key: key);

  @override
  State<KeuanganPage> createState() => _KeuanganPageState();
}

class _KeuanganPageState extends State<KeuanganPage> {
  void _showAddDialog(BuildContext context) {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    bool isIncome = true;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Catat Kas / Keuangan'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Keterangan'),
                  ),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Nominal (Rp)'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ChoiceChip(
                        label: const Text('Pemasukan'),
                        selected: isIncome,
                        selectedColor: Colors.teal.shade200,
                        onSelected: (val) => setDialogState(() => isIncome = true),
                      ),
                      const SizedBox(width: 10),
                      ChoiceChip(
                        label: const Text('Pengeluaran'),
                        selected: !isIncome,
                        selectedColor: Colors.red.shade200,
                        onSelected: (val) => setDialogState(() => isIncome = false),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                  onPressed: () {
                    if (titleController.text.isNotEmpty && amountController.text.isNotEmpty) {
                      final now = DateTime.now();
                      String formattedDate =
                          "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} - ${now.day}/${now.month}/${now.year}";

                      widget.onAddRecord(CashRecord(
                        title: titleController.text,
                        amount: double.tryParse(amountController.text) ?? 0,
                        isIncome: isIncome,
                        date: formattedDate,
                      ));
                      setState(() {});
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Simpan', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    double totalOmzet = widget.transactions.fold(0, (sum, tx) => sum + tx.total);
    double totalModal = widget.transactions.fold(0, (sum, tx) => sum + tx.totalCost);
    double totalLabaBersih = totalOmzet - totalModal;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Keuangan & Laba Bersih'),
        backgroundColor: Colors.teal,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.teal.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.teal.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Laba Bersih Penjualan', style: TextStyle(color: Colors.grey, fontSize: 14)),
                const SizedBox(height: 6),
                Text('Rp ${totalLabaBersih.toStringAsFixed(0)}',
                    style: const TextStyle(
                        fontSize: 26, fontWeight: FontWeight.bold, color: Colors.teal)),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total Omzet: Rp ${totalOmzet.toStringAsFixed(0)}',
                        style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                    Text('Total Modal: Rp ${totalModal.toStringAsFixed(0)}',
                        style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Catatan Kas Lain-Lain', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: widget.cashRecords.isEmpty
                ? const Center(
                    child: Text('Belum ada catatan keuangan manual', style: TextStyle(color: Colors.grey)))
                : ListView.builder(
                    itemCount: widget.cashRecords.length,
                    itemBuilder: (context, index) {
                      final r = widget.cashRecords[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                r.isIncome ? Colors.green.shade100 : Colors.red.shade100,
                            child: Icon(
                              r.isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                              color: r.isIncome ? Colors.green : Colors.red,
                            ),
                          ),
                          title: Text(r.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(r.date),
                          trailing: Text(
                            '${r.isIncome ? "+" : "-"} Rp ${r.amount.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: r.isIncome ? Colors.green : Colors.red,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.teal,
        onPressed: () => _showAddDialog(context),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

// Halaman Laporan Penjualan & Edit Struk
class LaporanPage extends StatefulWidget {
  final List<TransactionRecord> transactions;
  final Function(TransactionRecord) onPrint;
  final VoidCallback onUpdateTransaction;

  const LaporanPage({
    Key? key,
    required this.transactions,
    required this.onPrint,
    required this.onUpdateTransaction,
  }) : super(key: key);

  @override
  State<LaporanPage> createState() => _LaporanPageState();
}

class _LaporanPageState extends State<LaporanPage> {
  void _showEditReceiptDialog(TransactionRecord tx) {
    final noteController = TextEditingController(text: tx.note);
    final customerController = TextEditingController(text: tx.customerName);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Edit Struk: ${tx.id}'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: customerController,
                      decoration: const InputDecoration(labelText: 'Nama Pelanggan'),
                    ),
                    const SizedBox(height: 12),
                    const Text('Ubah Jumlah Item:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    ...tx.items.map((item) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          children: [
                            Expanded(child: Text(item.product.name)),
                            IconButton(
                              icon: const Icon(Icons.remove_circle, color: Colors.red),
                              onPressed: () {
                                setDialogState(() {
                                  if (item.quantity > 1) {
                                    item.quantity--;
                                  } else {
                                    tx.items.remove(item);
                                  }
                                  tx.recalculateTotal();
                                });
                              },
                            ),
                            Text('${item.quantity}'),
                            IconButton(
                              icon: const Icon(Icons.add_circle, color: Colors.green),
                              onPressed: () {
                                setDialogState(() {
                                  item.quantity++;
                                  tx.recalculateTotal();
                                });
                              },
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    const Divider(),
                    TextField(
                      controller: noteController,
                      decoration: const InputDecoration(
                        labelText: 'Catatan Khusus Struk',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Baru:', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('Rp ${tx.total.toStringAsFixed(0)}',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                  onPressed: () {
                    setState(() {
                      tx.note = noteController.text;
                      tx.customerName = customerController.text;
                    });
                    widget.onUpdateTransaction();
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Struk berhasil diperbarui!')),
                    );
                  },
                  child: const Text('Simpan Struk', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    double totalOmzet = widget.transactions.fold(0, (sum, tx) => sum + tx.total);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan & Edit Struk'),
        backgroundColor: Colors.teal,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.teal.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.teal.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Total Omzet Penjualan', style: TextStyle(color: Colors.grey, fontSize: 14)),
                const SizedBox(height: 6),
                Text('Rp ${totalOmzet.toStringAsFixed(0)}',
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold, color: Colors.teal)),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Riwayat Transaksi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: widget.transactions.isEmpty
                ? const Center(
                    child: Text('Belum ada transaksi tercatat', style: TextStyle(color: Colors.grey)))
                : ListView.builder(
                    itemCount: widget.transactions.length,
                    itemBuilder: (context,index) {
                      final tx = widget.transactions[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        child: ExpansionTile(
                          title: Text('${tx.id} - Rp ${tx.total.toStringAsFixed(0)}',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
                          subtitle: Text(
                              'Waktu: ${tx.date}${tx.customerName.isNotEmpty ? ' | Pelanggan: ${tx.customerName}' : ''}'),
                          children: [
                            ...tx.items.map((item) {
                              return ListTile(
                                dense: true,
                                title: Text(item.product.name),
                                trailing: Text(
                                    '${item.quantity}x @Rp ${item.customPrice.toStringAsFixed(0)} = Rp ${item.subtotal.toStringAsFixed(0)}'),
                              );
                            }).toList(),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Bayar: Rp ${tx.paidAmount.toStringAsFixed(0)}',
                                      style: const TextStyle(color: Colors.grey)),
                                  Text('Kembali: Rp ${tx.changeAmount.toStringAsFixed(0)}',
                                      style: const TextStyle(color: Colors.grey)),
                                ],
                              ),
                            ),
                            if (tx.note.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text('Catatan: ${tx.note}',
                                    style: const TextStyle(fontStyle: FontStyle.italic)),
                              ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  OutlinedButton.icon(
                                    icon: const Icon(Icons.edit, color: Colors.orange, size: 18),
                                    label: const Text('Edit Struk', style: TextStyle(color: Colors.orange)),
                                    onPressed: () => _showEditReceiptDialog(tx),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                                    icon: const Icon(Icons.print, size: 18, color: Colors.white),
                                    label: const Text('Cetak Struk', style: TextStyle(color: Colors.white)),
                                    onPressed: () => widget.onPrint(tx),
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
