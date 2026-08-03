import 'package:flutter/material.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';

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

// Model Data Produk
class Product {
  String name;
  double price;
  int stock;

  Product({required this.name, required this.price, required this.stock});
}

// Model Data Item di Keranjang Belanja
class CartItem {
  Product product;
  int quantity;
  double customPrice; // Memungkinkan penyesuaian harga di struk

  CartItem({
    required this.product,
    required this.quantity,
    double? customPrice,
  }) : customPrice = customPrice ?? product.price;

  double get subtotal => customPrice * quantity;
}

// Model Data Riwayat Transaksi (Laporan Penjualan)
class TransactionRecord {
  String id;
  String date;
  List<CartItem> items;
  double total;
  String note;

  TransactionRecord({
    required this.id,
    required this.date,
    required this.items,
    required this.total,
    this.note = '',
  });

  void recalculateTotal() {
    total = items.fold(0, (sum, item) => sum + item.subtotal);
  }
}

// Model Data Keuangan (Kas Masuk / Keluar)
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
  // Bluetooth Printer Global State
  BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;
  List<BluetoothDevice> _devices = [];
  BluetoothDevice? _selectedDevice;
  bool _isConnected = false;

  // Daftar Produk Utama
  List<Product> products = [
    Product(name: 'Kopi Susu', price: 15000, stock: 50),
    Product(name: 'Roti Bakar', price: 12000, stock: 30),
  ];

  // Daftar Riwayat Transaksi Penjualan
  List<TransactionRecord> transactions = [];

  // Daftar Catatan Keuangan
  List<CashRecord> cashRecords = [];

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
      // Bluetooth permission or hardware issue handle gracefully
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

  // Fungsi Cetak Struk ke Printer Thermal
  void _printReceipt(TransactionRecord record) async {
    bool? connected = await bluetooth.isConnected;
    if (connected != true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Printer belum terhubung! Sambungkan printer di menu Bluetooth.')),
        );
      }
      return;
    }

    // Header Struk
    bluetooth.printCustom("KASIR PINTAR", 2, 1);
    bluetooth.printCustom("Toko Pintar Kamu", 1, 1);
    bluetooth.printCustom("--------------------------------", 1, 1);
    bluetooth.printLeftRight("Waktu:", record.date, 1);
    bluetooth.printLeftRight("ID Tx:", record.id, 1);
    bluetooth.printCustom("--------------------------------", 1, 1);

    // Detail Item
    for (var item in record.items) {
      bluetooth.printLeftRight(
        "${item.product.name} x${item.quantity}",
        "Rp ${item.subtotal.toStringAsFixed(0)}",
        1,
      );
    }

    bluetooth.printCustom("--------------------------------", 1, 1);
    bluetooth.printLeftRight("TOTAL:", "Rp ${record.total.toStringAsFixed(0)}", 2);

    if (record.note.isNotEmpty) {
      bluetooth.printCustom("Catatan: ${record.note}", 1, 0);
    }

    bluetooth.printCustom("================================", 1, 1);
    bluetooth.printCustom("Terima Kasih Atas Kunjungan Anda!", 1, 1);
    bluetooth.printNewLine();
    bluetooth.printNewLine();
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
                        ? const Text('Tidak ada perangkat Bluetooth tersambung di HP (Lakukan Pairing di Pengaturan HP dulu).')
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
        title: const Text('Kasir Pintar'),
        backgroundColor: Colors.teal,
        actions: [
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

              // Menu List
              const Text('Menu Utama', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 10),

              // Menu Manajemen
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
                child: _buildMenuItem(Icons.layers, 'Manajemen Produk'),
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
                child: _buildMenuItem(Icons.shopping_cart, 'Transaksi Penjualan'),
              ),

              // Menu Pembelian dari Supplier
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SupplierPage(
                        products: products,
                        onRestock: (productName, addedStock, totalCost) {
                          setState(() {
                            var p = products.firstWhere((item) => item.name == productName);
                            p.stock += addedStock;

                            final now = DateTime.now();
                            String formattedDate =
                                "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} - ${now.day}/${now.month}/${now.year}";
                            cashRecords.add(CashRecord(
                              title: 'Restock: $productName ($addedStock pcs)',
                              amount: totalCost,
                              isIncome: false,
                              date: formattedDate,
                            ));
                          });
                        },
                      ),
                    ),
                  );
                },
                child: _buildMenuItem(Icons.inventory, 'Pembelian dari Supplier'),
              ),

              // Menu Keuangan
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => KeuanganPage(
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
                child: _buildMenuItem(Icons.account_balance_wallet, 'Keuangan'),
              ),

              // Menu Laporan & Edit Struk
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

// Halaman Manajemen Produk
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
    final stockController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Tambah Produk Baru'),
          content: Column(
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
                controller: stockController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Stok Awal'),
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
                if (nameController.text.isNotEmpty && priceController.text.isNotEmpty) {
                  widget.products.add(
                    Product(
                      name: nameController.text,
                      price: double.tryParse(priceController.text) ?? 0,
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
    final stockController = TextEditingController(text: product.stock.toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Produk'),
          content: Column(
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
                controller: stockController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Stok'),
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
                if (nameController.text.isNotEmpty) {
                  product.name = nameController.text;
                  product.price = double.tryParse(priceController.text) ?? product.price;
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
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
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
                          title: Text(product.name,
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(
                              'Harga: Rp ${product.price.toStringAsFixed(0)} | Stok: ${product.stock}'),
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

// Halaman Pembelian dari Supplier
class SupplierPage extends StatefulWidget {
  final List<Product> products;
  final Function(String, int, double) onRestock;

  const SupplierPage({
    Key? key,
    required this.products,
    required this.onRestock,
  }) : super(key: key);

  @override
  State<SupplierPage> createState() => _SupplierPageState();
}

class _SupplierPageState extends State<SupplierPage> {
  void _showRestockDialog(BuildContext context, Product product) {
    final qtyController = TextEditingController();
    final costController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Restock: ${product.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: qtyController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Jumlah Tambah Stok'),
              ),
              TextField(
                controller: costController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Total Biaya Belanja (Rp)'),
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
                if (qtyController.text.isNotEmpty && costController.text.isNotEmpty) {
                  int addQty = int.tryParse(qtyController.text) ?? 0;
                  double totalCost = double.tryParse(costController.text) ?? 0;

                  if (addQty > 0) {
                    widget.onRestock(product.name, addQty, totalCost);
                    setState(() {});
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Stok berhasil ditambah & tercatat di Keuangan!')),
                    );
                  }
                }
              },
              child: const Text('Simpan', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pembelian dari Supplier'),
        backgroundColor: Colors.teal,
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Pilih produk yang ingin ditambah stoknya (Kulakan)',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
          Expanded(
            child: widget.products.isEmpty
                ? const Center(child: Text('Belum ada produk terdaftar'))
                : ListView.builder(
                    itemCount: widget.products.length,
                    itemBuilder: (context, index) {
                      final p = widget.products[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Colors.teal,
                            child: Icon(Icons.local_shipping, color: Colors.white),
                          ),
                          title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('Stok Saat Ini: ${p.stock}'),
                          trailing: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                            onPressed: () => _showRestockDialog(context, p),
                            child: const Text('Restock', style: TextStyle(color: Colors.white)),
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
}

// Halaman Transaksi Penjualan
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
        orElse: () => CartItem(product: Product(name: '', price: 0, stock: 0), quantity: 0),
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

  void _checkout() {
    if (cart.isEmpty) return;

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
      items: recordedItems,
      total: totalHarga,
    );

    setState(() {
      for (var item in cart) {
        item.product.stock -= item.quantity;
      }
      widget.onCheckout(newRecord);
      cart.clear();
    });

    widget.onUpdateState();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Transaksi Berhasil & Struk Dicetak!')),
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
            height: 110,
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
            child: Text('Keranjang Belanja',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          Expanded(
            child: cart.isEmpty
                ? const Center(
                    child: Text('Keranjang masih kosong', style: TextStyle(color: Colors.grey)))
                : ListView.builder(
                    itemCount: cart.length,
                    itemBuilder: (context, index) {
                      final item = cart[index];
                      return ListTile(
                        title: Text(item.product.name),
                        subtitle: Text('Rp ${item.customPrice.toStringAsFixed(0)} x ${item.quantity}'),
                        trailing: Text(
                          'Rp ${item.subtotal.toStringAsFixed(0)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
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
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                  ),
                  onPressed: cart.isEmpty ? null : _checkout,
                  child: const Text('Bayar & Cetak',
                      style: TextStyle(fontSize: 16, color: Colors.white)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Halaman Keuangan
class KeuanganPage extends StatefulWidget {
  final List<CashRecord> cashRecords;
  final Function(CashRecord) onAddRecord;

  const KeuanganPage({
    Key? key,
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
    double totalPemasukan =
        widget.cashRecords.where((r) => r.isIncome).fold(0, (sum, r) => sum + r.amount);
    double totalPengeluaran =
        widget.cashRecords.where((r) => !r.isIncome).fold(0, (sum, r) => sum + r.amount);
    double saldoKas = totalPemasukan - totalPengeluaran;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Keuangan'),
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
                const Text('Saldo Kas Saat Ini', style: TextStyle(color: Colors.grey, fontSize: 14)),
                const SizedBox(height: 6),
                Text('Rp ${saldoKas.toStringAsFixed(0)}',
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold, color: Colors.teal)),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Masuk: Rp ${totalPemasukan.toStringAsFixed(0)}',
                        style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                    Text('Keluar: Rp ${totalPengeluaran.toStringAsFixed(0)}',
                        style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: widget.cashRecords.isEmpty
                ? const Center(
                    child: Text('Belum ada catatan keuangan', style: TextStyle(color: Colors.grey)))
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
  // Dialog khusus Edit Struk / Transaksi
  void _showEditReceiptDialog(TransactionRecord tx) {
    final noteController = TextEditingController(text: tx.note);

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
                    const Text('Ubah Jumlah atau Harga Item:',
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
                        labelText: 'Catatan Khusus Struk (Misal: Diskon Ultah)',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Baru:', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('Rp ${tx.total.toStringAsFixed(0)}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, color: Colors.teal)),
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
              child: Text('Riwayat Transaksi',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: widget.transactions.isEmpty
                ? const Center(
                    child: Text('Belum ada transaksi tercatat',
                        style: TextStyle(color: Colors.grey)))
                : ListView.builder(
                    itemCount: widget.transactions.length,
                    itemBuilder: (context, index) {
                      final tx = widget.transactions[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        child: ExpansionTile(
                          title: Text('${tx.id} - Rp ${tx.total.toStringAsFixed(0)}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, color: Colors.teal)),
                          subtitle: Text('Waktu: ${tx.date}'),
                          children: [
                            ...tx.items.map((item) {
                              return ListTile(
                                dense: true,
                                title: Text(item.product.name),
                                trailing: Text(
                                    '${item.quantity}x @Rp ${item.customPrice.toStringAsFixed(0)} = Rp ${item.subtotal.toStringAsFixed(0)}'),
                              );
                            }).toList(),
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
