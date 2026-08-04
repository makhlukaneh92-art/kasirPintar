import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

// 1. MODEL DATA PRODUK
class Product {
  String id;
  String name;
  double modalPrice;   // Harga Modal / HPP
  double sellingPrice; // Harga Jual
  int stock;          // Stok Barang

  Product({
    required this.id,
    required this.name,
    required this.modalPrice,
    required this.sellingPrice,
    required this.stock,
  });
}

// Data Store Sementara
class ProductData {
  static List<Product> products = [
    Product(id: '1', name: 'Kopi Susu Gula Aren', modalPrice: 10000, sellingPrice: 18000, stock: 45),
    Product(id: '2', name: 'Roti Bakar Cokelat', modalPrice: 7000, sellingPrice: 12000, stock: 20),
    Product(id: '3', name: 'Teh Manis Dingin', modalPrice: 2000, sellingPrice: 5000, stock: 100),
  ];
}

// 2. TAMPILAN HALAMAN MANAJEMEN PRODUK
class ProductManagementScreen extends StatefulWidget {
  const ProductManagementScreen({Key? key}) : super(key: key);

  @override
  State<ProductManagementScreen> createState() => _ProductManagementScreenState();
}

class _ProductManagementScreenState extends State<ProductManagementScreen> {
  final currencyFormat = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);

  // Form Tambah / Edit Produk
  void _showProductForm({Product? product, int? index}) {
    final isEdit = product != null;
    final nameController = TextEditingController(text: isEdit ? product.name : '');
    final modalController = TextEditingController(text: isEdit ? product.modalPrice.toInt().toString() : '');
    final sellingController = TextEditingController(text: isEdit ? product.sellingPrice.toInt().toString() : '');
    final stockController = TextEditingController(text: isEdit ? product.stock.toString() : '');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          isEdit ? 'Edit Produk' : 'Tambah Produk Baru',
          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00897B)),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nama Produk',
                  hintText: 'Contoh: Es Kopi Susu',
                  prefixIcon: Icon(Icons.fastfood),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: modalController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Harga Modal / HPP (Rp)',
                  hintText: '0',
                  prefixIcon: Icon(Icons.monetization_on_outlined),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: sellingController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Harga Jual (Rp)',
                  hintText: '0',
                  prefixIcon: Icon(Icons.sell_outlined),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: stockController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Stok Barang',
                  hintText: '0',
                  prefixIcon: Icon(Icons.inventory),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00897B),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              if (nameController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Nama produk tidak boleh kosong!')),
                );
                return;
              }

              setState(() {
                if (isEdit) {
                  product.name = nameController.text.trim();
                  product.modalPrice = double.tryParse(modalController.text) ?? 0;
                  product.sellingPrice = double.tryParse(sellingController.text) ?? 0;
                  product.stock = int.tryParse(stockController.text) ?? 0;
                } else {
                  ProductData.products.add(Product(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: nameController.text.trim(),
                    modalPrice: double.tryParse(modalController.text) ?? 0,
                    sellingPrice: double.tryParse(sellingController.text) ?? 0,
                    stock: int.tryParse(stockController.text) ?? 0,
                  ));
                }
              });

              Navigator.pop(ctx);
            },
            child: Text(isEdit ? 'Simpan' : 'Tambah'),
          ),
        ],
      ),
    );
  }

  // Dialog Konfirmasi Hapus
  void _confirmDelete(int index) {
    final product = ProductData.products[index];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Produk?'),
        content: Text('Apakah Anda yakin ingin menghapus "${product.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              setState(() {
                ProductData.products.removeAt(index);
              });
              Navigator.pop(ctx);
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Produk', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF00897B),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ProductData.products.isEmpty
          ? const Center(
              child: Text('Belum ada produk. Ketuk tombol + di bawah.', style: TextStyle(color: Colors.grey)),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: ProductData.products.length,
              itemBuilder: (context, index) {
                final item = ProductData.products[index];
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFF00897B).withOpacity(0.1),
                      child: Text(
                        item.name.isNotEmpty ? item.name[0].toUpperCase() : 'P',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00897B)),
                      ),
                    ),
                    title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Modal: ${currencyFormat.format(item.modalPrice)}  |  Jual: ${currencyFormat.format(item.sellingPrice)}'),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: item.stock > 10 ? Colors.green.shade100 : Colors.orange.shade100,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Stok: ${item.stock}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: item.stock > 10 ? Colors.green.shade800 : Colors.orange.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _showProductForm(product: item, index: index),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _confirmDelete(index),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF00897B),
        foregroundColor: Colors.white,
        onPressed: () => _showProductForm(),
        icon: const Icon(Icons.add),
        label: const Text('Tambah Produk'),
      ),
    );
  }
}
