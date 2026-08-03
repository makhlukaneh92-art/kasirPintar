import 'package:flutter/material.dart';

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

  CartItem({required this.product, required this.quantity});
}

class DashboardKasir extends StatefulWidget {
  const DashboardKasir({Key? key}) : super(key: key);

  @override
  State<DashboardKasir> createState() => _DashboardKasirState();
}

class _DashboardKasirState extends State<DashboardKasir> {
  // Daftar Produk Utama
  List<Product> products = [
    Product(name: 'Kopi Susu', price: 15000, stock: 50),
    Product(name: 'Roti Bakar', price: 12000, stock: 30),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Profil
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.teal,
                        child: Icon(Icons.person, color: Colors.white, size: 30),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('Kepada, Toko/tn...',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                          Text('Owner',
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 14)),
                        ],
                      ),
                    ],
                  ),
                  const Icon(Icons.swap_horiz, size: 28),
                ],
              ),
              const SizedBox(height: 20),

              // Backoffice Button
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.language, color: Colors.green),
                    SizedBox(width: 10),
                    Text('Backoffice Kasir Pintar',
                        style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 16)),
                    Spacer(),
                    Icon(Icons.chevron_right, color: Colors.green),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Misi Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.teal, Colors.greenAccent],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Text('Misi dapat hadiah',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16)),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('Baru!',
                          style: TextStyle(color: Colors.white, fontSize: 12)),
                    ),
                    const Spacer(),
                    const Icon(Icons.chevron_right, color: Colors.white),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Menu List
              const Text('Toko Online Saya',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 10),

              // Menu Manajemen
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProductManagementPage(
                        products: products,
                        onAddProduct: (newProduct) {
                          setState(() {
                            products.add(newProduct);
                          });
                        },
                      ),
                    ),
                  );
                },
                child: _buildMenuItem(Icons.layers, 'Manajemen'),
              ),

              // Menu Transaksi Penjualan (Aktif)
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SalesPage(
                        products: products,
                        onUpdateState: () {
                          setState(() {});
                        },
                      ),
                    ),
                  );
                },
                child: _buildMenuItem(Icons.shopping_cart, 'Transaksi Penjualan'),
              ),

              _buildMenuItem(Icons.inventory, 'Pembelian dari Supplier'),
              _buildMenuItem(Icons.account_balance_wallet, 'Keuangan'),
              _buildMenuItem(Icons.bolt, 'PPOB'),
              _buildMenuItem(Icons.description, 'Laporan'),
              _buildMenuItem(Icons.access_time, 'Absensi'),
              _buildMenuItem(Icons.event_note, 'Shift'),
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
          Text(title,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// Halaman Manajemen Produk
class ProductManagementPage extends StatefulWidget {
  final List<Product> products;
  final Function(Product) onAddProduct;

  const ProductManagementPage({
    Key? key,
    required this.products,
    required this.onAddProduct,
  }) : super(key: key);

  @override
  State<ProductManagementPage> createState() => _ProductManagementPageState();
}

class _ProductManagementPageState extends State<ProductManagementPage> {
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
                if (nameController.text.isNotEmpty &&
                    priceController.text.isNotEmpty) {
                  widget.onAddProduct(
                    Product(
                      name: nameController.text,
                      price: double.tryParse(priceController.text) ?? 0,
                      stock: int.tryParse(stockController.text) ?? 0,
                    ),
                  );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Produk'),
        backgroundColor: Colors.teal,
      ),
      body: widget.products.isEmpty
          ? const Center(
              child: Text('Belum ada produk. Tambahkan lewat tombol di bawah!'))
          : ListView.builder(
              itemCount: widget.products.length,
              itemBuilder: (context, index) {
                final product = widget.products[index];
                return ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.teal,
                    child: Icon(Icons.shopping_bag, color: Colors.white),
                  ),
                  title: Text(product.name,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                      'Harga: Rp ${product.price.toStringAsFixed(0)}'),
                  trailing: Text(
                    'Stok: ${product.stock}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                        fontSize: 16),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.teal,
        onPressed: () => _showAddProductDialog(context),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

// Halaman Transaksi Penjualan (Kasir)
class SalesPage extends StatefulWidget {
  final List<Product> products;
  final VoidCallback onUpdateState;

  const SalesPage({
    Key? key,
    required this.products,
    required this.onUpdateState,
  }) : super(key: key);

  @override
  State<SalesPage> createState() => _SalesPageState();
}

class _SalesPageState extends State<SalesPage> {
  final List<CartItem> cart = [];

  double get totalHarga {
    double sum = 0;
    for (var item in cart) {
      sum += (item.product.price * item.quantity);
    }
    return sum;
  }

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

    setState(() {
      for (var item in cart) {
        item.product.stock -= item.quantity;
      }
      cart.clear();
    });

    widget.onUpdateState();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Transaksi Berhasil!'),
        content: const Text('Pembayaran berhasil diproses dan stok telah diperbarui.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaksi Penjualan (Kasir)'),
        backgroundColor: Colors.teal,
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text('Ketuk Produk untuk Masuk Keranjang',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
          SizedBox(
            height: 120,
            child: widget.products.isEmpty
                ? const Center(child: Text('Belum ada produk di manajemen'))
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: widget.products.length,
                    itemBuilder: (context, index) {
                      final p = widget.products[index];
                      return GestureDetector(
                        onTap: () => _addToCart(p),
                        child: Container(
                          width: 130,
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          padding: const EdgeInsets.all(10),
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
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold, fontSize: 14),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 4),
                              Text('Rp ${p.price.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                      color: Colors.teal, fontSize: 12)),
                              const SizedBox(height: 4),
                              Text('Stok: ${p.stock}',
                                  style: const TextStyle(
                                      color: Colors.grey, fontSize: 12)),
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
                    child: Text('Keranjang masih kosong',
                        style: TextStyle(color: Colors.grey)))
                : ListView.builder(
                    itemCount: cart.length,
                    itemBuilder: (context, index) {
                      final item = cart[index];
                      return ListTile(
                        title: Text(item.product.name),
                        subtitle: Text(
                            'Rp ${item.product.price.toStringAsFixed(0)} x ${item.quantity}'),
                        trailing: Text(
                          'Rp ${(item.product.price * item.quantity).toStringAsFixed(0)}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14),
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
                    const Text('Total Pembayaran:',
                        style: TextStyle(color: Colors.grey)),
                    Text('Rp ${totalHarga.toStringAsFixed(0)}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.teal)),
                  ],
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 30, vertical: 12),
                  ),
                  onPressed: cart.isEmpty ? null : _checkout,
                  child: const Text('Bayar',
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
