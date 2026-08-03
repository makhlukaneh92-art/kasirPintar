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

class DashboardKasir extends StatefulWidget {
  const DashboardKasir({Key? key}) : super(key: key);

  @override
  State<DashboardKasir> createState() => _DashboardKasirState();
}

class _DashboardKasirState extends State<DashboardKasir> {
  // Daftar Produk Sementara (Akan bertambah saat kamu input produk baru)
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

              // Menu Manajemen (Dapat Diklik)
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
              _buildMenuItem(Icons.shopping_cart, 'Transaksi Penjualan'),
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
